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

unit CodeAssistantHandler;

{$mode objfpc}{$H+}

{ TCodeAssistantHandler
  ─────────────────────
  Integrates the AI Code Assistant with the Lazarus IDE:
    1. Adds "AI Assistant" submenu directly in the source-editor context menu
       (sibling of Refatorar, not nested inside it) with bitmap-icon items:
       Refatorar / Explicar / Completar / Corrigir.
    2. Adds 4 coloured bullet buttons (R/E/C/F) in the editor gutter next to
       the selection-start line; clicking each one triggers the matching action.
    3. Exposes TriggerCodeAssistantDefault for the Ctrl+Shift+A shortcut
       registered in LazSpecWizardReg. }

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, LCLType,
  SrcEditorIntf, MenuIntf, SynEdit, SynEditMiscClasses, SynGutterBase,
  SynEditTypes;

type
  { TAssistantGutterPart }
  TAssistantGutterPart = class(TSynGutterPartBase)
  private
    FSynEditRef: TCustomSynEdit;  // stored for safe handler unregistration
    procedure OnEditorStatusChange(Sender: TObject; Changes: TSynStatusChanges);
  protected
    function PreferedWidth: Integer; override;
    procedure Init; override;
    function GetOwnerSynEdit: TSynEditBase;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint(Canvas: TCanvas; AClip: TRect;
      FirstLine, LastLine: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    // Expose protected SynEdit for external duplicate-check
    property OwnerSynEdit: TSynEditBase read GetOwnerSynEdit;
  end;

  { TCodeAssistantHandler }
  TCodeAssistantHandler = class
  private
    FGutterParts: TList;
    FAISubMenu: TIDEMenuSection;
    FCmdRefactor: TIDEMenuCommand;
    FCmdExplain: TIDEMenuCommand;
    FCmdComplete: TIDEMenuCommand;
    FCmdFix: TIDEMenuCommand;
    FCmdReview: TIDEMenuCommand;
    procedure OnEditorCreated(Sender: TObject);
    procedure EnsureGutterForEditor(AEditor: TSourceEditorInterface);
    procedure OnMenuRefactor(Sender: TObject);
    procedure OnMenuExplain(Sender: TObject);
    procedure OnMenuComplete(Sender: TObject);
    procedure OnMenuFix(Sender: TObject);
    procedure OnMenuReview(Sender: TObject);
    procedure TriggerAssistant(AAction: Integer);
    procedure UpdateMenuCaptions;
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  CodeAssistantHandlerInstance: TCodeAssistantHandler = nil;

procedure InitCodeAssistantHandler;
procedure FinalizeCodeAssistantHandler;
procedure TriggerCodeAssistantDefault(Sender: TObject);
procedure RefreshCodeAssistantMenus;

implementation

uses
  frmCodeAssistant, EditorHelper, LazSpecLang;

{ Helper – creates a 16x16 coloured-circle bitmap with a white letter }
function CreateActionBitmap(ABgColor: TColor; const ALetter: string): TBitmap;
var
  TW, TH: Integer;
begin
  Result := TBitmap.Create;
  Result.SetSize(16, 16);
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
  with Result.Canvas do
  begin
    Brush.Color := clFuchsia;
    FillRect(0, 0, 16, 16);
    Brush.Color := ABgColor;
    Pen.Color   := ABgColor;
    Ellipse(1, 1, 15, 15);
    Font.Color  := clWhite;
    Font.Size   := 7;
    Font.Style  := [fsBold];
    Brush.Style := bsClear;
    TW := TextWidth(ALetter);
    TH := TextHeight('A');
    TextOut((16 - TW) div 2, (16 - TH) div 2, ALetter);
  end;
end;

{ TAssistantGutterPart }

constructor TAssistantGutterPart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSynEditRef := nil;
end;

destructor TAssistantGutterPart.Destroy;
begin
  if FSynEditRef <> nil then
  begin
    FSynEditRef.UnRegisterStatusChangedHandler(@OnEditorStatusChange);
    FSynEditRef := nil;
  end;

  inherited Destroy;
end;

procedure TAssistantGutterPart.OnEditorStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  // Force gutter repaint whenever selection appears / disappears
  if scSelection in Changes then
    if FSynEditRef <> nil then
      FSynEditRef.Invalidate;
end;

function TAssistantGutterPart.GetOwnerSynEdit: TSynEditBase;
begin
  Result := SynEdit;
end;

procedure TAssistantGutterPart.Init;
begin
  inherited Init;
  // AutoSize must be False, otherwise SetWidth is silently ignored
  AutoSize := False;
  Width    := 18;
  Visible  := True;
  // Register status-change hook so the gutter repaints on selection change
  if SynEdit is TCustomSynEdit then
  begin
    FSynEditRef := TCustomSynEdit(SynEdit);
    FSynEditRef.RegisterStatusChangedHandler(
      @OnEditorStatusChange, [scSelection]);
  end;
end;

function TAssistantGutterPart.PreferedWidth: Integer;
begin
  Result := 18;
end;

procedure TAssistantGutterPart.Paint(Canvas: TCanvas; AClip: TRect;
  FirstLine, LastLine: Integer);
const
  // TColor = $00BBGGRR
  BTN_COLORS: array[0..3] of TColor = (
    $00C83264,  // R – Refatorar: indigo
    $00B49600,  // E – Explicar:  teal
    $0028A028,  // C – Completar: green
    $000A5ADC   // F – Corrigir:  orange
  );
  BTN_LABELS: array[0..3] of string = ('R', 'E', 'C', 'F');
var
  LineHeight, SelStartLine, I, BtnLine: Integer;
  HasSel: Boolean;
  SynEditCtrl: TCustomSynEdit;
  BallD, CX, CY, BallX, BallY, RowY: Integer;
  OldFontSize: Integer;
  OldFontStyle: TFontStyles;
  OldBrushStyle: TBrushStyle;
begin
  if not (SynEdit is TCustomSynEdit) then Exit;
  SynEditCtrl  := TCustomSynEdit(SynEdit);
  HasSel       := SynEditCtrl.SelAvail;
  if not HasSel then Exit;

  SelStartLine := SynEditCtrl.BlockBegin.Y;  // 1-based
  LineHeight   := SynEditCtrl.LineHeight;

  // Centre X of the single column
  CX    := Width div 2;
  // Bullet diameter: snug fit, max Width-4
  BallD := LineHeight - 4;
  if BallD > Width - 4 then BallD := Width - 4;
  if BallD < 6 then BallD := 6;

  OldFontSize   := Canvas.Font.Size;
  OldFontStyle  := Canvas.Font.Style;
  OldBrushStyle := Canvas.Brush.Style;
  Canvas.Font.Size  := 6;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Pen.Width  := 1;

  // Draw one bullet per action, stacked vertically from the selection start line
  for I := 0 to 3 do
  begin
    BtnLine := SelStartLine + I;  // 1-based absolute line for this button
    if (BtnLine < FirstLine) or (BtnLine > LastLine) then Continue;

    RowY  := (BtnLine - FirstLine) * LineHeight;
    CY    := RowY + LineHeight div 2;
    BallX := CX - BallD div 2;
    BallY := CY - BallD div 2;

    Canvas.Brush.Color := BTN_COLORS[I];
    Canvas.Pen.Color   := BTN_COLORS[I];
    Canvas.Brush.Style := bsSolid;
    Canvas.Ellipse(BallX, BallY, BallX + BallD, BallY + BallD);

    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(
      CX - Canvas.TextWidth(BTN_LABELS[I]) div 2,
      CY - Canvas.TextHeight('A') div 2,
      BTN_LABELS[I]);
  end;

  Canvas.Font.Size   := OldFontSize;
  Canvas.Font.Style  := OldFontStyle;
  Canvas.Brush.Style := OldBrushStyle;
end;

procedure TAssistantGutterPart.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  SelCode: string;
  Action: TCodeAssistAction;
  LineHeight, SelStartLine, AbsLine, ActionIdx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then Exit;
  if not (SynEdit is TCustomSynEdit) then Exit;

  LineHeight   := TCustomSynEdit(SynEdit).LineHeight;
  SelStartLine := TCustomSynEdit(SynEdit).BlockBegin.Y;  // 1-based
  // Y is relative to the top of the visible gutter area
  AbsLine   := TCustomSynEdit(SynEdit).TopLine + (Y div LineHeight);
  ActionIdx := AbsLine - SelStartLine;  // 0=R, 1=E, 2=C, 3=F

  case ActionIdx of
    0: Action := caaRefactor;
    1: Action := caaExplain;
    2: Action := caaComplete;
    3: Action := caaFix;
  else
    Exit;  // clicked outside the 4 buttons
  end;

  SelCode := TEditorHelper.GetSelectedText;
  if Trim(SelCode) = '' then
    SelCode := TEditorHelper.GetActiveSourceCode;
  ShowCodeAssistant(SelCode, Action);
end;

{ TCodeAssistantHandler }

constructor TCodeAssistantHandler.Create;
var
  AISubMenu: TIDEMenuSection;
  AIParent: TIDEMenuSection;
  Cmd: TIDEMenuCommand;
  Bmp: TBitmap;
  I: Integer;
begin
  inherited Create;
  FGutterParts := TList.Create;
  FAISubMenu := nil;
  FCmdRefactor := nil;
  FCmdExplain := nil;
  FCmdComplete := nil;
  FCmdFix := nil;
  FCmdReview := nil;

  // ── Register AI Assistant at the MAIN context-menu level ──────────────────
  // Use the parent section of SrcEditSubMenuRefactor so the submenu appears
  // alongside (not inside) Refatorar.
  AIParent := nil;
  if SrcEditSubMenuRefactor <> nil then
  begin
    if SrcEditSubMenuRefactor.Section <> nil then
      AIParent := SrcEditSubMenuRefactor.Section
    else
      AIParent := SrcEditSubMenuRefactor;
  end;

  if AIParent <> nil then
  begin
    AISubMenu := RegisterIDESubMenu(AIParent, 'AIAssistSubMenu', TR('Menu.AIAssistant'));
    FAISubMenu := AISubMenu;
    if AISubMenu <> nil then
    begin
      Cmd := RegisterIDEMenuCommand(AISubMenu, 'AIAssist_Refactor',
        TR('Menu.Refactor'), @OnMenuRefactor);
      FCmdRefactor := Cmd;
      if Cmd <> nil then
      begin
        Bmp := CreateActionBitmap($00C83264, 'R');
        Cmd.Bitmap := Bmp;
      end;

      Cmd := RegisterIDEMenuCommand(AISubMenu, 'AIAssist_Explain',
        TR('Menu.Explain'), @OnMenuExplain);
      FCmdExplain := Cmd;
      if Cmd <> nil then
      begin
        Bmp := CreateActionBitmap($00B49600, 'E');
        Cmd.Bitmap := Bmp;
      end;

      Cmd := RegisterIDEMenuCommand(AISubMenu, 'AIAssist_Complete',
        TR('Menu.Complete'), @OnMenuComplete);
      FCmdComplete := Cmd;
      if Cmd <> nil then
      begin
        Bmp := CreateActionBitmap($0028A028, 'C');
        Cmd.Bitmap := Bmp;
      end;

      Cmd := RegisterIDEMenuCommand(AISubMenu, 'AIAssist_Fix',
        TR('Menu.Fix'), @OnMenuFix);
      FCmdFix := Cmd;
      if Cmd <> nil then
      begin
        Bmp := CreateActionBitmap($000A5ADC, 'F');
        Cmd.Bitmap := Bmp;
      end;

      Cmd := RegisterIDEMenuCommand(AISubMenu, 'AIAssist_Review',
        TR('Menu.Review'), @OnMenuReview);
      FCmdReview := Cmd;
      if Cmd <> nil then
      begin
        Bmp := CreateActionBitmap($00AA6699, 'V');
        Cmd.Bitmap := Bmp;
      end;

      UpdateMenuCaptions;
    end;
  end;

  // ── Listen for new editors so we inject the gutter part ───────────────────
  if SourceEditorManagerIntf <> nil then
    SourceEditorManagerIntf.RegisterChangeEvent(semEditorCreate,
      @OnEditorCreated);

  // ── Add gutter to editors already open ────────────────────────────────────
  if SourceEditorManagerIntf <> nil then
    for I := 0 to SourceEditorManagerIntf.SourceEditorCount - 1 do
      EnsureGutterForEditor(SourceEditorManagerIntf.SourceEditors[I]);
end;

destructor TCodeAssistantHandler.Destroy;
begin
  if SourceEditorManagerIntf <> nil then
    SourceEditorManagerIntf.UnRegisterChangeEvent(semEditorCreate,
      @OnEditorCreated);

  // Parts are owned by SynEdit; just release our reference list.
  FGutterParts.Clear;
  FreeAndNil(FGutterParts);
  inherited Destroy;
end;

procedure TCodeAssistantHandler.OnEditorCreated(Sender: TObject);
begin
  if SourceEditorManagerIntf = nil then Exit;
  EnsureGutterForEditor(SourceEditorManagerIntf.ActiveEditor);
end;

procedure TCodeAssistantHandler.EnsureGutterForEditor(
  AEditor: TSourceEditorInterface);
var
  SynEditCtrl: TCustomSynEdit;
  Part: TAssistantGutterPart;
  I: Integer;
begin
  if AEditor = nil then Exit;
  if not (AEditor.EditorControl is TCustomSynEdit) then Exit;

  SynEditCtrl := TCustomSynEdit(AEditor.EditorControl);

  // Only add once per SynEdit instance
  for I := 0 to FGutterParts.Count - 1 do
    if TAssistantGutterPart(FGutterParts[I]).OwnerSynEdit = SynEditCtrl then
      Exit;

  Part := TAssistantGutterPart.Create(SynEditCtrl.Gutter.Parts);
  FGutterParts.Add(Part);
  // Force the gutter to recalculate total width including our part
  SynEditCtrl.Gutter.DoAutoSize;
  SynEditCtrl.Invalidate;
end;

procedure TCodeAssistantHandler.OnMenuRefactor(Sender: TObject);
begin
  TriggerAssistant(1);
end;

procedure TCodeAssistantHandler.OnMenuExplain(Sender: TObject);
begin
  TriggerAssistant(2);
end;

procedure TCodeAssistantHandler.OnMenuComplete(Sender: TObject);
begin
  TriggerAssistant(3);
end;

procedure TCodeAssistantHandler.OnMenuFix(Sender: TObject);
begin
  TriggerAssistant(4);
end;

procedure TCodeAssistantHandler.OnMenuReview(Sender: TObject);
begin
  TriggerAssistant(5);
end;

procedure TCodeAssistantHandler.TriggerAssistant(AAction: Integer);
var
  Code: string;
  Action: TCodeAssistAction;
begin
  Code := TEditorHelper.GetSelectedText;
  if Trim(Code) = '' then
    Code := TEditorHelper.GetActiveSourceCode;

  case AAction of
    1: Action := caaRefactor;
    2: Action := caaExplain;
    3: Action := caaComplete;
    4: Action := caaFix;
    5: Action := caaReview;
  else
    Action := caaExplain;
  end;

  ShowCodeAssistant(Code, Action);
end;

procedure TCodeAssistantHandler.UpdateMenuCaptions;
begin
  if FAISubMenu <> nil then
    FAISubMenu.Caption := TR('Menu.AIAssistant');
  if FCmdRefactor <> nil then
    FCmdRefactor.Caption := TR('Menu.Refactor');
  if FCmdExplain <> nil then
    FCmdExplain.Caption := TR('Menu.Explain');
  if FCmdComplete <> nil then
    FCmdComplete.Caption := TR('Menu.Complete');
  if FCmdFix <> nil then
    FCmdFix.Caption := TR('Menu.Fix');
  if FCmdReview <> nil then
    FCmdReview.Caption := TR('Menu.Review');
end;

{ Module level }

procedure InitCodeAssistantHandler;
begin
  if CodeAssistantHandlerInstance = nil then
    CodeAssistantHandlerInstance := TCodeAssistantHandler.Create;
end;

procedure FinalizeCodeAssistantHandler;
begin
  FreeAndNil(CodeAssistantHandlerInstance);
end;

procedure TriggerCodeAssistantDefault(Sender: TObject);
var
  Code: string;
begin
  InitCodeAssistantHandler;
  Code := TEditorHelper.GetSelectedText;
  if Trim(Code) = '' then
    Code := TEditorHelper.GetActiveSourceCode;
  ShowCodeAssistant(Code, caaExplain);
end;

procedure RefreshCodeAssistantMenus;
begin
  if CodeAssistantHandlerInstance <> nil then
    CodeAssistantHandlerInstance.UpdateMenuCaptions;
end;

finalization
  FinalizeCodeAssistantHandler;

end.
