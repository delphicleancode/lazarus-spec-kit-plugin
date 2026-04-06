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

unit frmSpecWizard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, CheckLst, SynEdit, SynHighlighterPas, Clipbrd,
  BaseAIClient, PromptBuilder, SDDEngine, SpecSettings, SkillsLoader,
  EditorHelper, ProjectHelper, FileCreator, CodeAssistantHandler;

type
  { TRequestThread - Runs AI request off the main thread }
  TRequestThread = class(TThread)
  private
    FEngine: TSDDEngine;
    FMode: TSpecMode;
    FUserInput: string;
    FSelectedSkills: TStringList;
    FProjectName: string;
    FActiveFile: string;
    FSelectedText: string;
    FResult: string;
    FLastResponse: TAIResponse;
  protected
    procedure Execute; override;
  public
    constructor Create(AEngine: TSDDEngine; AMode: TSpecMode;
      const AUserInput: string; ASelectedSkills: TStringList;
      const AProjectName, AActiveFile, ASelectedText: string);
    destructor Destroy; override;
    property Result: string read FResult;
    property LastResponse: TAIResponse read FLastResponse;
  end;

  { TSpecWizardForm - Main dockable wizard form }
  TSpecWizardForm = class(TForm)
    // Top toolbar
    pnlToolbar: TPanel;
    btnAsk: TSpeedButton;
    btnPlan: TSpeedButton;
    btnAgent: TSpeedButton;
    btnSettings: TSpeedButton;
    btnExport: TSpeedButton;
    btnClear: TSpeedButton;
    // Main area
    pnlMain: TPanel;
    splSkills: TSplitter;
    pnlSkills: TPanel;
    lblSkills: TLabel;
    clbSkills: TCheckListBox;
    // Output
    pnlOutput: TPanel;
    synOutput: TSynEdit;
    SynPasSyn: TSynPasSyn;
    // Input
    pnlInput: TPanel;
    memInput: TMemo;
    btnSend: TButton;
    btnCancel: TButton;
    btnCopy: TButton;
    btnApply: TButton;
    // Status bar
    statusBar: TStatusBar;
    // Deferred init timer (fires once after form is shown)
    tmrInit: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrInitTimer(Sender: TObject);
    procedure btnAskClick(Sender: TObject);
    procedure btnPlanClick(Sender: TObject);
    procedure btnAgentClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure memInputKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FEngine: TSDDEngine;
    FCurrentMode: TSpecMode;
    FProcessing: Boolean;
    FInitialized: Boolean;
    FRequestThread: TRequestThread;
    procedure SetCurrentMode(AMode: TSpecMode);
    procedure UpdateModeButtons;
    procedure UpdateStatusBar(const AResponse: TAIResponse);
    procedure LoadSkillsList;
    function GetSelectedSkillIDs: TStringList;
    procedure DoSendRequest;
    procedure SetUIProcessing(AProcessing: Boolean);
    procedure AutoDetectSpecKitPath;
    procedure DeferredInitialize;
    procedure OnRequestDone(Sender: TObject);
    procedure ApplyTranslations;
  public
    property CurrentMode: TSpecMode read FCurrentMode;
  end;

var
  SpecWizardForm: TSpecWizardForm;

implementation

uses
  LCLType, dlgSpecSettings, LazSpecLang;

{$R *.lfm}

{ TRequestThread }

constructor TRequestThread.Create(AEngine: TSDDEngine; AMode: TSpecMode;
  const AUserInput: string; ASelectedSkills: TStringList;
  const AProjectName, AActiveFile, ASelectedText: string);
begin
  inherited Create(True); // suspended
  FreeOnTerminate := False;
  FEngine := AEngine;
  FMode := AMode;
  FUserInput := AUserInput;
  FSelectedSkills := ASelectedSkills;
  FProjectName := AProjectName;
  FActiveFile := AActiveFile;
  FSelectedText := ASelectedText;
end;

destructor TRequestThread.Destroy;
begin
  FSelectedSkills.Free;
  inherited Destroy;
end;

