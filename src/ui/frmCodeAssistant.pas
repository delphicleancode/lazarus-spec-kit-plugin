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

unit frmCodeAssistant;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, SynEdit, SynHighlighterPas,
  BaseAIClient, EditorHelper, SkillsLoader;

type
  TCodeAssistAction = (caaRefactor, caaExplain, caaComplete, caaFix, caaReview);
  TSkillApplyMode = (samStrict, samBalanced, samSoft);

  { TCodeAssistThread - Runs AI request off the main thread }
  TCodeAssistThread = class(TThread)
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

  { TfrmCodeAssistant }
  TfrmCodeAssistant = class(TForm)
    pnlTop: TPanel;
    lblAction: TLabel;
    pnlPrompt: TPanel;
    lblPrompt: TLabel;
    lblSkill: TLabel;
    lblSkillMode: TLabel;
    edtPrompt: TEdit;
    cmbSkill: TComboBox;
    cmbSkillMode: TComboBox;
    btnRefactor: TSpeedButton;
    btnExplain: TSpeedButton;
    btnComplete: TSpeedButton;
    btnFix: TSpeedButton;
    btnReview: TSpeedButton;
    btnRun: TButton;
    btnApply: TButton;
    pnlBottom: TPanel;
    btnClose: TButton;
    lblStatus: TLabel;
    splMain: TSplitter;
    pnlSelected: TPanel;
    lblSelected: TLabel;
    SynPasSyn1: TSynPasSyn;
    synSelected: TSynEdit;
    pnlResult: TPanel;
    lblResult: TLabel;
    synResult: TSynEdit;
    procedure ActionButtonClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FThread: TCodeAssistThread;
    FCurrentAction: TCodeAssistAction;
    FSelectedCode: string;
    FSkillsLoader: TSkillsLoader;
    FSkillIDs: TStringList;
    procedure HandleThreadDone(Sender: TObject);
    procedure SetStatus(const AMsg: string);
    function BuildPrompt(AAction: TCodeAssistAction; const ACode: string): TAIMessages;
    procedure SetBusy(ABusy: Boolean);
    procedure ApplyTranslations;
    procedure LoadSkills;
    function GetSelectedSkillID: string;
    function GetSelectedSkillMode: TSkillApplyMode;
  public
    procedure LoadSelectedCode(const ACode: string);
    property CurrentAction: TCodeAssistAction read FCurrentAction write FCurrentAction;
  end;

var
  frmCodeAssistantInstance: TfrmCodeAssistant = nil;

procedure ShowCodeAssistant(const ASelectedCode: string;
  AAction: TCodeAssistAction = caaExplain);

implementation

uses
  SpecSettings, GroqClient, LazSpecLang, ProjectHelper;

{$R *.lfm}

// The constant SYSTEM_PROMPT and ACTION_PROMPTS have been replaced by the
// language-aware TR() calls in BuildPrompt.  See LazSpecLang.pas.

{ TCodeAssistThread }

