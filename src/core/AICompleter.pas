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
    DisplayText: string;
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
    'Suggest up to 5 distinct code completions for the cursor position.' + sLineBreak +
    sLineBreak +
    'Rules:' + sLineBreak +
    '- Each suggestion must be valid Free Pascal code' + sLineBreak +
    '- Return one suggestion per line, prefixed with ">>> "' + sLineBreak +
    '- For multi-line suggestions, use literal \n for newlines within the suggestion' + sLineBreak +
    '- Do NOT include explanations, comments about suggestions, or markdown' + sLineBreak +
    '- Suggestions should be natural continuations of the code at cursor' + sLineBreak +
    '- Vary from short (single expression/statement) to longer (full blocks)' + sLineBreak +
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
    '```pascal' + sLineBreak +
    CodeWithCursor + sLineBreak +
    '```');
end;

function TAICompleter.ParseCompletionResponse(const AResponse: string): TAICompletionItems; 
var 
  Lines: TStringList; 
  I, Count: Integer;  
  Line, DisplayText, InsertText: string;
begin
  Result := nil;
  Count := 0;

  Lines := TStringList.Create;
  try
    Lines.Text := AResponse;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if Pos('>>> ', Line) = 1 then
      begin
        InsertText := Copy(Line, 5, MaxInt);
        if InsertText = '' then Continue;

        // Build display text: replace \n with visual marker, truncate
        DisplayText := StringReplace(InsertText, '\n', ' '#8629' ', [rfReplaceAll]);
        if Length(DisplayText) > 80 then
          DisplayText := Copy(DisplayText, 1, 77) + '...';

        Inc(Count);
        SetLength(Result, Count);
        Result[Count - 1].DisplayText := DisplayText;
        Result[Count - 1].InsertText := InsertText;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

end.