procedure TRequestThread.Execute;
begin
  try
    FResult := FEngine.ProcessRequest(
      FMode, FUserInput, FSelectedSkills,
      FProjectName, FActiveFile, FSelectedText
    );
    FLastResponse := FEngine.LastResponse;
  except
    on E: Exception do
    begin
      FResult := '**Error:** ' + E.Message;
      FLastResponse.Success := False;
      FLastResponse.ErrorMessage := E.Message;
    end;
  end;
end;

{ TSpecWizardForm }

procedure TSpecWizardForm.FormCreate(Sender: TObject);
begin
  // KEEP THIS ULTRA-LIGHTWEIGHT — called during IDE startup
  // Never call LazarusIDE, file system, or network here
  FEngine := TSDDEngine.Create;
  FCurrentMode := smAsk;
  FProcessing := False;
  FInitialized := False;
  FRequestThread := nil;

  // Configure TSynEdit in code (not .lfm) to avoid version incompatibilities
  synOutput.ReadOnly := True;
  synOutput.Font.Name := 'Courier New';
  synOutput.Font.Size := 10;
  synOutput.Highlighter := SynPasSyn;

  // Configure highlighter colors in code
  SynPasSyn.CommentAttri.Foreground := clGreen;
  SynPasSyn.CommentAttri.Style := [fsItalic];
  SynPasSyn.KeyAttri.Foreground := clNavy;
  SynPasSyn.KeyAttri.Style := [fsBold];
  SynPasSyn.NumberAttri.Foreground := clBlue;
  SynPasSyn.StringAttri.Foreground := clMaroon;

  // Set initial UI state
  UpdateModeButtons;
  btnApply.Visible := False;
  btnCancel.Enabled := False;
  btnSend.Enabled := False;
  statusBar.SimpleText := TR('Status.Initializing');
end;

procedure TSpecWizardForm.FormShow(Sender: TObject);
var
  Settings : TSpecSettings;
begin
  Settings := TSpecSettings.Instance;
  Caption := 'Spec Wizard (' + Settings.Provider + ' - ' + Settings.Model + ')';

  // Start the deferred init timer on first show
  if not FInitialized then
    tmrInit.Enabled := True;
end;

procedure TSpecWizardForm.tmrInitTimer(Sender: TObject);
begin
  // Single-shot: disable immediately, then do all heavy init
  tmrInit.Enabled := False;
  DeferredInitialize;
end;

procedure TSpecWizardForm.DeferredInitialize;
begin
  if FInitialized then Exit;
  FInitialized := True;

  try
    // 1. Load settings (file I/O, safe after IDE is ready)
    TSpecSettings.Instance.LoadFromConfig;

    // 2. Apply translations for current language
    ApplyTranslations;

    // 3. Auto-detect spec-kit path
    AutoDetectSpecKitPath;

    // 4. Scan skills (directory traversal)
    LoadSkillsList;

    // 5. Set project context if a project is open
    if TProjectHelper.HasActiveProject then
    begin
      FEngine.SetProjectPath(TProjectHelper.GetProjectPath);
      statusBar.SimpleText := Format(TR('Status.ProjectFmt'),
        [TProjectHelper.GetProjectName, TR('Mode.Ask')]);
    end
    else
      statusBar.SimpleText := TR('Status.NoProject');

    // 6. Enable input
    btnSend.Enabled := True;
    memInput.Enabled := True;
    memInput.SetFocus;

  except
    on E: Exception do
    begin
      statusBar.SimpleText := TR('Status.InitError') + E.Message;
      btnSend.Enabled := True;
    end;
  end;
end;

procedure TSpecWizardForm.FormDestroy(Sender: TObject);
begin
  // Cancel any running request and wait for thread to finish cleanly
  if Assigned(FRequestThread) then
  begin
    if FEngine.AIClient <> nil then
      FEngine.AIClient.AbortRequest;
    FRequestThread.WaitFor;
    FreeAndNil(FRequestThread);
  end;
  FEngine.Free;
end;

procedure TSpecWizardForm.AutoDetectSpecKitPath;
var
  Settings: TSpecSettings;
  PossiblePath: string;