constructor TCodeAssistThread.Create(const AMessages: TAIMessages;
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

procedure TCodeAssistThread.Execute;
var
  Client: ISpecAIClient;
  AIResponse: TAIResponse;
begin
  try
    if FProvider = 'ollama' then
      Client := TGroqClient.Create(FApiKey, FOllamaURL + '/v1')
    else
      Client := TGroqClient.Create(FApiKey);

    AIResponse := Client.ChatCompletion(FMessages, FModel, FMaxTokens, FTemperature);

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

{ TfrmCodeAssistant }

procedure TfrmCodeAssistant.FormCreate(Sender: TObject);
begin
  FCurrentAction := caaExplain;
  FThread := nil;
  FSkillsLoader := TSkillsLoader.Create('');
  FSkillIDs := TStringList.Create;

  synSelected.Font.Quality := fqDefault;
  synResult.Font.Quality := fqDefault;

  // Select Explain by default
  btnExplain.Down := True;
  cmbSkillMode.ItemIndex := 0; // strict by default
  LoadSkills;
  // Apply language-aware captions
  ApplyTranslations;
end;

procedure TfrmCodeAssistant.FormDestroy(Sender: TObject);
begin
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
  FreeAndNil(FSkillIDs);
  FreeAndNil(FSkillsLoader);
end;

procedure TfrmCodeAssistant.LoadSelectedCode(const ACode: string);
begin
  FSelectedCode := ACode;
  synSelected.Text := ACode;
  synResult.Clear;
  btnApply.Enabled := False;
  SetStatus(TR('CA.Ready'));
end;

procedure TfrmCodeAssistant.ActionButtonClick(Sender: TObject);
var
  LTag: Integer;
begin
  LTag := TSpeedButton(Sender).Tag;
  case LTag of
    1: FCurrentAction := caaRefactor;
    2: FCurrentAction := caaExplain;
    3: FCurrentAction := caaComplete;
    4: FCurrentAction := caaFix;
    5: FCurrentAction := caaReview;
  end;
end;

procedure TfrmCodeAssistant.btnRunClick(Sender: TObject);
var
  Settings: TSpecSettings;
  Messages: TAIMessages;
begin
  if Trim(FSelectedCode) = '' then
  begin
    SetStatus(TR('CA.NoCode'));
    Exit;
  end;

  if FThread <> nil then
  begin
    SetStatus(TR('CA.Waiting'));
    Exit;
  end;

  Settings := TSpecSettings.Instance;
  if Trim(Settings.ApiKey) = '' then
  begin
    ShowMessage(TR('CA.NeedApiKey'));
    Exit;
  end;

  synResult.Clear;
  btnApply.Enabled := False;
  SetBusy(True);
  SetStatus(TR('CA.Consulting'));

  Messages := BuildPrompt(FCurrentAction, FSelectedCode);

  FThread := TCodeAssistThread.Create(
    Messages,
    Settings.Model,
    Settings.ApiKey,
    Settings.Provider,
    Settings.OllamaURL,
    Settings.MaxTokens,
    Settings.Temperature
  );
  FThread.OnTerminate := @HandleThreadDone;
  FThread.Start;
end;

procedure TfrmCodeAssistant.HandleThreadDone(Sender: TObject);
begin
  // OnTerminate fires in main thread
  if FThread = nil then Exit;

  if FThread.Success then
  begin
    synResult.Text := FThread.Response;
    // Enable Apply only for code-producing actions
    btnApply.Enabled := FCurrentAction in [caaRefactor, caaComplete, caaFix];
    SetStatus(TR('CA.Done'));
  end
  else
  begin
    SetStatus(TR('CA.Error') + FThread.Error);
    synResult.Text := TR('CA.CodeError') + FThread.Error;
  end;

  FreeAndNil(FThread);
  SetBusy(False);
end;

procedure TfrmCodeAssistant.btnApplyClick(Sender: TObject);
var
  ResultCode: string;
begin
  ResultCode := Trim(synResult.Text);
  if ResultCode = '' then Exit;

  TEditorHelper.ReplaceSelectedText(ResultCode);
  SetStatus(TR('CA.Applied'));
  btnApply.Enabled := False;
end;

procedure TfrmCodeAssistant.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCodeAssistant.SetStatus(const AMsg: string);
begin
  lblStatus.Caption := AMsg;
  lblStatus.Update;
end;

procedure TfrmCodeAssistant.SetBusy(ABusy: Boolean);
begin
  btnRun.Enabled := not ABusy;
  btnRefactor.Enabled := not ABusy;
  btnExplain.Enabled := not ABusy;
  btnComplete.Enabled := not ABusy;
  btnFix.Enabled := not ABusy;
  btnReview.Enabled := not ABusy;
end;

function TfrmCodeAssistant.BuildPrompt(AAction: TCodeAssistAction;
  const ACode: string): TAIMessages;
var
  UserMsg, ExtraPrompt, SkillID, SkillContent, SkillSystemMsg: string;
  SkillMode: TSkillApplyMode;
begin
  SkillID := GetSelectedSkillID;
  SkillMode := GetSelectedSkillMode;
  SkillContent := '';
  if SkillID <> '' then
    SkillContent := FSkillsLoader.GetSkillContent(SkillID);

  if Trim(SkillContent) <> '' then
    UserMsg := Format(TR('AI.SkillTask.' + IntToStr(Ord(AAction))), [ACode])
  else
    UserMsg := Format(TR('AI.ActionPrompt.' + IntToStr(Ord(AAction))), [ACode]);

  ExtraPrompt := Trim(edtPrompt.Text);
  if ExtraPrompt <> '' then
    UserMsg := UserMsg + LineEnding + LineEnding +
      TR('CA.AdditionalInstruction') + ExtraPrompt;

  if Trim(SkillContent) <> '' then
  begin
    case SkillMode of
      samStrict:
        SkillSystemMsg := TR('AI.SkillSystemHeader.Strict') + LineEnding +
          SkillContent + LineEnding + TR('AI.SkillSystemFooter');
      samBalanced:
        SkillSystemMsg := TR('AI.SkillSystemHeader.Balanced') + LineEnding +
          SkillContent + LineEnding + TR('AI.SkillSystemFooter');
      samSoft:
        SkillSystemMsg := '';
    end;

    if SkillMode = samSoft then
    begin
      UserMsg := UserMsg + LineEnding + LineEnding +
        TR('AI.SkillSoftGuidanceHeader') + LineEnding + SkillContent;
      SetLength(Result, 2);
      Result[0] := CreateAIMessage('system', TR('AI.SystemPrompt'));
      Result[1] := CreateAIMessage('user', UserMsg);
    end
    else
    begin
      SetLength(Result, 3);
      Result[0] := CreateAIMessage('system', TR('AI.SystemPrompt'));
      Result[1] := CreateAIMessage('system', SkillSystemMsg);
      Result[2] := CreateAIMessage('user', UserMsg);
    end;
  end
  else
  begin
    SetLength(Result, 2);
    Result[0] := CreateAIMessage('system', TR('AI.SystemPrompt'));
    Result[1] := CreateAIMessage('user', UserMsg);
  end;
end;

procedure TfrmCodeAssistant.LoadSkills;
var
  Settings: TSpecSettings;
  Skills: TSkillInfoArray;
  I, PrevIndex: Integer;
  PrevSkillID, SpecKitPath: string;
begin
  PrevSkillID := GetSelectedSkillID;

  Settings := TSpecSettings.Instance;
  SpecKitPath := Settings.SpecKitPath;
  if (SpecKitPath = '') or (not DirectoryExists(SpecKitPath)) then
  begin
    if TProjectHelper.HasActiveProject then
      SpecKitPath := IncludeTrailingPathDelimiter(TProjectHelper.GetProjectPath) +
        'lazarus-spec-kit';
  end;

  cmbSkill.Items.BeginUpdate;
  try
    cmbSkill.Items.Clear;
    FSkillIDs.Clear;

    cmbSkill.Items.Add(TR('Skill.None'));
    FSkillIDs.Add('');

    if DirectoryExists(SpecKitPath) then
    begin
      FSkillsLoader.SpecKitPath := SpecKitPath;
      FSkillsLoader.ScanSkills;
      Skills := FSkillsLoader.GetSkillList;
      for I := 0 to Length(Skills) - 1 do
      begin
        cmbSkill.Items.Add(Skills[I].Name + ' [' + Skills[I].Category + ']');
        FSkillIDs.Add(Skills[I].ID);
      end;
    end;

    PrevIndex := FSkillIDs.IndexOf(PrevSkillID);
    if PrevIndex >= 0 then
      cmbSkill.ItemIndex := PrevIndex
    else
      cmbSkill.ItemIndex := 0;
  finally
    cmbSkill.Items.EndUpdate;
  end;
end;

function TfrmCodeAssistant.GetSelectedSkillID: string;
begin
  Result := '';
  if (cmbSkill.ItemIndex >= 0) and (cmbSkill.ItemIndex < FSkillIDs.Count) then
    Result := FSkillIDs[cmbSkill.ItemIndex];
end;

function TfrmCodeAssistant.GetSelectedSkillMode: TSkillApplyMode;
begin
  case cmbSkillMode.ItemIndex of
    1: Result := samBalanced;
    2: Result := samSoft;
  else
    Result := samStrict;
  end;
end;

{ ShowCodeAssistant }

procedure TfrmCodeAssistant.ApplyTranslations;
var
  PrevMode: Integer;
begin
  Caption                := TR('Form.CodeAssistant');
  lblAction.Caption      := TR('Lbl.Action');
  btnRefactor.Caption    := TR('Btn.Refactor');
  btnExplain.Caption     := TR('Btn.Explain');
  btnComplete.Caption    := TR('Btn.Complete');
  btnFix.Caption         := TR('Btn.Fix');
  btnReview.Caption      := TR('Btn.Review');
  btnRun.Caption         := TR('Btn.Run');
  btnApply.Caption       := TR('Btn.ApplyCode');
  lblPrompt.Caption      := TR('Lbl.AdditionalPrompt');
  lblSkill.Caption       := TR('Lbl.Skill');
  lblSkillMode.Caption   := TR('Lbl.SkillMode');

  PrevMode := cmbSkillMode.ItemIndex;
  cmbSkillMode.Items.BeginUpdate;
  try
    cmbSkillMode.Items.Clear;
    cmbSkillMode.Items.Add(TR('Skill.Mode.Strict'));
    cmbSkillMode.Items.Add(TR('Skill.Mode.Balanced'));
    cmbSkillMode.Items.Add(TR('Skill.Mode.Soft'));
    if PrevMode < 0 then
      PrevMode := 0;
    if PrevMode >= cmbSkillMode.Items.Count then
      PrevMode := cmbSkillMode.Items.Count - 1;
    cmbSkillMode.ItemIndex := PrevMode;
  finally
    cmbSkillMode.Items.EndUpdate;
  end;

  if cmbSkill.Items.Count > 0 then
    cmbSkill.Items[0] := TR('Skill.None');
  btnClose.Caption       := TR('Btn.Close');
  lblSelected.Caption    := TR('Lbl.SelectedCode');
  lblResult.Caption      := TR('Lbl.Result');
end;

procedure ShowCodeAssistant(const ASelectedCode: string;
  AAction: TCodeAssistAction);
begin
  if frmCodeAssistantInstance = nil then
    frmCodeAssistantInstance := TfrmCodeAssistant.Create(Application);

  frmCodeAssistantInstance.LoadSkills;
  frmCodeAssistantInstance.ApplyTranslations;
  frmCodeAssistantInstance.LoadSelectedCode(ASelectedCode);
  frmCodeAssistantInstance.CurrentAction := AAction;

  // Sync button state with requested action
  case AAction of
    caaRefactor: frmCodeAssistantInstance.btnRefactor.Down := True;
    caaExplain:  frmCodeAssistantInstance.btnExplain.Down := True;
    caaComplete: frmCodeAssistantInstance.btnComplete.Down := True;
    caaFix:      frmCodeAssistantInstance.btnFix.Down := True;
    caaReview:   frmCodeAssistantInstance.btnReview.Down := True;
  end;

  frmCodeAssistantInstance.Show;
  frmCodeAssistantInstance.BringToFront;
end;

end.
