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

unit dlgSpecSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Spin, EditBtn, SpecSettings, LazSpecLang;

type
  { TdlgSpecSettings - Settings dialog for the Spec Wizard }
  TdlgSpecSettings = class(TForm)
    pnlMain: TPanel;
    lblProvider: TLabel;
    cmbProvider: TComboBox;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    lblModel: TLabel;
    cmbModel: TComboBox;
    lblOllamaURL: TLabel;
    edtOllamaURL: TEdit;
    lblMaxTokens: TLabel;
    seMaxTokens: TSpinEdit;
    lblTemperature: TLabel;
    edtTemperature: TEdit;
    lblSpecKitPath: TLabel;
    deSpecKitPath: TDirectoryEdit;
    lblLanguage: TLabel;
    cmbLanguage: TComboBox;
    btnTestConnection: TButton;
    gbAutoComplete: TGroupBox;
    chkAutoComplete: TCheckBox;
    lblACMaxTokens: TLabel;
    seACMaxTokens: TSpinEdit;
    lblACTemperature: TLabel;
    edtACTemperature: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnTestConnectionClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cmbProviderChange(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateProviderUI;
    procedure ApplyTranslations;
  end;

implementation

uses
  BaseAIClient, GroqClient;

{$R *.lfm}

{ TdlgSpecSettings }

procedure TdlgSpecSettings.FormCreate(Sender: TObject);
begin
  LoadSettings;
  UpdateProviderUI;
  ApplyTranslations;
end;

procedure TdlgSpecSettings.LoadSettings;
var
  Settings: TSpecSettings;
begin
  Settings := TSpecSettings.Instance;

  // Provider
  if Settings.Provider = 'ollama' then
    cmbProvider.ItemIndex := 1
  else
    cmbProvider.ItemIndex := 0;

  // API Key
  edtApiKey.Text := Settings.ApiKey;

  // Model
  cmbModel.Text := Settings.Model;

  // Ollama URL
  edtOllamaURL.Text := Settings.OllamaURL;

  // Max tokens
  seMaxTokens.Value := Settings.MaxTokens;

  // Temperature
  edtTemperature.Text := FormatFloat('0.0', Settings.Temperature);

  // Spec-kit path
  deSpecKitPath.Text := Settings.SpecKitPath;

  // Language (0=English, 1=Português BR)
  if Settings.Language = 'pt-BR' then
    cmbLanguage.ItemIndex := 1
  else
    cmbLanguage.ItemIndex := 0;

  // Autocomplete
  chkAutoComplete.Checked := Settings.AutoCompleteEnabled;
  seACMaxTokens.Value := Settings.AutoCompleteMaxTokens;
  edtACTemperature.Text := FormatFloat('0.0', Settings.AutoCompleteTemperature);
end;

procedure TdlgSpecSettings.SaveSettings;
var
  Settings: TSpecSettings;
  TempVal: Double;
begin
  Settings := TSpecSettings.Instance;

  // Provider
  if cmbProvider.ItemIndex = 1 then
    Settings.Provider := 'ollama'
  else
    Settings.Provider := 'groq';

  // API Key
  Settings.ApiKey := edtApiKey.Text;

  // Model
  Settings.Model := cmbModel.Text;

  // Ollama URL
  Settings.OllamaURL := edtOllamaURL.Text;

  // Max tokens
  Settings.MaxTokens := seMaxTokens.Value;

  // Temperature
  if TryStrToFloat(edtTemperature.Text, TempVal) then
    Settings.Temperature := TempVal
  else
    Settings.Temperature := 0.7;

  // Spec-kit path
  Settings.SpecKitPath := deSpecKitPath.Text;

  // Language
  if cmbLanguage.ItemIndex = 1 then
    Settings.Language := 'pt-BR'
  else
    Settings.Language := 'en';

  // Autocomplete
  Settings.AutoCompleteEnabled := chkAutoComplete.Checked;
  Settings.AutoCompleteMaxTokens := seACMaxTokens.Value;
  if TryStrToFloat(edtACTemperature.Text, TempVal) then
    Settings.AutoCompleteTemperature := TempVal
  else
    Settings.AutoCompleteTemperature := 0.2;

  Settings.SaveToConfig;
end;

procedure TdlgSpecSettings.UpdateProviderUI;
var
  IsGroq: Boolean;
begin
  IsGroq := (cmbProvider.ItemIndex = 0);
  edtApiKey.Enabled := IsGroq;
  lblApiKey.Enabled := IsGroq;
  edtOllamaURL.Enabled := not IsGroq;
  lblOllamaURL.Enabled := not IsGroq;
end;

procedure TdlgSpecSettings.ApplyTranslations;
begin
  Caption                       := TR('Settings.Title');
  lblProvider.Caption           := TR('Settings.Provider');
  lblApiKey.Caption             := TR('Settings.ApiKey');
  lblModel.Caption              := TR('Settings.Model');
  lblOllamaURL.Caption          := TR('Settings.OllamaURL');
  lblMaxTokens.Caption          := TR('Settings.MaxTokens');
  lblTemperature.Caption        := TR('Settings.Temperature');
  lblSpecKitPath.Caption        := TR('Settings.SpecKitPath');
  lblLanguage.Caption           := TR('Settings.Language');
  btnTestConnection.Caption     := TR('Settings.TestConnection');
  gbAutoComplete.Caption        := TR('Settings.AutoComplete');
  chkAutoComplete.Caption       := TR('Settings.EnableAutoComplete');
  lblACMaxTokens.Caption        := TR('Settings.MaxTokens');
  lblACTemperature.Caption      := TR('Settings.Temperature');
  btnOK.Caption                 := TR('Settings.OK');
  btnCancel.Caption             := TR('Settings.Cancel');
end;

procedure TdlgSpecSettings.cmbProviderChange(Sender: TObject);
begin
  UpdateProviderUI;
end;

procedure TdlgSpecSettings.btnTestConnectionClick(Sender: TObject);
var
  Client: TGroqClient;
begin
  Screen.Cursor := crHourGlass;
  try
    if cmbProvider.ItemIndex = 0 then
    begin
      Client := TGroqClient.Create(edtApiKey.Text);
      try
        if Client.TestConnection then
          MessageDlg(TR('Conn.TestTitle'), TR('Conn.Success'),
            mtInformation, [mbOK], 0)
        else
          MessageDlg(TR('Conn.TestTitle'), TR('Conn.Fail'),
            mtError, [mbOK], 0);
      finally
        Client.Free;
      end;
    end
    else
      MessageDlg(TR('Conn.TestTitle'), TR('Conn.OllamaNotImpl'),
        mtInformation, [mbOK], 0);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TdlgSpecSettings.btnOKClick(Sender: TObject);
begin
  SaveSettings;
  ModalResult := mrOK;
end;

end.