begin
  Settings := TSpecSettings.Instance;
  if Settings.SpecKitPath <> '' then
  begin
    if DirectoryExists(Settings.SpecKitPath) then
    begin
      FEngine.SkillsLoader.SpecKitPath := Settings.SpecKitPath;
      Exit;
    end;
    // Saved path no longer exists — reset it
    Settings.SpecKitPath := '';
  end;

  // Try lazarus-spec-kit beside the active project
  if TProjectHelper.HasActiveProject and (TProjectHelper.GetProjectPath <> '') then
  begin
    PossiblePath := IncludeTrailingPathDelimiter(
      TProjectHelper.GetProjectPath) + 'lazarus-spec-kit';
    if DirectoryExists(PossiblePath) then
    begin
      Settings.SpecKitPath := PossiblePath;
      Settings.SaveToConfig;
      FEngine.SkillsLoader.SpecKitPath := PossiblePath;
      Exit;
    end;
  end;

  // Try lazarus-spec-kit beside the Lazarus executable
  PossiblePath := IncludeTrailingPathDelimiter(
    ExtractFilePath(ParamStr(0))) + 'lazarus-spec-kit';
  if DirectoryExists(PossiblePath) then
  begin
    Settings.SpecKitPath := PossiblePath;
    Settings.SaveToConfig;
    FEngine.SkillsLoader.SpecKitPath := PossiblePath;
    Exit;
  end;
end;

procedure TSpecWizardForm.SetCurrentMode(AMode: TSpecMode);
const
  ModeKeys: array[TSpecMode] of string = ('Mode.Ask', 'Mode.Plan', 'Mode.Agent');
begin
  FCurrentMode := AMode;
  UpdateModeButtons;
  statusBar.SimpleText := Format(TR('Status.ModeFmt'), [TR(ModeKeys[AMode])]);
  btnApply.Visible := (AMode = smAgent);
end;

procedure TSpecWizardForm.UpdateModeButtons;
begin
  btnAsk.Down := (FCurrentMode = smAsk);
  btnPlan.Down := (FCurrentMode = smPlan);
  btnAgent.Down := (FCurrentMode = smAgent);
end;

procedure TSpecWizardForm.UpdateStatusBar(const AResponse: TAIResponse);
begin
  if AResponse.Success then
    statusBar.SimpleText := Format(TR('Status.TokensFmt'),
      [AResponse.PromptTokens, AResponse.CompletionTokens,
       AResponse.TotalTokens, AResponse.Model])
  else
    statusBar.SimpleText := TR('Status.Error') + AResponse.ErrorMessage;
end;

procedure TSpecWizardForm.LoadSkillsList;
var
  Skills: TSkillInfoArray;
  I: Integer;
begin
  clbSkills.Items.BeginUpdate;
  try
    clbSkills.Items.Clear;
    FEngine.SkillsLoader.ScanSkills;
    Skills := FEngine.SkillsLoader.GetSkillList;
    for I := 0 to Length(Skills) - 1 do
      clbSkills.Items.Add(Skills[I].Name + ' [' + Skills[I].Category + ']');
  finally
    clbSkills.Items.EndUpdate;
  end;
end;

function TSpecWizardForm.GetSelectedSkillIDs: TStringList;
var
  Skills: TSkillInfoArray;
  I: Integer;
begin
  Result := TStringList.Create;
  Skills := FEngine.SkillsLoader.GetSkillList;
  for I := 0 to clbSkills.Count - 1 do
    if clbSkills.Checked[I] and (I < Length(Skills)) then
      Result.Add(Skills[I].ID);
end;

procedure TSpecWizardForm.SetUIProcessing(AProcessing: Boolean);
begin
  FProcessing := AProcessing;
  btnSend.Enabled := not AProcessing;
  btnCancel.Enabled := AProcessing;
  btnAsk.Enabled := not AProcessing;
  btnPlan.Enabled := not AProcessing;
  btnAgent.Enabled := not AProcessing;
  memInput.Enabled := not AProcessing;

  if AProcessing then
  begin
    statusBar.SimpleText := TR('Status.Processing');
    Screen.Cursor := crHourGlass;
  end
  else
    Screen.Cursor := crDefault;

  Application.ProcessMessages;
end;

procedure TSpecWizardForm.DoSendRequest;
var
  UserInput: string;
  SelectedSkills: TStringList;
  ProjectName, ActiveFile, SelectedText: string;
