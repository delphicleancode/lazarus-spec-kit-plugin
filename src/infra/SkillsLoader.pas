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

unit SkillsLoader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazFileUtils;

type
  { TSkillInfo - Metadata about a single skill }
  TSkillInfo = record
    ID: string;
    Name: string;
    Category: string;
    FilePath: string;
  end;
  TSkillInfoArray = array of TSkillInfo;

  { TSkillsLoader - Scans and loads skills from the lazarus-spec-kit repo }
  TSkillsLoader = class
  private
    FSpecKitPath: string;
    FSkills: TSkillInfoArray;
    procedure ScanGeminiSkills;
    procedure ScanCursorRules;
    function ExtractSkillName(const APath: string): string;
    function ExtractCategory(const AContent: string): string;
  public
    constructor Create(const ASpecKitPath: string);
    procedure ScanSkills;
    function GetSkillContent(const ASkillID: string): string;
    function GetSkillContents(const ASkillIDs: TStrings): TStringList;
    function GetSkillList: TSkillInfoArray;
    function SkillCount: Integer;
    property SpecKitPath: string read FSpecKitPath write FSpecKitPath;
  end;

implementation

{ TSkillsLoader }

constructor TSkillsLoader.Create(const ASpecKitPath: string);
begin
  inherited Create;
  FSpecKitPath := ASpecKitPath;
  SetLength(FSkills, 0);
end;

function TSkillsLoader.ExtractSkillName(const APath: string): string;
var
  DirName: string;
begin
  // Extract skill name from directory path
  // e.g., '.gemini/skills/clean-code/SKILL.md' -> 'Clean Code'
  DirName := ExtractFileName(ExtractFileDir(APath));
  if DirName = '' then
    DirName := ChangeFileExt(ExtractFileName(APath), '');

  // Convert slug to title case
  Result := StringReplace(DirName, '-', ' ', [rfReplaceAll]);
  if Length(Result) > 0 then
    Result[1] := UpCase(Result[1]);
end;

function TSkillsLoader.ExtractCategory(const AContent: string): string;
begin
  // Simple categorization based on content keywords
  if (Pos('database', LowerCase(AContent)) > 0) or
     (Pos('sql', LowerCase(AContent)) > 0) or
     (Pos('firebird', LowerCase(AContent)) > 0) or
     (Pos('postgresql', LowerCase(AContent)) > 0) or
     (Pos('mysql', LowerCase(AContent)) > 0) then
    Result := 'Database'
  else if (Pos('test', LowerCase(AContent)) > 0) or
          (Pos('fpcunit', LowerCase(AContent)) > 0) or
          (Pos('tdd', LowerCase(AContent)) > 0) then
    Result := 'Testing'
  else if (Pos('thread', LowerCase(AContent)) > 0) then
    Result := 'Concurrency'
  else if (Pos('horse', LowerCase(AContent)) > 0) or
          (Pos('intraweb', LowerCase(AContent)) > 0) or
          (Pos('acbr', LowerCase(AContent)) > 0) then
    Result := 'Framework'
  else if (Pos('refactor', LowerCase(AContent)) > 0) or
          (Pos('review', LowerCase(AContent)) > 0) then
    Result := 'Quality'
  else if (Pos('memory', LowerCase(AContent)) > 0) or
          (Pos('exception', LowerCase(AContent)) > 0) then
    Result := 'Safety'
  else
    Result := 'Architecture';
end;

procedure TSkillsLoader.ScanGeminiSkills;
var
  SearchPath: string;
  SkillDirs: TStringList;
  SkillFile: string;
  I, Len: Integer;
begin
  SearchPath := IncludeTrailingPathDelimiter(FSpecKitPath) +
                '.gemini' + PathDelim + 'skills';
  if not DirectoryExists(SearchPath) then
    Exit;

  SkillDirs := FindAllDirectories(SearchPath, False);
  try
    for I := 0 to SkillDirs.Count - 1 do
    begin
      SkillFile := IncludeTrailingPathDelimiter(SkillDirs[I]) + 'SKILL.md';
      if FileExists(SkillFile) then
      begin
        Len := Length(FSkills);
        SetLength(FSkills, Len + 1);
        FSkills[Len].ID := 'gemini:' + ExtractFileName(SkillDirs[I]);
        FSkills[Len].Name := ExtractSkillName(SkillFile);
        FSkills[Len].FilePath := SkillFile;
        // Category will be set after content is available
        FSkills[Len].Category := ExtractCategory(
          ExtractFileName(SkillDirs[I]));
      end;
    end;
  finally
    SkillDirs.Free;
  end;
end;

procedure TSkillsLoader.ScanCursorRules;
var
  SearchPath: string;
  RuleFiles: TStringList;
  I, Len: Integer;
  FileName: string;
begin
  SearchPath := IncludeTrailingPathDelimiter(FSpecKitPath) +
                '.cursor' + PathDelim + 'rules';
  if not DirectoryExists(SearchPath) then
    Exit;

  RuleFiles := FindAllFiles(SearchPath, '*.md', False);
  try
    for I := 0 to RuleFiles.Count - 1 do
    begin
      FileName := ChangeFileExt(ExtractFileName(RuleFiles[I]), '');
      Len := Length(FSkills);
      SetLength(FSkills, Len + 1);
      FSkills[Len].ID := 'cursor:' + FileName;
      FSkills[Len].Name := ExtractSkillName(RuleFiles[I]);
      FSkills[Len].FilePath := RuleFiles[I];
      FSkills[Len].Category := ExtractCategory(FileName);
    end;
  finally
    RuleFiles.Free;
  end;
end;

procedure TSkillsLoader.ScanSkills;
begin
  SetLength(FSkills, 0);
  if (FSpecKitPath = '') or not DirectoryExists(FSpecKitPath) then
    Exit;

  ScanGeminiSkills;
  ScanCursorRules;
end;

function TSkillsLoader.GetSkillContent(const ASkillID: string): string;
var
  I: Integer;
  SL: TStringList;
begin
  Result := '';
  for I := 0 to Length(FSkills) - 1 do
  begin
    if FSkills[I].ID = ASkillID then
    begin
      if FileExists(FSkills[I].FilePath) then
      begin
        SL := TStringList.Create;
        try
          SL.LoadFromFile(FSkills[I].FilePath);
          Result := SL.Text;
        finally
          SL.Free;
        end;
      end;
      Exit;
    end;
  end;
end;

function TSkillsLoader.GetSkillContents(const ASkillIDs: TStrings): TStringList;
var
  I: Integer;
  Content: string;
begin
  Result := TStringList.Create;
  if ASkillIDs = nil then
    Exit;

  for I := 0 to ASkillIDs.Count - 1 do
  begin
    Content := GetSkillContent(ASkillIDs[I]);
    if Content <> '' then
      Result.Values[ASkillIDs[I]] := Content;
  end;
end;

function TSkillsLoader.GetSkillList: TSkillInfoArray;
begin
  Result := Copy(FSkills, 0, Length(FSkills));
end;

function TSkillsLoader.SkillCount: Integer;
begin
  Result := Length(FSkills);
end;

end.
