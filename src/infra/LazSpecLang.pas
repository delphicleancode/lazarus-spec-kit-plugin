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

unit LazSpecLang;

{$mode objfpc}{$H+}

{ LazSpecLang — Multilanguage support (EN / PT-BR) for the LazarusSpecKit plugin.

  All user-visible strings live here.  To add a new language: extend TR() with
  another branch and add the corresponding entry to the language combobox in
  dlgSpecSettings.

  Usage:  uses LazSpecLang;
          Caption := TR('Settings.Title');
}

interface

{ Returns True when the current plugin language is Portuguese (pt-BR). }
function IsPTBR: Boolean;

{ Returns the translated string for AKey according to the current language
  stored in TSpecSettings.  Falls back to the key itself if unknown. }
function TR(const AKey: string): string;

implementation

uses
  SysUtils, SpecSettings;

{ --------------------------------------------------------------------------- }

function IsPTBR: Boolean;
begin
  Result := TSpecSettings.Instance.Language = 'pt-BR';
end;

{ --------------------------------------------------------------------------- }

function TR(const AKey: string): string;
var
  P: Boolean;
begin
  P := IsPTBR;
  case AKey of

    // -----------------------------------------------------------------------
    // Spec Wizard main form — static button / label captions
    // -----------------------------------------------------------------------
    'Form.SpecWizard':
      Result := 'Spec Wizard';
    'Btn.Ask':
      if P then Result := 'Perguntar'   else Result := 'Ask';
    'Btn.Plan':
      if P then Result := 'Planejar'    else Result := 'Plan';
    'Btn.Agent':
      if P then Result := 'Agente'      else Result := 'Agent';
    'Btn.Settings':
      if P then Result := 'Configurações' else Result := 'Settings';
    'Btn.Export':
      if P then Result := 'Exportar'    else Result := 'Export';
    'Lbl.Skills':
      Result := 'Skills';
    'Btn.Send':
      if P then Result := 'Enviar'      else Result := 'Send';
    'Btn.Cancel':
      if P then Result := 'Cancelar'    else Result := 'Cancel';
    'Btn.Copy':
      if P then Result := 'Copiar'      else Result := 'Copy';
    'Btn.Apply':
      if P then Result := 'Aplicar'     else Result := 'Apply';

    // IDE context menu (editor right-click)
    'Menu.AIAssistant':
      if P then Result := 'Assistente IA' else Result := 'AI Assistant';
    'Menu.Refactor':
      if P then Result := 'Refatorar' else Result := 'Refactor';
    'Menu.Explain':
      if P then Result := 'Explicar' else Result := 'Explain';
    'Menu.Complete':
      if P then Result := 'Completar' else Result := 'Complete';
    'Menu.Fix':
      if P then Result := 'Corrigir' else Result := 'Fix';
    'Menu.Review':
      if P then Result := 'Revisão de Código' else Result := 'Code Review';

    // -----------------------------------------------------------------------
    // Mode names (used in status bar and buttons)
    // -----------------------------------------------------------------------
    'Mode.Ask':
      if P then Result := 'Perguntar' else Result := 'Ask';
    'Mode.Plan':
      if P then Result := 'Planejar'  else Result := 'Plan';
    'Mode.Agent':
      if P then Result := 'Agente'    else Result := 'Agent';

    // -----------------------------------------------------------------------
    // Spec Wizard status bar messages
    // -----------------------------------------------------------------------
    'Status.Initializing':
      if P then Result := 'Inicializando...' else Result := 'Initializing...';
    'Status.NoProject':
      if P then Result := 'Sem projeto aberto | Modo: Perguntar | Pronto'
           else Result := 'No project open | Mode: Ask | Ready';
    'Status.ProjectFmt':
      if P then Result := 'Projeto: %s | Modo: %s | Pronto'
           else Result := 'Project: %s | Mode: %s | Ready';
    'Status.ModeFmt':
      if P then Result := 'Modo: %s' else Result := 'Mode: %s';
    'Status.Processing':
      if P then Result := 'Processando... (clique em Cancelar para interromper)'
           else Result := 'Processing... (click Cancel to abort)';
    'Status.Cancelling':
      if P then Result := 'Cancelando...' else Result := 'Cancelling...';
    'Status.InitError':
      if P then Result := 'Erro de inicialização: ' else Result := 'Init error: ';
    'Status.Error':
      if P then Result := 'Erro: ' else Result := 'Error: ';
    'Status.TokensFmt':
      Result := 'Tokens: %d + %d = %d | %s';
    'Status.Cleared':
      if P then Result := 'Conversa limpa' else Result := 'Conversation cleared';
    'Status.Copied':
      if P then Result := 'Copiado para a área de transferência'
           else Result := 'Copied to clipboard';
    'Status.NothingToExport':
      if P then Result := 'Nada para exportar' else Result := 'Nothing to export';
    'Status.ExportedTo':
      if P then Result := 'Exportado para ' else Result := 'Exported to ';
    'Status.Created':
      if P then Result := 'Criado: ' else Result := 'Created: ';
    'Status.Inserted':
      if P then Result := 'Resposta inserida no editor ativo'
           else Result := 'Response inserted into active editor';

    // -----------------------------------------------------------------------
    // Dialog titles / texts used in frmSpecWizard
    // -----------------------------------------------------------------------
    'Dlg.Clear.Title':
      if P then Result := 'Limpar Conversa' else Result := 'Clear Conversation';
    'Dlg.Clear.Text':
      if P then Result := 'Limpar o histórico da conversa e a saída?'
           else Result := 'Clear conversation history and output?';
    'Dlg.Export.Title':
      if P then Result := 'Exportar Resposta' else Result := 'Export Response';
    'Dlg.Export.Filter':
      if P then
        Result := 'Markdown (*.md)|*.md|Código Pascal (*.pas)|*.pas|Texto (*.txt)|*.txt|Todos os arquivos (*.*)|*.*'
      else
        Result := 'Markdown (*.md)|*.md|Pascal source (*.pas)|*.pas|Text (*.txt)|*.txt|All files (*.*)|*.*';
    'Dlg.NoEditor.Title':
      if P then Result := 'Sem Editor Ativo' else Result := 'No Active Editor';
    'Dlg.NoEditor.Text':
      if P then Result := 'Abra um arquivo fonte no editor primeiro e clique em Aplicar.'
           else Result := 'Open a source file in the editor first, then click Apply.';
    'Dlg.CreateFile.Title':
      if P then Result := 'Criar Arquivo' else Result := 'Create File';
    'Dlg.CreateFile.Fmt':
      if P then Result := 'Criar arquivo:' + LineEnding + '%s'
           else Result := 'Create file:' + LineEnding + '%s';
    'Dlg.SaveFile.TitleFmt':
      if P then Result := 'Salvar %s' else Result := 'Save %s';
    'Dlg.FileError.Title':
      if P then Result := 'Erro ao Criar Arquivo' else Result := 'File Creation Error';
    'Dlg.FileError.Fmt':
      if P then
        Result := 'Falha ao criar:' + LineEnding + '%s' + LineEnding +
                  LineEnding + 'Verifique se o diretório existe e você tem permissão de escrita.'
      else
        Result := 'Failed to create:' + LineEnding + '%s' + LineEnding +
                  LineEnding + 'Check that the directory exists and you have write permission.';

    // -----------------------------------------------------------------------
    // Settings dialog — labels, buttons, group captions
    // -----------------------------------------------------------------------
    'Settings.Title':
      if P then Result := 'Configurações do Spec Wizard' else Result := 'Spec Wizard Settings';
    'Settings.Provider':
      if P then Result := 'Provedor:'    else Result := 'Provider:';
    'Settings.ApiKey':
      Result := 'API Key:';
    'Settings.Model':
      if P then Result := 'Modelo:'      else Result := 'Model:';
    'Settings.OllamaURL':
      Result := 'Ollama URL:';
    'Settings.MaxTokens':
      if P then Result := 'Máx. Tokens:' else Result := 'Max Tokens:';
    'Settings.Temperature':
      if P then Result := 'Temperatura:' else Result := 'Temperature:';
    'Settings.SpecKitPath':
      if P then Result := 'Caminho Spec-Kit:' else Result := 'Spec-Kit Path:';
    'Settings.Language':
      if P then Result := 'Idioma:'      else Result := 'Language:';
    'Settings.TestConnection':
      if P then Result := 'Testar Conexão' else Result := 'Test Connection';
    'Settings.AutoComplete':
      if P then Result := 'Autocomplete IA' else Result := 'AI Autocomplete';
    'Settings.EnableAutoComplete':
      if P then Result := 'Habilitar Autocomplete IA (Ctrl+Alt+Space)'
           else Result := 'Enable AI Autocomplete (Ctrl+Alt+Space)';
    'Settings.OK':
      Result := 'OK';
    'Settings.Cancel':
      if P then Result := 'Cancelar' else Result := 'Cancel';

    // Connection test messages
    'Conn.TestTitle':
      if P then Result := 'Teste de Conexão'     else Result := 'Connection Test';
    'Conn.Success':
      if P then Result := 'Conexão bem-sucedida!' else Result := 'Connection successful!';
    'Conn.Fail':
      if P then Result := 'Falha na conexão. Verifique sua API Key.'
           else Result := 'Connection failed. Check your API key.';
    'Conn.OllamaNotImpl':
      if P then Result := 'Teste de conexão Ollama ainda não implementado.'
           else Result := 'Ollama connection test not yet implemented.';

    // -----------------------------------------------------------------------
    // Code Assistant form — static captions
    // -----------------------------------------------------------------------
    'Form.CodeAssistant':
      if P then Result := 'Assistente de Código IA' else Result := 'AI Code Assistant';
    'Lbl.Action':
      if P then Result := 'Ação:'   else Result := 'Action:';
    'Btn.Refactor':
      if P then Result := 'Refatorar' else Result := 'Refactor';
    'Btn.Explain':
      if P then Result := 'Explicar' else Result := 'Explain';
    'Btn.Complete':
      if P then Result := 'Completar' else Result := 'Complete';
    'Btn.Fix':
      if P then Result := 'Corrigir'  else Result := 'Fix';
    'Btn.Review':
      if P then Result := 'Review' else Result := 'Review';
    'Btn.Run':
      if P then Result := 'Executar' else Result := 'Run';
    'Btn.ApplyCode':
      if P then Result := 'Aplicar'  else Result := 'Apply';
    'Lbl.AdditionalPrompt':
      if P then Result := 'Instrução adicional (opcional):'
           else Result := 'Additional instruction (optional):';
    'Lbl.Skill':
      Result := 'Skill:';
    'Lbl.SkillMode':
      if P then Result := 'Modo da skill:' else Result := 'Skill mode:';
    'Skill.None':
      if P then Result := 'Nenhuma' else Result := 'None';
    'Skill.Mode.Strict':
      Result := 'Strict';
    'Skill.Mode.Balanced':
      if P then Result := 'Balanced' else Result := 'Balanced';
    'Skill.Mode.Soft':
      Result := 'Soft';
    'Btn.Close':
      if P then Result := 'Fechar'   else Result := 'Close';
    'Lbl.SelectedCode':
      if P then Result := 'Código selecionado:' else Result := 'Selected code:';
    'Lbl.Result':
      if P then Result := 'Resultado AI:' else Result := 'AI Result:';

    // -----------------------------------------------------------------------
    // Completion preview form (autocomplete)
    // -----------------------------------------------------------------------
    'Form.CompletionPreview':
      if P then Result := 'Autocomplete IA' else Result := 'AI Completion';
    'Completion.Hint':
      if P then Result := 'Selecione linhas para inserir parcialmente, ou Aplicar para tudo.'
           else Result := 'Select lines to insert partially, or Apply for all.';
    'Btn.NextSuggestion':
      if P then Result := 'Próxima' else Result := 'Next';

    // -----------------------------------------------------------------------
    // Code Assistant runtime status messages
    // -----------------------------------------------------------------------
    'CA.Ready':
      if P then Result := 'Pronto. Selecione uma ação e clique em Executar.'
           else Result := 'Ready. Select an action and click Run.';
    'CA.NoCode':
      if P then Result := 'Nenhum código selecionado.' else Result := 'No code selected.';
    'CA.Waiting':
      if P then Result := 'Aguardando resposta anterior...'
           else Result := 'Waiting for previous response...';
    'CA.NeedApiKey':
      if P then Result := 'Configure a API Key em Ferramentas > Spec Wizard Settings.'
           else Result := 'Configure API Key at Tools > Spec Wizard Settings.';
    'CA.Consulting':
      if P then Result := 'Consultando AI...' else Result := 'Consulting AI...';
    'CA.Done':
      if P then Result := 'Concluído.' else Result := 'Done.';
    'CA.Error':
      if P then Result := 'Erro: '    else Result := 'Error: ';
    'CA.CodeError':
      if P then Result := '// Erro: ' else Result := '// Error: ';
    'CA.Applied':
      if P then Result := 'Código aplicado no editor.' else Result := 'Code applied in editor.';
    'CA.AdditionalInstruction':
      if P then Result := 'Instrução adicional do usuário: '
           else Result := 'Additional user instruction: ';

    // -----------------------------------------------------------------------
    // AI prompts sent to the language model
    //   Index corresponds to Ord(TCodeAssistAction):
    //   0=Refactor  1=Explain  2=Complete  3=Fix  4=Review
    // -----------------------------------------------------------------------
    'AI.SystemPrompt':
      if P then
        Result :=
          'Você é um assistente especialista em Free Pascal/Lazarus.' + LineEnding +
          'Ao refatorar, completar ou corrigir código, responda APENAS com código Free Pascal válido.' + LineEnding +
          'Para explicações, responda em português (pt-BR) de forma clara e concisa.' + LineEnding +
          'NÃO use marcadores de código markdown. Retorne apenas o código ou o texto da explicação.'
      else
        Result :=
          'You are an expert Free Pascal/Lazarus developer assistant.' + LineEnding +
          'When refactoring, completing, or fixing code, respond with valid Free Pascal code ONLY.' + LineEnding +
          'For explanations, respond in clear and concise English.' + LineEnding +
          'Do NOT wrap code in markdown code fences. Return only the code or explanation text.';

    'AI.SkillSystemHeader.Strict':
      if P then
        Result :=
          'Siga ESTRITAMENTE as instruções da skill abaixo durante toda a resposta. ' +
          'Se houver conflito, priorize a skill.' + LineEnding +
          '=== SKILL.MD ==='
      else
        Result :=
          'Follow the skill instructions below STRICTLY throughout your response. ' +
          'If any conflict exists, prioritize the skill.' + LineEnding +
          '=== SKILL.MD ===';

    'AI.SkillSystemHeader.Balanced':
      if P then
        Result :=
          'Use a skill abaixo como guia principal. Você pode adaptar quando necessário para manter ' +
          'correção, segurança e clareza da resposta.' + LineEnding +
          '=== SKILL.MD ==='
      else
        Result :=
          'Use the skill below as primary guidance. You may adapt when necessary to preserve ' +
          'correctness, safety, and clarity.' + LineEnding +
          '=== SKILL.MD ===';

    'AI.SkillSystemFooter':
      if P then Result := '=== FIM DA SKILL ==='
           else Result := '=== END OF SKILL ===';

    'AI.SkillSoftGuidanceHeader':
      if P then
        Result := 'Use as instruções abaixo como referência opcional durante a tarefa:'
      else
        Result := 'Use the instructions below as optional guidance for this task:';

    'AI.SkillTask.0':   // Refactor
      if P then
        Result :=
          'Refatore este código conforme as instruções da skill. Retorne somente o código:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Refactor this code according to the skill instructions. Return code only:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.SkillTask.1':   // Explain
      if P then
        Result :=
          'Explique este código conforme as instruções da skill:' + LineEnding +
          LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Explain this code according to the skill instructions:' + LineEnding +
          LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.SkillTask.2':   // Complete
      if P then
        Result :=
          'Complete este código conforme as instruções da skill. Retorne somente o código:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Complete this code according to the skill instructions. Return code only:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.SkillTask.3':   // Fix
      if P then
        Result :=
          'Corrija este código conforme as instruções da skill. Retorne somente o código corrigido:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Fix this code according to the skill instructions. Return only the corrected code:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.SkillTask.4':   // Review
      if P then
        Result :=
          'Faça code review deste código conforme as instruções da skill. ' +
          'Liste achados por severidade (alto, médio, baixo) com recomendações objetivas:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Perform a code review of this code according to the skill instructions. ' +
          'List findings by severity (high, medium, low) with concise recommendations:' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.ActionPrompt.0':   // Refactor
      if P then
        Result :=
          'Refatore o seguinte código Free Pascal para melhorar sua qualidade, legibilidade e ' +
          'eficiência, mantendo o comportamento original. Retorne apenas o código refatorado, ' +
          'sem explicações.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Refactor the following Free Pascal code to improve its quality, readability, and ' +
          'efficiency while preserving its original behaviour. Return only the refactored code, ' +
          'no explanations.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.ActionPrompt.1':   // Explain
      if P then
        Result :=
          'Explique em detalhes o que faz o seguinte código Free Pascal. ' +
          'Responda em português (pt-BR).' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Explain in detail what the following Free Pascal code does. ' +
          'Respond in English.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.ActionPrompt.2':   // Complete
      if P then
        Result :=
          'Complete o seguinte código Free Pascal. Retorne o código completo e funcional, ' +
          'sem explicações.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Complete the following Free Pascal code. Return the complete, working code ' +
          'without explanations.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.ActionPrompt.3':   // Fix
      if P then
        Result :=
          'Corrija todos os erros e problemas no seguinte código Free Pascal. ' +
          'Retorne apenas o código corrigido, sem explicações.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Fix all errors and issues in the following Free Pascal code. ' +
          'Return only the fixed code, no explanations.' + LineEnding + LineEnding +
          '```' + LineEnding + '%s' + LineEnding + '```';

    'AI.ActionPrompt.4':   // Review
      if P then
        Result :=
          'Faça um code review do código Free Pascal abaixo. Priorize bugs, riscos e regressões. ' +
          'Responda com achados ordenados por severidade e sugestões de correção.' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```'
      else
        Result :=
          'Perform a code review of the Free Pascal code below. Prioritize bugs, risks, and regressions. ' +
          'Respond with findings ordered by severity and suggested fixes.' +
          LineEnding + LineEnding + '```' + LineEnding + '%s' + LineEnding + '```';

  else
    Result := AKey;  // Unknown key — return the key as its own fallback
  end;
end;

end.