begin
  UserInput := Trim(memInput.Text);
  if UserInput = '' then
  begin
    memInput.SetFocus;
    Exit;
  end;

  if FProcessing then Exit;

  ProjectName := '';
  ActiveFile := '';
  SelectedText := '';

  if TProjectHelper.HasActiveProject then
    ProjectName := TProjectHelper.GetProjectName;
  if TEditorHelper.HasActiveEditor then
  begin
    ActiveFile := TEditorHelper.GetActiveFileName;
    SelectedText := TEditorHelper.GetSelectedText;
  end;

  SelectedSkills := GetSelectedSkillIDs;
  // SelectedSkills ownership is transferred to TRequestThread

  FRequestThread := TRequestThread.Create(
    FEngine, FCurrentMode, UserInput, SelectedSkills,
    ProjectName, ActiveFile, SelectedText
  );
  FRequestThread.OnTerminate := @OnRequestDone;

  SetUIProcessing(True);
  FRequestThread.Start;
end;

procedure TSpecWizardForm.OnRequestDone(Sender: TObject);
begin
  // Called from the thread — use Synchronize context (OnTerminate fires in main thread via LCL)
  SetUIProcessing(False);

  synOutput.Lines.Text := FRequestThread.Result;
  synOutput.CaretXY := Point(1, 1);
  UpdateStatusBar(FRequestThread.LastResponse);

  if not FRequestThread.Terminated or FRequestThread.LastResponse.Success then
    memInput.Clear;

  FreeAndNil(FRequestThread);
end;

// Event handlers

procedure TSpecWizardForm.btnAskClick(Sender: TObject);
begin
  SetCurrentMode(smAsk);
end;

procedure TSpecWizardForm.btnPlanClick(Sender: TObject);
begin
  SetCurrentMode(smPlan);
end;

procedure TSpecWizardForm.btnAgentClick(Sender: TObject);
begin
  SetCurrentMode(smAgent);
end;

procedure TSpecWizardForm.btnSendClick(Sender: TObject);
begin
  DoSendRequest;
end;

procedure TSpecWizardForm.btnCancelClick(Sender: TObject);
begin
  if FProcessing and Assigned(FRequestThread) then
  begin
    statusBar.SimpleText := TR('Status.Cancelling');
    if FEngine.AIClient <> nil then
      FEngine.AIClient.AbortRequest;
    FRequestThread.Terminate;
  end;
end;

procedure TSpecWizardForm.btnSettingsClick(Sender: TObject);
var
  Dlg: TdlgSpecSettings;
begin
  Dlg := TdlgSpecSettings.Create(Self);
  try
    if Dlg.ShowModal = mrOK then
    begin
      // Force settings reload and client re-creation with new values
      TSpecSettings.Instance.ReloadFromConfig;
      FEngine.AIClient := nil;
      RefreshCodeAssistantMenus;
      AutoDetectSpecKitPath;
      LoadSkillsList;
      // Refresh UI to reflect any language change
      ApplyTranslations;
      SetCurrentMode(FCurrentMode);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TSpecWizardForm.btnClearClick(Sender: TObject);
