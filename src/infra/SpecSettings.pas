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

unit SpecSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazConfigStorage, BaseIDEIntf, LazIDEIntf;

type
  { TSpecSettings - Singleton for persistent plugin settings }
  TSpecSettings = class
  private
    FApiKey: string;
    FProvider: string;
    FModel: string;
    FOllamaURL: string;
    FQwenURL: string;
    FOpenRouterURL: string;
    FMaxTokens: Integer;
    FTemperature: Double;
    FSpecKitPath: string;
    FAutoCompleteEnabled: Boolean;
    FAutoCompleteMaxTokens: Integer;
    FAutoCompleteTemperature: Double;
    FLanguage: string;   // 'en' or 'pt-BR'
    FLoaded: Boolean;
    class function EncryptApiKey(const AKey: string): string;
    class function DecryptApiKey(const AEncrypted: string): string;
  public
    constructor Create;
    procedure LoadFromConfig;
    procedure SaveToConfig;
    procedure ReloadFromConfig;
    class function Instance: TSpecSettings;
    class procedure ReleaseInstance;

    property ApiKey: string read FApiKey write FApiKey;
    property Provider: string read FProvider write FProvider;
    property Model: string read FModel write FModel;
    property OllamaURL: string read FOllamaURL write FOllamaURL;
    property QwenURL: string read FQwenURL write FQwenURL;
    property OpenRouterURL: string read FOpenRouterURL write FOpenRouterURL;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;
    property Temperature: Double read FTemperature write FTemperature;
    property SpecKitPath: string read FSpecKitPath write FSpecKitPath;
    property AutoCompleteEnabled: Boolean read FAutoCompleteEnabled write FAutoCompleteEnabled;
    property AutoCompleteMaxTokens: Integer read FAutoCompleteMaxTokens write FAutoCompleteMaxTokens;
    property AutoCompleteTemperature: Double read FAutoCompleteTemperature write FAutoCompleteTemperature;
    property Language: string read FLanguage write FLanguage;  // 'en' or 'pt-BR'
  end;

implementation

uses
  base64
  {$IFDEF WINDOWS}
  , Windows
  {$ENDIF}
  ;

{$IFDEF WINDOWS}
const
  CRYPTPROTECT_UI_FORBIDDEN = $1;

type
  _DATA_BLOB = record
    cbData: DWORD;
    pbData: PBYTE;
  end;
  DATA_BLOB = _DATA_BLOB;
  PDATA_BLOB = ^DATA_BLOB;

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: LPCWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDATA_BLOB): BOOL; stdcall; external 'Crypt32.dll';

function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDATA_BLOB): BOOL; stdcall; external 'Crypt32.dll';
{$ENDIF}

const
  CONFIG_FILE = 'specwizard.xml';
  CONFIG_VERSION = 1;
  // Prefix stored with encrypted keys so we can detect plain-text legacy values
  ENCRYPTED_PREFIX = 'dpapi:';

var
  SettingsInstance: TSpecSettings = nil;

{ TSpecSettings }

class function TSpecSettings.EncryptApiKey(const AKey: string): string;
{$IFDEF WINDOWS}
var
  DataIn, DataOut: DATA_BLOB;
  PlainBytes: array of Byte;
  OutBytes: array of Byte;
  SS: TStringStream;
  Encoder: TBase64EncodingStream;
begin
  Result := AKey;
  if AKey = '' then Exit;
  try
    SetLength(PlainBytes, Length(AKey));
    Move(AKey[1], PlainBytes[0], Length(AKey));

    DataIn.cbData := Length(PlainBytes);
    DataIn.pbData := @PlainBytes[0];
    DataOut.cbData := 0;
    DataOut.pbData := nil;

    if CryptProtectData(@DataIn, nil, nil, nil, nil,
        CRYPTPROTECT_UI_FORBIDDEN, @DataOut) then
    try
      SetLength(OutBytes, DataOut.cbData);
      Move(DataOut.pbData^, OutBytes[0], DataOut.cbData);
      SS := TStringStream.Create('');
      try
        Encoder := TBase64EncodingStream.Create(SS);
        try
          Encoder.WriteBuffer(OutBytes[0], Length(OutBytes));
        finally
          Encoder.Free;
        end;
        Result := ENCRYPTED_PREFIX + SS.DataString;
      finally
        SS.Free;
      end;
    finally
      LocalFree(HLOCAL(DataOut.pbData));
    end;
  except
    Result := AKey;
  end;
end;
{$ELSE}
begin
  Result := AKey;
end;
{$ENDIF}

class function TSpecSettings.DecryptApiKey(const AEncrypted: string): string;
{$IFDEF WINDOWS}
var
  DataIn, DataOut: DATA_BLOB;
  Encoded: string;
  SS: TStringStream;
  Decoder: TBase64DecodingStream;
  DecodedBytes: array of Byte;
  Len: Integer;
begin
  Result := AEncrypted;
  if AEncrypted = '' then Exit;
  if Pos(ENCRYPTED_PREFIX, AEncrypted) <> 1 then Exit;

  try
    Encoded := Copy(AEncrypted, Length(ENCRYPTED_PREFIX) + 1, MaxInt);

    SS := TStringStream.Create(Encoded);
    try
      Decoder := TBase64DecodingStream.Create(SS, bdmMIME);
      try
        SetLength(DecodedBytes, SS.Size);
        Len := Decoder.Read(DecodedBytes[0], Length(DecodedBytes));
        SetLength(DecodedBytes, Len);
      finally
        Decoder.Free;
      end;
    finally
      SS.Free;
    end;

    if Len = 0 then Exit;

    DataIn.cbData := Len;
    DataIn.pbData := @DecodedBytes[0];
    DataOut.cbData := 0;
    DataOut.pbData := nil;

    if CryptUnprotectData(@DataIn, nil, nil, nil, nil,
        CRYPTPROTECT_UI_FORBIDDEN, @DataOut) then
    try
      SetLength(Result, DataOut.cbData);
      Move(DataOut.pbData^, Result[1], DataOut.cbData);
    finally
      LocalFree(HLOCAL(DataOut.pbData));
    end;
  except
    Result := AEncrypted;
  end;
