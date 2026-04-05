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

unit ProjectHelper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazIDEIntf, ProjectIntf;

type
  { TProjectHelper - Helper for project context }
  TProjectHelper = class
  public
    class function GetProjectName: string;
    class function GetProjectPath: string;
    class function GetProjectUnits: TStringList;
    class function HasActiveProject: Boolean;
  end;

implementation

{ TProjectHelper }

class function TProjectHelper.HasActiveProject: Boolean;
begin
  Result := (LazarusIDE <> nil) and (LazarusIDE.ActiveProject <> nil);
end;

class function TProjectHelper.GetProjectName: string;
begin
  Result := '';
  if not HasActiveProject then Exit;
  Result := ExtractFileName(LazarusIDE.ActiveProject.ProjectInfoFile);
  Result := ChangeFileExt(Result, '');
end;

class function TProjectHelper.GetProjectPath: string;
begin
  Result := '';
  if not HasActiveProject then Exit;
  Result := ExtractFilePath(LazarusIDE.ActiveProject.ProjectInfoFile);
end;

class function TProjectHelper.GetProjectUnits: TStringList;
var
  I: Integer;
  Project: TLazProject;
begin
  Result := TStringList.Create;
  if not HasActiveProject then Exit;

  Project := LazarusIDE.ActiveProject;
  for I := 0 to Project.FileCount - 1 do
  begin
    if Project.Files[I].IsPartOfProject then
      Result.Add(Project.Files[I].Filename);
  end;
end;

end.
