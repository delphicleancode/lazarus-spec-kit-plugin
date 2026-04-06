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

unit SDDEngine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseAIClient, PromptBuilder, ContextMemory, SkillsLoader,
  SpecSettings;

type
  { TSDDEngine - Main engine orchestrating Ask/Plan/Agent modes }
  TSDDEngine = class
  private
    FAIClient: ISpecAIClient;
    FPromptBuilder: TPromptBuilder;
    FContextMemory: TContextMemory;
    FSkillsLoader: TSkillsLoader;
    FLastResponse: TAIResponse;
    procedure EnsureComponents;
  public
    constructor Create;
    destructor Destroy; override;

    function ProcessRequest(AMode: TSpecMode;
      const AUserInput: string;
      ASelectedSkills: TStrings;
      const AProjectName: string;
      const AActiveFile: string;
      const ASelectedText: string): string;

    procedure ClearContext;
    procedure SetProjectPath(const APath: string);
    procedure RefreshSkills;

    function ExtractCodeBlocks(const AResponse: string): TStringList;

    property AIClient: ISpecAIClient read FAIClient write FAIClient;
    property LastResponse: TAIResponse read FLastResponse;
    property PromptBuilder: TPromptBuilder read FPromptBuilder;
    property ContextMemory: TContextMemory read FContextMemory;
    property SkillsLoader: TSkillsLoader read FSkillsLoader;
  end;

implementation

uses
  GroqClient, QwenClient, OpenRouterClient;

{ TSDDEngine }

constructor TSDDEngine.Create;
begin
  inherited Create;
  FPromptBuilder := TPromptBuilder.Create;
  FContextMemory := TContextMemory.Create('');
  FSkillsLoader := TSkillsLoader.Create('');
end;

destructor TSDDEngine.Destroy;
begin
  FSkillsLoader.Free;
  FContextMemory.Free;
  FPromptBuilder.Free;
  FAIClient := nil; // Release interface
  inherited Destroy;
end;

procedure TSDDEngine.EnsureComponents;
var
  Settings: TSpecSettings;
begin
  Settings := TSpecSettings.Instance;

  // (Re)create AI client when nil or provider settings changed
  if FAIClient = nil then
  begin
    if Settings.Provider = 'groq' then
      FAIClient := TGroqClient.Create(Settings.ApiKey)
    else if Settings.Provider = 'qwen' then
      FAIClient := TQwenClient.Create(Settings.ApiKey, Settings.QwenURL)
    else if Settings.Provider = 'openrouter' then
      FAIClient := TOpenRouterClient.Create(Settings.ApiKey, Settings.OpenRouterURL)
    else
    begin
      // Ollama not yet implemented — fall back to Groq and notify via error
      // so the caller sees a clear message instead of silently using Groq
      FAIClient := TGroqClient.Create(Settings.ApiKey);
    end;
  end;

  // Update skills loader path whenever it diverges from saved settings
  if Settings.SpecKitPath <> FSkillsLoader.SpecKitPath then
  begin
    FSkillsLoader.SpecKitPath := Settings.SpecKitPath;
    if Settings.SpecKitPath <> '' then
      FSkillsLoader.ScanSkills;
  end;
end;

function TSDDEngine.ProcessRequest(AMode: TSpecMode;
  const AUserInput: string;
  ASelectedSkills: TStrings;
  const AProjectName: string;
  const AActiveFile: string;
  const ASelectedText: string): string;
var
  Messages: TAIMessages;
  SkillContents: TStringList;
  History: TAIMessages;
  Settings: TSpecSettings;
begin
  Result := '';
  EnsureComponents;
  Settings := TSpecSettings.Instance;

  // Load skill contents for selected skills
  SkillContents := FSkillsLoader.GetSkillContents(ASelectedSkills);
  try
    // Get conversation history
    History := FContextMemory.GetHistory;

    // Build the messages array
    Messages := FPromptBuilder.BuildMessages(
      AMode,
      AUserInput,
      SkillContents,
      History,
      AProjectName,
      AActiveFile,
      ASelectedText
    );

    // Call AI
    FLastResponse := FAIClient.ChatCompletion(
      Messages,
      Settings.Model,
      Settings.MaxTokens,
      Settings.Temperature
    );

    if FLastResponse.Success then
    begin
      Result := FLastResponse.Content;
      // Prepend Ollama notice if applicable
      if Settings.Provider = 'ollama' then
        Result := '**Notice:** Ollama support is not yet implemented. Request sent via Groq.' +
                  sLineBreak + sLineBreak + Result;
      // Save to context memory (only when project path is known)
      FContextMemory.AddUserMessage(AUserInput);
      FContextMemory.AddAssistantMessage(FLastResponse.Content);
      if FContextMemory.ProjectPath <> '' then
        FContextMemory.SaveToFile;
    end
    else
    begin
      Result := '**Error:** ' + FLastResponse.ErrorMessage;
    end;
  finally
    SkillContents.Free;
  end;
end;

procedure TSDDEngine.ClearContext;
begin
  FContextMemory.ClearHistory;
end;

procedure TSDDEngine.SetProjectPath(const APath: string);
begin
  FContextMemory.ProjectPath := APath;
  FContextMemory.LoadFromFile;
end;

procedure TSDDEngine.RefreshSkills;
begin
  FSkillsLoader.ScanSkills;
end;

function TSDDEngine.ExtractCodeBlocks(const AResponse: string): TStringList;
var
  Lines: TStringList;
  I: Integer;
  InBlock: Boolean;
  CurrentBlock: string;
  CurrentFileName: string;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    Lines.Text := AResponse;
    InBlock := False;
    CurrentBlock := '';
    CurrentFileName := '';

    for I := 0 to Lines.Count - 1 do
    begin
      if not InBlock then
      begin
        // Look for opening fence
        if (Pos('```pascal', LowerCase(Trim(Lines[I]))) = 1) or
           (Pos('```pas', LowerCase(Trim(Lines[I]))) = 1) then
        begin
          InBlock := True;
          CurrentBlock := '';
          CurrentFileName := '';
        end;
      end
      else
      begin
        // Check for closing fence
        if Trim(Lines[I]) = '```' then
        begin
          InBlock := False;
          if CurrentFileName = '' then
            CurrentFileName := 'untitled_' + IntToStr(Result.Count + 1) + '.pas';
          Result.Values[CurrentFileName] := CurrentBlock;
        end
        else
        begin
          // Check for filename comment on first line
          if (CurrentBlock = '') and (Pos('// filename:', LowerCase(Lines[I])) = 1) then
            CurrentFileName := Trim(Copy(Lines[I], 14, MaxInt))
          else
            CurrentBlock := CurrentBlock + Lines[I] + sLineBreak;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

end.
