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

unit ContextMemory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, BaseAIClient;

type
  { TContextMemory - Manages conversation history per project }
  TContextMemory = class
  private
    FMessages: TAIMessages;
    FMaxMessages: Integer;
    FProjectPath: string;
    function GetHistoryFilePath: string;
  public
    constructor Create(const AProjectPath: string);
    procedure AddMessage(const ARole, AContent: string);
    procedure AddUserMessage(const AContent: string);
    procedure AddAssistantMessage(const AContent: string);
    function GetHistory: TAIMessages;
    procedure ClearHistory;
    procedure LoadFromFile;
    procedure SaveToFile;
    function MessageCount: Integer;
    property MaxMessages: Integer read FMaxMessages write FMaxMessages;
    property ProjectPath: string read FProjectPath write FProjectPath;
  end;

implementation

const
  LAZSPEC_DIR = '.lazspec';
  HISTORY_FILE = 'history.json';
  DEFAULT_MAX_MESSAGES = 20;

{ TContextMemory }

constructor TContextMemory.Create(const AProjectPath: string);
begin
  inherited Create;
  FProjectPath := AProjectPath;
  FMaxMessages := DEFAULT_MAX_MESSAGES;
  SetLength(FMessages, 0);
end;

function TContextMemory.GetHistoryFilePath: string;
begin
  Result := IncludeTrailingPathDelimiter(FProjectPath) +
            LAZSPEC_DIR + PathDelim + HISTORY_FILE;
end;

procedure TContextMemory.AddMessage(const ARole, AContent: string);
var
  Len, I: Integer;
begin
  Len := Length(FMessages);
  // Trim oldest 2 messages to keep history bounded
  if Len >= FMaxMessages then
  begin
    // Use loop to correctly handle AnsiString reference counts
    for I := 0 to Len - 3 do
      FMessages[I] := FMessages[I + 2];
    SetLength(FMessages, Len - 2);
    Len := Length(FMessages);
  end;
  SetLength(FMessages, Len + 1);
  FMessages[Len].Role := ARole;
  FMessages[Len].Content := AContent;
end;

procedure TContextMemory.AddUserMessage(const AContent: string);
begin
  AddMessage('user', AContent);
end;

procedure TContextMemory.AddAssistantMessage(const AContent: string);
begin
  AddMessage('assistant', AContent);
end;

function TContextMemory.GetHistory: TAIMessages;
begin
  Result := Copy(FMessages, 0, Length(FMessages));
end;

procedure TContextMemory.ClearHistory;
begin
  SetLength(FMessages, 0);
  // Delete file if exists
  if FileExists(GetHistoryFilePath) then
    DeleteFile(GetHistoryFilePath);
end;

function TContextMemory.MessageCount: Integer;
begin
  Result := Length(FMessages);
end;

procedure TContextMemory.LoadFromFile;
var
  FilePath: string;
  FileStream: TFileStream;
  JSONData: TJSONData;
  JSONArr: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
begin
  FilePath := GetHistoryFilePath;
  if not FileExists(FilePath) then
    Exit;

  FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    try
      JSONData := GetJSON(FileStream);
      try
        if JSONData is TJSONArray then
        begin
          JSONArr := TJSONArray(JSONData);
          SetLength(FMessages, JSONArr.Count);
          for I := 0 to JSONArr.Count - 1 do
          begin
            JSONObj := JSONArr.Objects[I];
            FMessages[I].Role := JSONObj.Get('role', '');
            FMessages[I].Content := JSONObj.Get('content', '');
          end;
        end;
      finally
        JSONData.Free;
      end;
    except
      // Silently ignore corrupt files
      SetLength(FMessages, 0);
    end;
  finally
    FileStream.Free;
  end;
end;

procedure TContextMemory.SaveToFile;
var
  FilePath, DirPath: string;
  JSONArr: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  FileContent: string;
  FileStream: TFileStream;
begin
  if FProjectPath = '' then
    Exit;

  FilePath := GetHistoryFilePath;
  DirPath := ExtractFileDir(FilePath);

  // Create .lazspec directory if it doesn't exist
  if not DirectoryExists(DirPath) then
    ForceDirectories(DirPath);

  JSONArr := TJSONArray.Create;
  try
    for I := 0 to Length(FMessages) - 1 do
    begin
      JSONObj := TJSONObject.Create;
      JSONObj.Add('role', FMessages[I].Role);
      JSONObj.Add('content', FMessages[I].Content);
      JSONArr.Add(JSONObj);
    end;

    FileContent := JSONArr.FormatJSON;
  finally
    JSONArr.Free;
  end;

  FileStream := TFileStream.Create(FilePath, fmCreate);
  try
    if FileContent <> '' then
      FileStream.WriteBuffer(FileContent[1], Length(FileContent));
  finally
    FileStream.Free;
  end;
end;

end.