end;
{$ELSE}
begin
  Result := AEncrypted;
end;
{$ENDIF}

{ TSpecSettings }

constructor TSpecSettings.Create;
begin
  inherited Create;
  FApiKey := '';
  FProvider := 'groq';
  FModel := 'llama-3.3-70b-versatile';
  FOllamaURL := 'http://localhost:11434';
  FQwenURL := 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  FOpenRouterURL := 'https://openrouter.ai/api/v1';
  FMaxTokens := 4096;
  FTemperature := 0.7;
  FSpecKitPath := '';
  FAutoCompleteEnabled := True;
  FAutoCompleteMaxTokens := 256;
  FAutoCompleteTemperature := 0.2;
  FLanguage := 'en';
  FLoaded := False;
end;

procedure TSpecSettings.LoadFromConfig;
var
  Config: TConfigStorage;
begin
  if FLoaded then Exit;
  try
    Config := GetIDEConfigStorage(CONFIG_FILE, True);
    try
      FApiKey := DecryptApiKey(Config.GetValue('Settings/ApiKey', ''));
      FProvider := Config.GetValue('Settings/Provider', 'groq');
      FModel := Config.GetValue('Settings/Model', 'llama-3.3-70b-versatile');
      FOllamaURL := Config.GetValue('Settings/OllamaURL', 'http://localhost:11434');
      FQwenURL := Config.GetValue('Settings/QwenURL', 'https://dashscope.aliyuncs.com/compatible-mode/v1');
      FOpenRouterURL := Config.GetValue('Settings/OpenRouterURL', 'https://openrouter.ai/api/v1');
      FMaxTokens := Config.GetValue('Settings/MaxTokens', 4096);
      FTemperature := StrToFloatDef(Config.GetValue('Settings/Temperature', '0.7'), 0.7);
      FSpecKitPath := Config.GetValue('Settings/SpecKitPath', '');
      FAutoCompleteEnabled := Config.GetValue('Settings/AutoCompleteEnabled', True);
      FAutoCompleteMaxTokens := Config.GetValue('Settings/AutoCompleteMaxTokens', 256);
      FAutoCompleteTemperature := StrToFloatDef(Config.GetValue('Settings/AutoCompleteTemperature', '0.2'), 0.2);
      FLanguage := Config.GetValue('Settings/Language', 'en');
      FLoaded := True;
    finally
      Config.Free;
    end;
  except
    on E: Exception do
    begin
      // Use defaults on load failure — do not set FLoaded so next call retries
    end;
  end;
end;

procedure TSpecSettings.SaveToConfig;
var
  Config: TConfigStorage;
begin
  try
    Config := GetIDEConfigStorage(CONFIG_FILE, False);
    try
      Config.SetDeleteValue('Settings/Version', CONFIG_VERSION, 0);
      Config.SetDeleteValue('Settings/ApiKey', EncryptApiKey(FApiKey), '');
      Config.SetDeleteValue('Settings/Provider', FProvider, 'groq');
      Config.SetDeleteValue('Settings/Model', FModel, 'llama-3.3-70b-versatile');
      Config.SetDeleteValue('Settings/OllamaURL', FOllamaURL, 'http://localhost:11434');
      Config.SetDeleteValue('Settings/QwenURL', FQwenURL, 'https://dashscope.aliyuncs.com/compatible-mode/v1');
      Config.SetDeleteValue('Settings/OpenRouterURL', FOpenRouterURL, 'https://openrouter.ai/api/v1');
      Config.SetDeleteValue('Settings/MaxTokens', FMaxTokens, 4096);
      Config.SetDeleteValue('Settings/Temperature', FloatToStr(FTemperature), '0.7');
      Config.SetDeleteValue('Settings/SpecKitPath', FSpecKitPath, '');
      Config.SetDeleteValue('Settings/AutoCompleteEnabled', FAutoCompleteEnabled, True);
      Config.SetDeleteValue('Settings/AutoCompleteMaxTokens', FAutoCompleteMaxTokens, 256);
      Config.SetDeleteValue('Settings/AutoCompleteTemperature', FloatToStr(FAutoCompleteTemperature), '0.2');
      Config.SetDeleteValue('Settings/Language', FLanguage, 'en');
      Config.WriteToDisk;
    finally
      Config.Free;
    end;
  except
    on E: Exception do
    begin
      // Silently fail on save error
    end;
  end;
end;

class function TSpecSettings.Instance: TSpecSettings;
begin
  if SettingsInstance = nil then
  begin
    SettingsInstance := TSpecSettings.Create;
    SettingsInstance.LoadFromConfig;
  end;
  Result := SettingsInstance;
end;

procedure TSpecSettings.ReloadFromConfig;
begin
  FLoaded := False;
  LoadFromConfig;
end;

class procedure TSpecSettings.ReleaseInstance;
begin
  FreeAndNil(SettingsInstance);
end;

finalization
  TSpecSettings.ReleaseInstance;

end.
