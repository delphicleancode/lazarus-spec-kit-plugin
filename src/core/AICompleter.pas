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

unit AICompleter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseAIClient;

type
  TAICompletionItem = record
    InsertText: string;
  end;
  TAICompletionItems = array of TAICompletionItem;

  { TAICompleter - Builds prompts and parses responses for AI code completion }
  TAICompleter = class
  private
    const
      MAX_CONTEXT_LINES = 200;
      CURSOR_MARKER = #171'|CURSOR|'#187; // «|CURSOR|»
  public
    function BuildCompletionMessages(const ASourceCode: string; ACursorLine, ACursorCol: Integer; const AFileName: string): TAIMessages;
    function ParseCompletionResponse(const AResponse: string): TAICompletionItems;
  end;

implementation

const
  COMPLETION_SYSTEM_PROMPT =
    'You are a Free Pascal/Lazarus intelligent code completion engine.' + sLineBreak +
    'You will receive source code with the cursor position marked as '#171'|CURSOR|'#187'.' + sLineBreak +
    'Provide exactly ONE complete code suggestion for the cursor position.' + sLineBreak +
    sLineBreak +
    'Rules:' + sLineBreak +
    '- Return ONLY the code that should be INSERTED at the cursor position' + sLineBreak +
    '- Do NOT repeat code that already exists BEFORE the cursor marker' + sLineBreak +
    '- Do NOT repeat code that already exists AFTER the cursor marker' + sLineBreak +
    '- The suggestion must be valid Free Pascal code' + sLineBreak +
    '- Return ONLY the code, no explanations, no comments, no markdown' + sLineBreak +
    '- Do NOT wrap the code in ``` blocks' + sLineBreak +
    '- The suggestion should be the best and most complete implementation' + sLineBreak +
    '- Include the full algorithm/logic block that fits the cursor context' + sLineBreak +
    '- Respect current indentation and Pascal conventions' + sLineBreak +
    '- Consider the unit structure, existing types, variables, and methods' + sLineBreak +
    '- Use {$mode objfpc}{$H+}, T prefix for types, F for fields, A for parameters';

{ TAICompleter }

function TAICompleter.BuildCompletionMessages(const ASourceCode: string; ACursorLine, ACursorCol: Integer; const AFileName: string): TAIMessages;
var
  Lines: TStringList;
  CodeWithCursor: string;
  LineText: string;
  I, StartLine, EndLine: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := ASourceCode;

    // Insert cursor marker at the caret position
    if (ACursorLine >= 0) and (ACursorLine < Lines.Count) then
    begin
      LineText := Lines[ACursorLine];
      if ACursorCol <= Length(LineText) then
        Lines[ACursorLine] := Copy(LineText, 1, ACursorCol - 1) +
          CURSOR_MARKER + Copy(LineText, ACursorCol, MaxInt)
      else
        Lines[ACursorLine] := LineText + CURSOR_MARKER;
    end;

    // Calculate context window (lines around cursor)
    StartLine := ACursorLine - (MAX_CONTEXT_LINES div 2);
    if StartLine < 0 then StartLine := 0;
    EndLine := StartLine + MAX_CONTEXT_LINES - 1;
    if EndLine >= Lines.Count then EndLine := Lines.Count - 1;

    // Build code context
    CodeWithCursor := '';
    for I := StartLine to EndLine do
    begin
      if I > StartLine then
        CodeWithCursor := CodeWithCursor + sLineBreak;
      CodeWithCursor := CodeWithCursor + Lines[I];
    end;
  finally
    Lines.Free;
  end;

  // Build messages
  SetLength(Result, 2);
  Result[0] := CreateAIMessage('system', COMPLETION_SYSTEM_PROMPT);
  Result[1] := CreateAIMessage('user',
    'File: ' + ExtractFileName(AFileName) + sLineBreak +
    'Return ONLY the new code to INSERT at the '#171'|CURSOR|'#187' position. ' +
    'Do NOT repeat any code that is already present before or after the cursor.' + sLineBreak +
    '```pascal' + sLineBreak +
    CodeWithCursor + sLineBreak +
    '```');
end;

function TAICompleter.ParseCompletionResponse(const AResponse: string): TAICompletionItems;
var
  Code: string;
begin
  Result := nil;
  Code := Trim(AResponse);
  if Code = '' then Exit;

  // Strip markdown fences if accidentally returned
  if (Pos('```', Code) = 1) then
  begin
    Delete(Code, 1, Pos(#10, Code)); // remove first line (```pascal)
    if Pos('```', Code) > 0 then
      Code := Copy(Code, 1, Pos('```', Code) - 1);
    Code := Trim(Code);
  end;

  if Code = '' then Exit;

  SetLength(Result, 1);
  Result[0].InsertText := Code;
end;

end.
