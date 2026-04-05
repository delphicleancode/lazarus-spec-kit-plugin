{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

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

unit LazSpecWizard;

{$warn 5023 off : no warning about unused units}
interface

uses
  LazSpecWizardReg, frmSpecWizard, dlgSpecSettings, SDDEngine, PromptBuilder, 
  ContextMemory, BaseAIClient, GroqClient, SkillsLoader, SpecSettings, 
  LazSpecLang, EditorHelper, ProjectHelper, FileCreator, AICompleter, 
  AICompletionHandler, CodeAssistantHandler, frmCodeAssistant, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('LazSpecWizardReg', @LazSpecWizardReg.Register);
end;

initialization
  RegisterPackage('LazSpecWizard', @Register);
end.
