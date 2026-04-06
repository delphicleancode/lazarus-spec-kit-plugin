{***************************************************************}
{                                                               }
{                        LazarusSpecKit                         }
{     AI-powered Spec-Driven Development wizard for Lazarus     }
{                                                               }
{                 Author: Carlos Eduardo Paulino                }
{           Company: Inovefast https://inovefast.com.br         }
{                   Plugin Version: 1.0.3                       }
{                                                               }
{***************************************************************}

{@**************************************************************}
{  Project Repository:                                          }
{    https://github.com/delphicleancode/lazarus-spec-kit        }
{                                                               }
{  License: MIT                                                 }
{                                                               }
{  This project is provided "as is", without warranty of any    }
{  kind, express or implied, including but not limited to       }
{  merchantability, fitness for a particular purpose and        }
{  noninfringement. See LICENSE for full terms.                 }
{                                                               }
{                     Inovefast / LazarusSpecKit                }
{**************************************************************@}

unit AICompletionHandler;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, LCLType, SynEdit,
  SrcEditorIntf, BaseAIClient, AICompleter, SpecSettings;

type
  { TAICompletionThread - Background thread for AI completion requests }
  TAICompletionThread = class(TThread)
  private
    FMessages: TAIMessages;
    FModel: string;
    FMaxTokens: Integer;
    FTemperature: Double;
    FApiKey: string;
    FProvider: string;
    FOllamaURL: string;
    FResponse: string;
    FError: string;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AMessages: TAIMessages;
      const AModel, AApiKey, AProvider, AOllamaURL: string;
      AMaxTokens: Integer; ATemperature: Double);
    property Response: string read FResponse;
    property Error: string read FError;
    property Success: Boolean read FSuccess;
  end;

  { TAICompletionHandler - Manages AI code completion in the IDE editor }
  TAICompletionHandler = class
  private
    FCompleter: TAICompleter;
    FThread: TAICompletionThread;
    FBusy: Boolean;
    FCursorPos: TPoint;
    procedure HandleThreadDone(Sender: TObject);
    procedure ShowCompletionPreview(const ACode: string);
    function GetCurrentSynEdit: TCustomSynEdit;
    procedure OnKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor Create;
    destructor Destroy; override;
    procedure TriggerCompletion;
    property Busy: Boolean read FBusy;
  end;

var
  AICompletionHandlerInstance: TAICompletionHandler = nil;

procedure InitAICompletionHandler;
procedure FinalizeAICompletionHandler;
procedure TriggerAICompletion(Sender: TObject);

implementation

uses
  GroqClient, QwenClient, OpenRouterClient, EditorHelper, frmCompletionPreview;


{ Helper function to get the correct URL based on provider }
function GetProviderURL(const ASettings: TSpecSettings): string;
begin
  if ASettings.Provider = 'qwen' then
    Result := ASettings.QwenURL
  else if ASettings.Provider = 'openrouter' then
    Result := ASettings.OpenRouterURL
  else
    Result := ASettings.OllamaURL;
end;


{ TAICompletionThread }

constructor TAICompletionThread.Create(const AMessages: TAIMessages;
  const AModel, AApiKey, AProvider, AOllamaURL: string;
  AMaxTokens: Integer; ATemperature: Double);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FMessages := AMessages;
  FModel := AModel;
  FApiKey := AApiKey;
  FProvider := AProvider;
  FOllamaURL := AOllamaURL;
  FMaxTokens := AMaxTokens;
  FTemperature := ATemperature;
  FResponse := '';
  FError := '';
  FSuccess := False;
end;

procedure TAICompletionThread.Execute;
var
  Client: ISpecAIClient;
  AIResponse: TAIResponse;
begin
  try
    if FProvider = 'ollama' then
      Client := TGroqClient.Create(FApiKey, FOllamaURL + '/v1')
    else if FProvider = 'qwen' then
      Client := TQwenClient.Create(FApiKey, FOllamaURL)
    else if FProvider = 'openrouter' then
      Client := TOpenRouterClient.Create(FApiKey, FOllamaURL)
    else
      Client := TGroqClient.Create(FApiKey);

    AIResponse := Client.ChatCompletion(FMessages, FModel,
      FMaxTokens, FTemperature);

    if AIResponse.Success then
    begin
      FResponse := AIResponse.Content;
      FSuccess := True;
    end
    else
    begin
      FError := AIResponse.ErrorMessage;
      FSuccess := False;
    end;
  except
    on E: Exception do
    begin
      FError := E.Message;
      FSuccess := False;
    end;
  end;
end;

{ TAICompletionHandler }

constructor TAICompletionHandler.Create;
begin
  inherited Create;
  FCompleter := TAICompleter.Create;
  FThread := nil;
  FBusy := False;
  Application.AddOnKeyDownBeforeHandler(@OnKeyDown);
end;

destructor TAICompletionHandler.Destroy;
begin
  Application.RemoveOnKeyDownBeforeHandler(@OnKeyDown);
  if FThread <> nil then
  begin
    FThread.OnTerminate := nil;
    if not FThread.Finished then
    begin
      FThread.Terminate;
      FThread.WaitFor;
    end;
    FreeAndNil(FThread);
  end;
  FreeAndNil(FCompleter);
  inherited Destroy;
end;

procedure TAICompletionHandler.OnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Ctrl+Shift+Space fires AI completion when the source editor is focused.
  // Using AddOnKeyDownBeforeHandler ensures SynEdit and OS (AltGr) don't intercept first.
  if (Key = VK_SPACE) and (Shift = [ssCtrl, ssShift]) then
  begin
    if GetCurrentSynEdit <> nil then
    begin
      Key := 0; // consume the keystroke
      TriggerCompletion;
    end;
  end;
end;

function TAICompletionHandler.GetCurrentSynEdit: TCustomSynEdit;
var
  Editor: TSourceEditorInterface;
begin
  Result := nil;
  if SourceEditorManagerIntf = nil then Exit;
  Editor := SourceEditorManagerIntf.ActiveEditor;
  if Editor = nil then Exit;
  if Editor.EditorControl is TCustomSynEdit then
    Result := TCustomSynEdit(Editor.EditorControl);
end;

procedure TAICompletionHandler.TriggerCompletion;
var
  SynEdit: TCustomSynEdit;
  SourceCode, FileName: string;
  CursorLine, CursorCol: Integer;
  Messages: TAIMessages;
  Settings: TSpecSettings;
begin
  if FBusy then Exit;

  Settings := TSpecSettings.Instance;
  if not Settings.AutoCompleteEnabled then Exit;
  if Settings.ApiKey = '' then Exit;

  SynEdit := GetCurrentSynEdit;
  if SynEdit = nil then Exit;

  SourceCode := SynEdit.Text;
  if Trim(SourceCode) = '' then Exit;

  // SynEdit uses 1-based, AICompleter expects 0-based line index
  CursorLine := SynEdit.CaretY - 1;
  CursorCol := SynEdit.CaretX;

  FileName := '';
  if SourceEditorManagerIntf.ActiveEditor <> nil then
    FileName := SourceEditorManagerIntf.ActiveEditor.FileName;

  // Save cursor position for insertion later
  FCursorPos := Point(SynEdit.CaretX, SynEdit.CaretY);

  // Build messages
  Messages := FCompleter.BuildCompletionMessages(
    SourceCode, CursorLine, CursorCol, FileName);

  // Clean up previous thread
  if FThread <> nil then
  begin
    FThread.OnTerminate := nil;
    if not FThread.Finished then
    begin
      FThread.Terminate;
      FThread.WaitFor;
    end;
    FreeAndNil(FThread);
  end;

  // Start background thread
  FBusy := True;
  FThread := TAICompletionThread.Create(
    Messages,
    Settings.Model,
    Settings.ApiKey,
    Settings.Provider,
    GetProviderURL(Settings),
    Settings.AutoCompleteMaxTokens,
    Settings.AutoCompleteTemperature);
  FThread.OnTerminate := @HandleThreadDone;
  FThread.Start;
end;

procedure TAICompletionHandler.HandleThreadDone(Sender: TObject);
var
  Items: TAICompletionItems;
begin
  FBusy := False;
  if FThread = nil then Exit;
  if not FThread.Success then Exit;

  Items := FCompleter.ParseCompletionResponse(FThread.Response);
  if Length(Items) > 0 then
    ShowCompletionPreview(Items[0].InsertText);
end;

procedure TAICompletionHandler.ShowCompletionPreview(const ACode: string);
var
  SynEdit: TCustomSynEdit;
  P: TPoint;
  TextToInsert: string;
begin
  SynEdit := GetCurrentSynEdit;
  if SynEdit = nil then Exit;

  // Position popup near the caret
  P := SynEdit.ClientToScreen(
    SynEdit.RowColumnToPixels(
      SynEdit.LogicalToPhysicalPos(SynEdit.LogicalCaretXY)));

  TextToInsert := frmCompletionPreview.ShowCompletionPreview(
    ACode, P.X, P.Y + SynEdit.LineHeight);

  if TextToInsert <> '' then
    TEditorHelper.InsertTextAtCursor(TextToInsert);
end;

{ Module-level procedures }

procedure InitAICompletionHandler;
begin
  if AICompletionHandlerInstance = nil then
    AICompletionHandlerInstance := TAICompletionHandler.Create;
end;

procedure FinalizeAICompletionHandler;
begin
  FreeAndNil(AICompletionHandlerInstance);
end;

procedure TriggerAICompletion(Sender: TObject);
begin
  InitAICompletionHandler;
  if AICompletionHandlerInstance <> nil then
    AICompletionHandlerInstance.TriggerCompletion;
end;

finalization
  FinalizeAICompletionHandler;

end.
