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

unit OpenRouterClient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser,
  BaseAIClient;

type
  { TOpenRouterClient - HTTP client for OpenRouter API (OpenAI-compatible endpoint) }
  TOpenRouterClient = class(TInterfacedObject, ISpecAIClient)
  private
    FApiKey: string;
    FBaseURL: string;
    FTimeout: Integer;
    FHTTPClient: TFPHTTPClient;
    FAborted: Boolean;
    function BuildRequestJSON(const AMessages: TAIMessages;
      const AModel: string; AMaxTokens: Integer;
      ATemperature: Double): string;
    function ParseResponse(const AResponseBody: string): TAIResponse;
    function DoPost(const AEndpoint, ABody: string): string;
  public
    constructor Create(const AApiKey: string);
    constructor Create(const AApiKey, ABaseURL: string);
    destructor Destroy; override;
    { ISpecAIClient }
    function ChatCompletion(const AMessages: TAIMessages;
      const AModel: string; AMaxTokens: Integer;
      ATemperature: Double): TAIResponse;
    function TestConnection: Boolean;
    function GetAvailableModels: TStringList;
    function GetProviderName: string;
    procedure AbortRequest;
    { Properties }
    property ApiKey: string read FApiKey write FApiKey;
    property BaseURL: string read FBaseURL write FBaseURL;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

const
  OPENROUTER_DEFAULT_BASE_URL = 'https://openrouter.ai/api/v1';
  OPENROUTER_DEFAULT_MODEL = 'meta-llama/llama-3.3-70b-instruct';
  OPENROUTER_DEFAULT_TIMEOUT = 120000; // 120 seconds

implementation

{ TOpenRouterClient }

constructor TOpenRouterClient.Create(const AApiKey: string);
begin
  inherited Create;
  FApiKey := AApiKey;
  FBaseURL := OPENROUTER_DEFAULT_BASE_URL;
  FTimeout := OPENROUTER_DEFAULT_TIMEOUT;
  FAborted := False;
  FHTTPClient := TFPHTTPClient.Create(nil);
end;

constructor TOpenRouterClient.Create(const AApiKey, ABaseURL: string);
begin
  inherited Create;
  FApiKey := AApiKey;
  FBaseURL := ABaseURL;
  FTimeout := OPENROUTER_DEFAULT_TIMEOUT;
  FAborted := False;
  FHTTPClient := TFPHTTPClient.Create(nil);
end;

destructor TOpenRouterClient.Destroy;
begin
  FHTTPClient.Free;
  inherited Destroy;
end;

procedure TOpenRouterClient.AbortRequest;
begin
  FAborted := True;
  // TFPHTTPClient has no mid-request cancel API; the flag prevents the next request
end;

function TOpenRouterClient.BuildRequestJSON(const AMessages: TAIMessages;
  const AModel: string; AMaxTokens: Integer;
  ATemperature: Double): string;
var
  RequestObj: TJSONObject;
  MessagesArr: TJSONArray;
  MsgObj: TJSONObject;
  I: Integer;
begin
  RequestObj := TJSONObject.Create;
  try
    RequestObj.Add('model', AModel);
    RequestObj.Add('max_tokens', AMaxTokens);
    RequestObj.Add('temperature', ATemperature);

    MessagesArr := TJSONArray.Create;
    for I := 0 to Length(AMessages) - 1 do
    begin
      MsgObj := TJSONObject.Create;
      MsgObj.Add('role', AMessages[I].Role);
      MsgObj.Add('content', AMessages[I].Content);
      MessagesArr.Add(MsgObj);
    end;
    RequestObj.Add('messages', MessagesArr);

    Result := RequestObj.AsJSON;
  finally
    RequestObj.Free;
  end;
end;

function TOpenRouterClient.ParseResponse(const AResponseBody: string): TAIResponse;
var
  ResponseObj: TJSONObject;
  ChoicesArr: TJSONArray;
  ChoiceObj: TJSONObject;
  MessageObj: TJSONObject;
  UsageObj: TJSONObject;
  JSONData: TJSONData;
begin
  Result.Success := False;
  Result.ErrorMessage := '';
  Result.Content := '';
  Result.PromptTokens := 0;
  Result.CompletionTokens := 0;
  Result.TotalTokens := 0;
  Result.FinishReason := '';

  try
    JSONData := GetJSON(AResponseBody);
    try
      if not (JSONData is TJSONObject) then
      begin
        Result.ErrorMessage := 'Invalid response: expected JSON object';
        Exit;
      end;

      ResponseObj := TJSONObject(JSONData);

      // Check for error response
      if ResponseObj.IndexOfName('error') >= 0 then
      begin
        Result.ErrorMessage := ResponseObj.Objects['error'].Get('message', 'Unknown API error');
        Exit;
      end;

      // Parse model
      Result.Model := ResponseObj.Get('model', '');

      // Parse choices
      if ResponseObj.IndexOfName('choices') >= 0 then
      begin
        ChoicesArr := ResponseObj.Arrays['choices'];
        if ChoicesArr.Count > 0 then
        begin
          ChoiceObj := ChoicesArr.Objects[0];
          Result.FinishReason := ChoiceObj.Get('finish_reason', '');

          if ChoiceObj.IndexOfName('message') >= 0 then
          begin
            MessageObj := ChoiceObj.Objects['message'];
            Result.Content := MessageObj.Get('content', '');
          end;
        end;
      end;

      // Parse usage
      if ResponseObj.IndexOfName('usage') >= 0 then
      begin
        UsageObj := ResponseObj.Objects['usage'];
        Result.PromptTokens := UsageObj.Get('prompt_tokens', 0);
        Result.CompletionTokens := UsageObj.Get('completion_tokens', 0);
        Result.TotalTokens := UsageObj.Get('total_tokens', 0);
      end;

      Result.Success := True;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
      Result.ErrorMessage := 'Failed to parse response: ' + E.Message;
  end;
