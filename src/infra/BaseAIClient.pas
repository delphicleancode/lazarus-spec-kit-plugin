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

unit BaseAIClient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { TAIMessage - Represents a single message in the conversation }
  TAIMessage = record
    Role: string;    // 'system', 'user', 'assistant'
    Content: string;
  end;
  TAIMessages = array of TAIMessage;

  { TAIResponse - Represents the AI response with metadata }
  TAIResponse = record
    Content: string;
    Model: string;
    PromptTokens: Integer;
    CompletionTokens: Integer;
    TotalTokens: Integer;
    FinishReason: string;
    Success: Boolean;
    ErrorMessage: string;
  end;

  { ISpecAIClient - Interface for AI provider clients }
  ISpecAIClient = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function ChatCompletion(const AMessages: TAIMessages;
      const AModel: string; AMaxTokens: Integer;
      ATemperature: Double): TAIResponse;
    function TestConnection: Boolean;
    function GetAvailableModels: TStringList;
    function GetProviderName: string;
    procedure AbortRequest;
  end;

{ Helper functions }
function CreateAIMessage(const ARole, AContent: string): TAIMessage;
function CreateErrorResponse(const AErrorMessage: string): TAIResponse;

implementation

function CreateAIMessage(const ARole, AContent: string): TAIMessage;
begin
  Result.Role := ARole;
  Result.Content := AContent;
end;

function CreateErrorResponse(const AErrorMessage: string): TAIResponse;
begin
  Result.Content := '';
  Result.Model := '';
  Result.PromptTokens := 0;
  Result.CompletionTokens := 0;
  Result.TotalTokens := 0;
  Result.FinishReason := 'error';
  Result.Success := False;
  Result.ErrorMessage := AErrorMessage;
end;

end.
