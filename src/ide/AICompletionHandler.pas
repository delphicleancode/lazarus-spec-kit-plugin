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
  Classes, SysUtils, Forms, Controls, LCLType, SynEdit, SynCompletion,
  SrcEditorIntf, BaseAIClient, AICompleter;

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
    FCompletion: TSynCompletion;
    FCompleter: TAICompleter;
    FThread: TAICompletionThread;
    FInsertList: TStringList;
    FBusy: Boolean;
    FCursorPos: TPoint;
    procedure HandleThreadDone(Sender: TObject);
    procedure HandleCodeCompletion(var Value: string;
      SourceValue: string;
      var SourceStart, SourceEnd: TPoint;
      KeyChar: TUTF8Char; Shift: TShiftState);
    procedure ShowCompletions(const AItems: TAICompletionItems);
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
  SpecSettings, GroqClient;

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
  FInsertList := TStringList.Create;
  FCompletion := TSynCompletion.Create(nil);
  FCompletion.Width := 520;
  FCompletion.NbLinesInWindow := 8;
  FCompletion.ShowSizeDrag := True;
  FCompletion.OnCodeCompletion := @HandleCodeCompletion;
  FCompletion.LongLineHintType := sclpExtendRightOnly;
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
  FreeAndNil(FCompletion);
  FreeAndNil(FInsertList);
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
    Settings.OllamaURL,
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
    ShowCompletions(Items);
end;

procedure TAICompletionHandler.ShowCompletions(
  const AItems: TAICompletionItems);
var
  SynEdit: TCustomSynEdit;
  P: TPoint;
  I: Integer;
begin
  SynEdit := GetCurrentSynEdit;
  if SynEdit = nil then Exit;

  FCompletion.ItemList.Clear;
  FInsertList.Clear;

  for I := 0 to Length(AItems) - 1 do
  begin
    FCompletion.ItemList.Add(AItems[I].DisplayText);
    FInsertList.Add(AItems[I].InsertText);
  end;

  FCompletion.Editor := SynEdit;

  // Calculate screen position for the popup
  P := SynEdit.ClientToScreen(
    SynEdit.RowColumnToPixels(
      SynEdit.LogicalToPhysicalPos(SynEdit.LogicalCaretXY)));
  FCompletion.Execute('', P.X, P.Y + SynEdit.LineHeight);
end;

procedure TAICompletionHandler.HandleCodeCompletion(var Value: string;
  SourceValue: string;
  var SourceStart, SourceEnd: TPoint;
  KeyChar: TUTF8Char; Shift: TShiftState);
begin
  // Set source range to cursor position so text is inserted, not replaced
  SourceStart := FCursorPos;
  SourceEnd := FCursorPos;
  // Replace display text with the stored insert text for this item
  if (FCompletion.Position >= 0) and (FCompletion.Position < FInsertList.Count) then
    Value := FInsertList[FCompletion.Position];
  // Convert literal \n markers to real line breaks
  Value := StringReplace(Value, '\n', LineEnding, [rfReplaceAll]);
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