end;

function TOpenRouterClient.DoPost(const AEndpoint, ABody: string): string;
var
  ResponseStream: TStringStream;
  RequestStream: TStringStream;
begin
  Result := '';
  if FAborted then
    raise Exception.Create('Request aborted');

  ResponseStream := TStringStream.Create('');
  RequestStream := TStringStream.Create(ABody);
  try
    FHTTPClient.ConnectTimeout := FTimeout;
    FHTTPClient.IOTimeout := FTimeout;
    FHTTPClient.RequestHeaders.Clear;
    FHTTPClient.AddHeader('Authorization', 'Bearer ' + FApiKey);
    FHTTPClient.AddHeader('Content-Type', 'application/json');
    FHTTPClient.AddHeader('HTTP-Referer', 'https://github.com/delphicleancode/lazarus-spec-kit');
    FHTTPClient.AddHeader('X-Title', 'Lazarus Spec Kit');
    FHTTPClient.AllowRedirect := True;
    FHTTPClient.RequestBody := RequestStream;

    try
      FHTTPClient.Post(FBaseURL + AEndpoint, ResponseStream);
      Result := ResponseStream.DataString;
    except
      on E: EHTTPClient do
      begin
        if ResponseStream.DataString <> '' then
          Result := ResponseStream.DataString
        else
          raise;
      end;
    end;
  finally
    RequestStream.Free;
    ResponseStream.Free;
    FHTTPClient.RequestBody := nil;
  end;
end;

function TOpenRouterClient.ChatCompletion(const AMessages: TAIMessages;
  const AModel: string; AMaxTokens: Integer;
  ATemperature: Double): TAIResponse;
var
  RequestBody: string;
  ResponseBody: string;
  Model: string;
begin
  if FApiKey = '' then
  begin
    Result := CreateErrorResponse('API key is not configured. Go to Settings to set your OpenRouter API key.');
    Exit;
  end;

  FAborted := False;
  Model := AModel;
  if Model = '' then
    Model := OPENROUTER_DEFAULT_MODEL;

  try
    RequestBody := BuildRequestJSON(AMessages, Model, AMaxTokens, ATemperature);
    ResponseBody := DoPost('/chat/completions', RequestBody);
    Result := ParseResponse(ResponseBody);
  except
    on E: Exception do
      Result := CreateErrorResponse('HTTP request failed: ' + E.Message);
  end;
end;

function TOpenRouterClient.TestConnection: Boolean;
var
  Messages: TAIMessages;
  Response: TAIResponse;
begin
  FAborted := False;
  SetLength(Messages, 1);
  Messages[0] := CreateAIMessage('user', 'Hi');
  Response := ChatCompletion(Messages, OPENROUTER_DEFAULT_MODEL, 10, 0.0);
  Result := Response.Success;
end;

function TOpenRouterClient.GetAvailableModels: TStringList;
var
  ResponseBody: string;
  JSONData: TJSONData;
  ResponseObj: TJSONObject;
  DataArr: TJSONArray;
  I: Integer;
begin
  Result := TStringList.Create;
  try
    // OpenRouter supports listing models via GET /models
    // Using TFPHTTPClient.Get for this endpoint
    FHTTPClient.RequestHeaders.Clear;
    FHTTPClient.AddHeader('Authorization', 'Bearer ' + FApiKey);
    FHTTPClient.AddHeader('Content-Type', 'application/json');
    ResponseBody := FHTTPClient.Get(FBaseURL + '/models');
  except
    on E: Exception do
    begin
      // Return default models on failure
      Result.Add('meta-llama/llama-3.3-70b-instruct');
      Result.Add('anthropic/claude-3.5-sonnet');
      Result.Add('google/gemini-2.0-flash-exp:free');
      Result.Add('mistralai/mistral-large');
      Exit;
    end;
  end;

  try
    JSONData := GetJSON(ResponseBody);
    try
      if JSONData is TJSONObject then
      begin
        ResponseObj := TJSONObject(JSONData);
        if ResponseObj.IndexOfName('data') >= 0 then
        begin
          DataArr := ResponseObj.Arrays['data'];
          for I := 0 to DataArr.Count - 1 do
            Result.Add(DataArr.Objects[I].Get('id', ''));
        end;
      end;
    finally
      JSONData.Free;
    end;
  except
    // Return defaults on parse failure
    Result.Add('meta-llama/llama-3.3-70b-instruct');
    Result.Add('anthropic/claude-3.5-sonnet');
    Result.Add('google/gemini-2.0-flash-exp:free');
    Result.Add('mistralai/mistral-large');
  end;
end;

function TOpenRouterClient.GetProviderName: string;
begin
  Result := 'OpenRouter';
end;

end.
