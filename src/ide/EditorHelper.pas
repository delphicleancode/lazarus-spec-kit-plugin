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

unit EditorHelper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SrcEditorIntf, LazIDEIntf;

type
  { TEditorHelper - Helper for Source Editor integration }
  TEditorHelper = class
  public
    class function GetActiveSourceCode: string;
    class function GetSelectedText: string;
    class function GetActiveFileName: string;
    class procedure InsertTextAtCursor(const AText: string);
    class procedure ReplaceSelectedText(const AText: string);
    class function HasActiveEditor: Boolean;
  end;

implementation

{ TEditorHelper }

class function TEditorHelper.HasActiveEditor: Boolean;
begin
  Result := (SourceEditorManagerIntf <> nil) and
            (SourceEditorManagerIntf.ActiveEditor <> nil);
end;

class function TEditorHelper.GetActiveSourceCode: string;
var
  Editor: TSourceEditorInterface;
begin
  Result := '';
  if not HasActiveEditor then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  Result := Editor.SourceText;
end;

class function TEditorHelper.GetSelectedText: string;
var
  Editor: TSourceEditorInterface;
begin
  Result := '';
  if not HasActiveEditor then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  Result := Editor.Selection;
end;

class function TEditorHelper.GetActiveFileName: string;
var
  Editor: TSourceEditorInterface;
begin
  Result := '';
  if not HasActiveEditor then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  Result := Editor.FileName;
end;

class procedure TEditorHelper.InsertTextAtCursor(const AText: string);
var
  Editor: TSourceEditorInterface;
begin
  if not HasActiveEditor then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  Editor.Selection := AText;
end;

class procedure TEditorHelper.ReplaceSelectedText(const AText: string);
var
  Editor: TSourceEditorInterface;
begin
  if not HasActiveEditor then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  if Editor.Selection <> '' then
    Editor.Selection := AText;
end;

end.
