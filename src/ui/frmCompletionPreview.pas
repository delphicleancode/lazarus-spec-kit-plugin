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
  SynEdit, SynHighlighterPas, LCLType;

type
  { TfrmCompletionPreview }
  TfrmCompletionPreview = class(TForm)
    pnlButtons: TPanel;
    lblHint: TLabel;
    btnApply: TButton;
    btnCancel: TButton;
    synPreview: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    function GetTextToInsert: string;
    procedure LoadCompletion(const ACode: string);
  end;

function ShowCompletionPreview(const ACode: string; AX, AY: Integer): string;

implementation

{$R *.lfm}

function ShowCompletionPreview(const ACode: string; AX, AY: Integer): string;
var
  Frm: TfrmCompletionPreview;
begin
  Result := '';
  Frm := TfrmCompletionPreview.Create(Application);
  try
    Frm.LoadCompletion(ACode);
    Frm.Left := AX;
    Frm.Top := AY;
    if Frm.ShowModal = mrOk then
      Result := Frm.GetTextToInsert;
  finally
    Frm.Free;
  end;
end;

{ TfrmCompletionPreview }

procedure TfrmCompletionPreview.FormCreate(Sender: TObject);
begin
  synPreview.Highlighter := SynPasSyn1;
  synPreview.Font.Quality := fqDefault;
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
