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

unit frmCompletionPreview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  SynEdit, SynHighlighterPas, LCLType, SpecSettings, LazSpecLang;

type
  TCompletionPreviewAction = (cpaCancel, cpaApply, cpaNext);

  { TfrmCompletionPreview }
  TfrmCompletionPreview = class(TForm)
    pnlButtons: TPanel;
    lblHint: TLabel;
    btnApply: TButton;
    btnCancel: TButton;
    btnNext: TButton;
    synPreview: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure ApplyTranslations;
  public
    function GetTextToInsert: string;
    procedure LoadCompletion(const ACode: string);
  end;

function ShowCompletionPreview(const ACode: string; AX, AY: Integer;
  out ATextToInsert: string; ACanSuggestNext: Boolean = True): TCompletionPreviewAction;

implementation

{$R *.lfm}

function ShowCompletionPreview(const ACode: string; AX, AY: Integer;
  out ATextToInsert: string; ACanSuggestNext: Boolean): TCompletionPreviewAction;
var
  Frm: TfrmCompletionPreview;
begin
  ATextToInsert := '';
  Result := cpaCancel;
  Frm := TfrmCompletionPreview.Create(Application);
  try
    Frm.LoadCompletion(ACode);
    Frm.btnNext.Visible := ACanSuggestNext;
    Frm.Left := AX;
    Frm.Top := AY;
    case Frm.ShowModal of
      mrOk:
      begin
        ATextToInsert := Frm.GetTextToInsert;
        Result := cpaApply;
      end;
      mrRetry:
        Result := cpaNext;
    else
      Result := cpaCancel;
    end;
  finally
    Frm.Free;
  end;
end;

{ TfrmCompletionPreview }

procedure TfrmCompletionPreview.FormCreate(Sender: TObject);
begin
  synPreview.Highlighter := SynPasSyn1;
  synPreview.Font.Quality := fqDefault;
  btnNext.ModalResult := mrRetry;
  ApplyTranslations;
end;

procedure TfrmCompletionPreview.ApplyTranslations;
var
  Settings: TSpecSettings;
begin
  Settings := TSpecSettings.Instance;
  Caption := TR('Form.CompletionPreview') +
    ' (' + Settings.Provider + ' - ' + Settings.Model + ')';
  lblHint.Caption := TR('Completion.Hint');
  btnApply.Caption := TR('Btn.ApplyCode');
  btnCancel.Caption := TR('Btn.Cancel');
  btnNext.Caption := TR('Btn.NextSuggestion');
end;

procedure TfrmCompletionPreview.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmCompletionPreview.LoadCompletion(const ACode: string);
begin
  synPreview.Text := ACode;
end;

function TfrmCompletionPreview.GetTextToInsert: string;
begin
  Result := synPreview.SelText;
  if Trim(Result) = '' then
    Result := synPreview.Text;
end;

end.