begin
  if MessageDlg(TR('Dlg.Clear.Title'), TR('Dlg.Clear.Text'),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    synOutput.Lines.Clear;
    FEngine.ClearContext;
    statusBar.SimpleText := TR('Status.Cleared');
  end;
end;

procedure TSpecWizardForm.btnCopyClick(Sender: TObject);
begin
  if synOutput.Lines.Text <> '' then
  begin
    Clipboard.AsText := synOutput.Lines.Text;
    statusBar.SimpleText := TR('Status.Copied');
  end;
end;

procedure TSpecWizardForm.btnExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Content: string;
  Stream: TFileStream;
begin
  Content := synOutput.Lines.Text;
  if Content = '' then
  begin
    statusBar.SimpleText := TR('Status.NothingToExport');
    Exit;
  end;

  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Title := TR('Dlg.Export.Title');
    Dlg.DefaultExt := 'md';
    Dlg.Filter := TR('Dlg.Export.Filter');
    Dlg.Options := Dlg.Options + [ofOverwritePrompt];
    if TProjectHelper.HasActiveProject then
      Dlg.InitialDir := TProjectHelper.GetProjectPath;
    if not Dlg.Execute then
      Exit;

    Stream := TFileStream.Create(Dlg.FileName, fmCreate);
    try
      Stream.WriteBuffer(Content[1], Length(Content));
    finally
      Stream.Free;
    end;
    statusBar.SimpleText := TR('Status.ExportedTo') + ExtractFileName(Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TSpecWizardForm.btnApplyClick(Sender: TObject);
var
  CodeBlocks: TStringList;
  I: Integer;
  FileName, Code, FullPath, BaseDir: string;
  Dlg: TSaveDialog;
  MsgRes: Integer;
begin
  if synOutput.Lines.Text = '' then Exit;

  CodeBlocks := FEngine.ExtractCodeBlocks(synOutput.Lines.Text);
  try
    if CodeBlocks.Count = 0 then
    begin
      // No code blocks found — insert raw text at cursor
      if TEditorHelper.HasActiveEditor then
      begin
        TEditorHelper.InsertTextAtCursor(synOutput.Lines.Text);
        statusBar.SimpleText := TR('Status.Inserted');
      end
      else
        MessageDlg(TR('Dlg.NoEditor.Title'), TR('Dlg.NoEditor.Text'),
          mtWarning, [mbOK], 0);
      Exit;
    end;

    // Determine base directory for saving files
    BaseDir := '';
    if TProjectHelper.HasActiveProject then
    begin
      BaseDir := TProjectHelper.GetProjectPath;
      if BaseDir <> '' then
        BaseDir := IncludeTrailingPathDelimiter(BaseDir);
    end;

    for I := 0 to CodeBlocks.Count - 1 do
    begin
      FileName := CodeBlocks.Names[I];
      Code := CodeBlocks.ValueFromIndex[I];

      // Resolve full path
      if BaseDir <> '' then
        FullPath := BaseDir + FileName
      else
      begin
        // No active project: ask user where to save
        Dlg := TSaveDialog.Create(nil);
        try
          Dlg.Title := Format(TR('Dlg.SaveFile.TitleFmt'), [FileName]);
          Dlg.FileName := FileName;
          Dlg.DefaultExt := 'pas';
          Dlg.Filter := 'Pascal files (*.pas)|*.pas|All files (*.*)|*.*';
          Dlg.Options := Dlg.Options + [ofOverwritePrompt];
          if Dlg.Execute then
            FullPath := Dlg.FileName
          else
            Continue; // User cancelled this file
        finally
          Dlg.Free;
        end;
      end;

      // Confirm creation showing the full resolved path
      MsgRes := MessageDlg(TR('Dlg.CreateFile.Title'),
        Format(TR('Dlg.CreateFile.Fmt'), [FullPath]),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);

      if MsgRes = mrCancel then Break
      else if MsgRes = mrNo then Continue;

      // Create the file
      if TFileCreator.CreateAndAddToProject(FullPath, Code) then
        statusBar.SimpleText := TR('Status.Created') + ExtractFileName(FullPath)
      else
        MessageDlg(TR('Dlg.FileError.Title'),
          Format(TR('Dlg.FileError.Fmt'), [FullPath]),
          mtError, [mbOK], 0);
    end;
  finally
    CodeBlocks.Free;
  end;
end;

procedure TSpecWizardForm.ApplyTranslations;
begin
  Caption              := TR('Form.SpecWizard');
  btnAsk.Caption       := TR('Btn.Ask');
  btnPlan.Caption      := TR('Btn.Plan');
  btnAgent.Caption     := TR('Btn.Agent');
  btnSettings.Caption  := TR('Btn.Settings');
  btnExport.Caption    := TR('Btn.Export');
  lblSkills.Caption    := TR('Lbl.Skills');
  btnSend.Caption      := TR('Btn.Send');
  btnCancel.Caption    := TR('Btn.Cancel');
  btnCopy.Caption      := TR('Btn.Copy');
  btnApply.Caption     := TR('Btn.Apply');
end;

procedure TSpecWizardForm.memInputKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Enter sends, Ctrl+Enter inserts a new line
  if (Key = VK_RETURN) and not (ssCtrl in Shift) then
  begin
    Key := 0;
    if not FProcessing and FInitialized then
      DoSendRequest;
  end;
end;

end.
