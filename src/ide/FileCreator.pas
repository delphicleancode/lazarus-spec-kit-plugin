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

unit FileCreator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LazIDEIntf, ProjectIntf;

type
  { TFileCreator - Creates new files and adds to project (Agent mode) }
  TFileCreator = class
  public
    class function CreateUnitFile(const AFilePath, ASource: string): Boolean;
    class function CreateAndAddToProject(const AFilePath, ASource: string): Boolean;
    class function OpenFileInEditor(const AFilePath: string): Boolean;
  end;

implementation

{ TFileCreator }

class function TFileCreator.CreateUnitFile(const AFilePath, ASource: string): Boolean;
var
  DirPath: string;
  SL: TStringList;
begin
  Result := False;
  if AFilePath = '' then Exit;
  try
    DirPath := ExtractFileDir(AFilePath);
    if (DirPath <> '') and not DirectoryExists(DirPath) then
      if not ForceDirectories(DirPath) then Exit;

    SL := TStringList.Create;
    try
      SL.Text := ASource;
      SL.SaveToFile(AFilePath);
    finally
      SL.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

class function TFileCreator.CreateAndAddToProject(const AFilePath, ASource: string): Boolean;
begin
  // File creation is the primary goal; opening in editor is best-effort
  Result := CreateUnitFile(AFilePath, ASource);
  if Result then
    OpenFileInEditor(AFilePath); // Ignore return value — file was created OK
end;

class function TFileCreator.OpenFileInEditor(const AFilePath: string): Boolean;
begin
  Result := False;
  if LazarusIDE = nil then Exit;
  if not FileExists(AFilePath) then Exit;

  try
    Result := LazarusIDE.DoOpenEditorFile(AFilePath, -1, -1,
      [ofAddToRecent]) = mrOK;
  except
    Result := False;
  end;
end;

end.
