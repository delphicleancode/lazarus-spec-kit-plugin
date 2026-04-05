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

unit PromptBuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseAIClient;

type
  TSpecMode = (smAsk, smPlan, smAgent);

  { TPromptBuilder - Assembles prompt messages for the AI }
  TPromptBuilder = class
  private
    function GetSystemPrompt(AMode: TSpecMode): string;
    function BuildSkillsContext(const ASkillContents: TStrings): string;
    function BuildProjectContext(const AProjectName, AActiveFile, ASelectedText: string): string;
  public
    function BuildMessages(AMode: TSpecMode;
      const AUserInput: string;
      ASkillContents: TStrings;
      const AHistory: TAIMessages;
      const AProjectName: string;
      const AActiveFile: string;
      const ASelectedText: string): TAIMessages;
  end;

implementation

const
  SYSTEM_PROMPT_ASK =
    'You are an expert in Free Pascal and Lazarus IDE development. ' +
    'Answer clearly and directly. ' +
    'When providing code examples, use proper Object Pascal syntax with ' +
    '{$mode objfpc}{$H+} directive. ' +
    'Follow Free Pascal naming conventions: T prefix for types, I for interfaces, ' +
    'F for private fields, A for parameters, L for local variables, E for exceptions.';

  SYSTEM_PROMPT_PLAN =
    'You are a Spec-Driven Development (SDD) specialist for Free Pascal/Lazarus. ' +
    'Generate a complete SDD specification based on the user''s request. ' +
    'Use the provided skills as development guidelines. ' + sLineBreak +
    'Your SDD output must include:' + sLineBreak +
    '1. **Specification** — Clear description of what will be built' + sLineBreak +
    '2. **Technical Plan** — Architecture, patterns, and design decisions' + sLineBreak +
    '3. **Unit Structure** — List of .pas units with their responsibilities' + sLineBreak +
    '4. **Interface Definitions** — Key types, interfaces, and classes' + sLineBreak +
    '5. **Test Plan** — FPCUnit test cases to validate the implementation' + sLineBreak +
    'Follow Free Pascal/Lazarus conventions throughout.';

  SYSTEM_PROMPT_AGENT =
    'You are an iterative development agent for Free Pascal/Lazarus. ' +
    'Generate compilable Free Pascal code. ' +
    'When providing code, wrap each file in a fenced code block with ' +
    'the target filename as a comment on the first line. Example:' + sLineBreak +
    '```pascal' + sLineBreak +
    '// filename: MyUnit.pas' + sLineBreak +
    'unit MyUnit;' + sLineBreak +
    '...' + sLineBreak +
    '```' + sLineBreak +
    'When requested, apply refactorings based on active skills. ' +
    'Always use {$mode objfpc}{$H+} directive. ' +
    'Follow memory safety patterns: every .Create without Owner requires try..finally..Free. ' +
    'Use interfaces for dependency injection.';

{ TPromptBuilder }

function TPromptBuilder.GetSystemPrompt(AMode: TSpecMode): string;
begin
  case AMode of
    smAsk:   Result := SYSTEM_PROMPT_ASK;
    smPlan:  Result := SYSTEM_PROMPT_PLAN;
    smAgent: Result := SYSTEM_PROMPT_AGENT;
  end;
end;

function TPromptBuilder.BuildSkillsContext(const ASkillContents: TStrings): string;
var
  I: Integer;
  SB: TStringList;
begin
  Result := '';
  if (ASkillContents = nil) or (ASkillContents.Count = 0) then
    Exit;

  SB := TStringList.Create;
  try
    SB.Add('');
    SB.Add('--- ACTIVE DEVELOPMENT SKILLS ---');
    SB.Add('Apply the following development guidelines when generating code:');
    SB.Add('');
    for I := 0 to ASkillContents.Count - 1 do
    begin
      SB.Add('### Skill: ' + ASkillContents.Names[I]);
      SB.Add(ASkillContents.ValueFromIndex[I]);
      SB.Add('');
    end;
    SB.Add('--- END OF SKILLS ---');
    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

function TPromptBuilder.BuildProjectContext(const AProjectName, AActiveFile, ASelectedText: string): string;
var
  SB: TStringList;
begin
  Result := '';
  if (AProjectName = '') and (AActiveFile = '') and (ASelectedText = '') then
    Exit;

  SB := TStringList.Create;
  try
    SB.Add('');
    SB.Add('--- PROJECT CONTEXT ---');
    if AProjectName <> '' then
      SB.Add('Project: ' + AProjectName);
    if AActiveFile <> '' then
      SB.Add('Active file: ' + AActiveFile);
    if ASelectedText <> '' then
    begin
      SB.Add('Selected code:');
      SB.Add('```pascal');
      SB.Add(ASelectedText);
      SB.Add('```');
    end;
    SB.Add('--- END CONTEXT ---');
    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

function TPromptBuilder.BuildMessages(AMode: TSpecMode;
  const AUserInput: string;
  ASkillContents: TStrings;
  const AHistory: TAIMessages;
  const AProjectName: string;
  const AActiveFile: string;
  const ASelectedText: string): TAIMessages;
var
  SystemContent: string;
  TotalMessages: Integer;
  I, Idx: Integer;
begin
  // Build system prompt = base prompt + skills + project context
  SystemContent := GetSystemPrompt(AMode);
  SystemContent := SystemContent + BuildSkillsContext(ASkillContents);
  SystemContent := SystemContent + BuildProjectContext(AProjectName,
    AActiveFile, ASelectedText);

  // Calculate total: 1 system + history + 1 user
  TotalMessages := 1 + Length(AHistory) + 1;
  Result := nil;
  SetLength(Result, TotalMessages);

  // System message
  Idx := 0;
  Result[Idx] := CreateAIMessage('system', SystemContent);
  Inc(Idx);

  // History messages
  for I := 0 to Length(AHistory) - 1 do
  begin
    Result[Idx] := AHistory[I];
    Inc(Idx);
  end;

  // User message
  Result[Idx] := CreateAIMessage('user', AUserInput);
end;

end.
