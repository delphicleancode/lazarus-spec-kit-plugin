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

unit LazSpecWizardReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, MenuIntf, IDEWindowIntf,
  IDECommands, LazIDEIntf, BaseIDEIntf, LCLType;

procedure Register;

implementation

uses
  frmSpecWizard, AICompletionHandler, CodeAssistantHandler;

const
  SpecWizardFormName = 'LazSpecWizardWindow';

type
  { TSpecWizardRestoreHandler - Wraps the restore callback as a method }
  TSpecWizardRestoreHandler = class
    procedure OnIDERestore(Sender: TObject);
  end;

var
  SpecWizardWindow: TSpecWizardForm = nil;
  RestoreHandler: TSpecWizardRestoreHandler = nil;

procedure CreateSpecWizardForm(Sender: TObject; AFormName: string; var AForm: TCustomForm; DoDisableAutoSizing: Boolean);
begin
  if CompareText(AFormName, SpecWizardFormName) <> 0 then
    Exit;
  IDEWindowCreators.CreateForm(SpecWizardWindow, TSpecWizardForm,
    DoDisableAutoSizing, LazarusIDE.OwningComponent);
  AForm := SpecWizardWindow;
end;

procedure ShowSpecWizardWindow(Sender: TObject);
begin
  IDEWindowCreators.ShowForm(SpecWizardFormName, True);
end;

{ TSpecWizardRestoreHandler }

procedure TSpecWizardRestoreHandler.OnIDERestore(Sender: TObject);
begin
  // Called during IDE startup to restore window state
  // Only show if it was visible in the previous session
end;

procedure Register;
var
  CmdCategory: TIDECommandCategory;
  IDECommand: TIDECommand;
  AICompleteCmd: TIDECommand;
begin
  // Register dockable window creator
  IDEWindowCreators.Add(SpecWizardFormName,
    @CreateSpecWizardForm, nil,
    '70%', '0', '30%', '100%');

  // Register keyboard shortcut Ctrl+Shift+K
  CmdCategory := IDECommandList.FindCategoryByName(CommandCategoryToolMenuName);
  if CmdCategory <> nil then
  begin
    IDECommand := RegisterIDECommand(CmdCategory,
      'LazSpecWizardShow',
      'Show Spec Wizard',
      IDEShortCut(ord('K'), [ssCtrl, ssShift], VK_UNDEFINED, []),
      nil, @ShowSpecWizardWindow);
    // Register menu item under Tools with the shortcut
    RegisterIDEMenuCommand(itmSecondaryTools, 'LazSpecWizard',
      'AI Spec Wizard', nil, nil, IDECommand);

    // Register AI Autocomplete shortcut Ctrl+Shift+Space
    AICompleteCmd := RegisterIDECommand(CmdCategory,
      'LazSpecAIComplete',
      'AI Autocomplete',
      IDEShortCut(VK_SPACE, [ssCtrl, ssShift], VK_UNDEFINED, []),
      nil, @TriggerAICompletion);
    RegisterIDEMenuCommand(itmSecondaryTools, 'LazSpecAIComplete',
      'AI Autocomplete', nil, nil, AICompleteCmd);

    // Register AI Code Assistant shortcut Ctrl+Shift+A
    RegisterIDECommand(CmdCategory,
      'LazSpecAIAssistant',
      'AI Code Assistant',
      IDEShortCut(ord('A'), [ssCtrl, ssShift], VK_UNDEFINED, []),
      nil, @TriggerCodeAssistantDefault);
    RegisterIDEMenuCommand(itmSecondaryTools, 'LazSpecAIAssistant',
      'AI Code Assistant', nil, @TriggerCodeAssistantDefault);
  end
  else
  begin
    // Fallback: register without shortcut
    RegisterIDEMenuCommand(itmSecondaryTools, 'LazSpecWizard',
      'Spec Wizard', nil, @ShowSpecWizardWindow);
  end;

  // Restore window on IDE startup
  RestoreHandler := TSpecWizardRestoreHandler.Create;
  LazarusIDE.AddHandlerOnIDERestoreWindows(@RestoreHandler.OnIDERestore);

  // Eagerly initialize the completion handler so the Application key hook
  // is registered before the user opens any source file.
  InitAICompletionHandler;

  // Initialize the AI Code Assistant IDE integration (context menu + gutter).
  InitCodeAssistantHandler;
end;

finalization
  FreeAndNil(RestoreHandler);

end.
