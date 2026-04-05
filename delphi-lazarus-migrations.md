name: delphi-lazarus-migration
description: >
  Migração completa de projetos Delphi IntraWeb para Lazarus IntraWeb, mantendo
  funcionalidade idêntica sem refatorar lógica de negócio. Use esta skill sempre
  que o usuário mencionar migração Delphi→Lazarus, conversão de projetos IntraWeb,
  substituição de FireDAC por Zeos, conversão de .dfm para .lfm, adaptação de units
  System.* para Lazarus, ou qualquer tarefa que envolva portar código Delphi para
  Free Pascal/Lazarus. Também acione quando o usuário disser "RETOMAR" em contexto
  de migração, ou pedir para continuar uma migração interrompida.
---

# Skill: Migração Delphi IntraWeb → Lazarus IntraWeb

## 🎯 Objetivo
Migrar projetos Delphi IntraWeb para Lazarus IntraWeb mantendo *funcionalidade idêntica*.  
*Não refatorar, não corrigir SQL, não alterar lógica de negócio.*

---

## 📋 REGRAS CRÍTICAS (NUNCA VIOLAR)

1. *NÃO refatorar código* — manter lógica original intacta
2. *NÃO corrigir nomes* de colunas, tabelas ou SQL
3. *NÃO alterar funcionalidades* — apenas migrar estrutura
4. *NÃO criar arquivos .ini* para configuração de banco
5. *MANTER compatibilidade* com HTTP.SYS do Delphi
6. *SEMPRE atualizar* migration_log.md após cada arquivo migrado
7. *NUNCA pular* etapas sem documentar no log

---

## 🔄 SISTEMA DE CHECKPOINT (LOG DE MIGRAÇÃO)

Antes de qualquer coisa: *criar e manter o arquivo migration_log.md* na raiz do projeto.  
Ver estrutura completa do log em: references/migration_log_template.md

### Comandos de Controle
| Comando | Ação |
|---------|------|
| RETOMAR | Ler migration_log.md e continuar de onde parou |
| STATUS | Exibir progresso atual da migração |
| PAUSAR | Salvar estado e encerrar sessão com segurança |

### Fluxo ao Receber "RETOMAR"
1. Ler migration_log.md
2. Identificar último arquivo concluído
3. Retomar do próximo arquivo pendente
4. Continuar atualizando log normalmente

---

## 📁 Estrutura de Diretórios


NomeProjeto/
├── backup/        # Backups do projeto original Delphi
├── lib/           # Executável compilado + wwroot + DLLs
│   └── wwroot/   # Gerenciado automaticamente pelo IntraWeb
├── temp/          # Arquivos temporários de compilação (.o, .ppu)
├── src/           # TODOS os .pas e .lfm
└── [raiz]/        # .lpi, .lpr, .lres, .dbg, migration_log.md


---

## 📦 ORDEM DE MIGRAÇÃO

### Etapa 1 — Estrutura Base
- [ ] Criar pastas: backup/, lib/, temp/, src/
- [ ] Criar NOMEPROJETO.lpi (ver template em references/templates.md)
- [ ] Criar NOMEPROJETO.lpr (ver template abaixo)
- [ ] Criar NOMEPROJETO.lres (vazio)
- [ ] Criar migration_log.md com lista completa de arquivos

### Etapa 2 — Arquivos Principais (nesta ordem)

servercontroller.pas/.lfm
usersessionunit.pas/.lfm
udm.pas/.lfm  (DataModule — converter FireDAC → Zeos aqui)
uBase.pas/.lfm  (formulário base, se existir)


### Etapa 3 — Demais Formulários e Units
Migrar na ordem: formulários principais → formulários secundários → units auxiliares

### Etapa 4 — Finalização
- [ ] Compilação de teste com compile.bat
- [ ] Verificar DLLs em lib/
- [ ] Testar funcionalidades críticas

---

## 🔧 CONVERSÕES OBRIGATÓRIAS

### Extensões de Arquivo
| Delphi | Lazarus |
|--------|---------|
| .dpr | .lpr |
| .dproj | .lpi |
| .dfm | .lfm |
| .pas | .pas (sem alteração) |

### Componentes de Banco de Dados
| FireDAC | Zeos | Units |
|---------|------|-------|
| TFDConnection | TZConnection | ZConnection |
| TFDQuery | TZQuery | ZDataset |
| TFDStoredProc | TZStoredProc | ZDataset |
| TFDTable | TZTable | ZDataset |

### Units (remover namespaces System.* / VCL.*)
| Delphi | Lazarus |
|--------|---------|
| System.SysUtils | SysUtils |
| System.Classes | Classes |
| System.JSON | JsonDataObjects |
| REST.Client, TRESTClient | RESTRequest4D |
| FireDAC.* | ZConnection, ZDataset |
| VCL.* | LCL.* ou remover |
| System.Generics.Collections | Generics.Collections |

---

## 📝 DIRETIVAS OBRIGATÓRIAS EM TODOS OS .PAS

Adicionar logo após unit NomeUnit;:
pascal
{$mode delphiunicode}
{$codepage utf8}


---

## 📄 TEMPLATE DO ARQUIVO .LPR

pascal
program NOMEPROJETO;

{$mode delphiunicode}
{$codepage utf8}

uses
  Interfaces,
  IWStartHSys,
  servercontroller,
  usersessionunit,
  // adicionar demais units aqui
  ;

{$R *.res}

begin
  {$ifndef release}
  TIWStartHSys.Execute(True);   // Modo Debug
  {$else}
  TIWStartHSys.Execute(False);  // Modo Release
  {$endif}
end.


---

## ⚙️ PACOTES NECESSÁRIOS NO .LPI

xml
<RequiredPackages>
  <Item><PackageName Value="LazDaemon"/></Item>
  <Item><PackageName Value="LCL"/></Item>
  <Item><PackageName Value="FCL"/></Item>
  <Item><PackageName Value="dclIntraWeb_16_Lazarus"/></Item>
  <Item><PackageName Value="zcomponentdesign"/></Item>
  <Item><PackageName Value="zcomponent"/></Item>
</RequiredPackages>


### Paths de Compilação (OtherUnitFiles)

src;C:\Users\Administrator\AppData\Roaming\IntraWeb 16\LibLazarus;C:\Users\Administrator\Documents\Componentes\RestRequest4Delphi\src;C:\Users\Administrator\Documents\Componentes\Json4Delphi\src


---

## 🗃️ CONFIGURAÇÃO DE BANCO (SEM .INI)

pascal
procedure TDM.ConfigurarConexao(AServer, ADatabase, AUser, APass: string);
begin
  ZConnection1.Protocol := 'mysql';  // ou mssql, postgresql
  ZConnection1.HostName := AServer;
  ZConnection1.Database := ADatabase;
  ZConnection1.User     := AUser;
  ZConnection1.Password := APass;
  ZConnection1.Port     := 3306;
  ZConnection1.Connected := True;
end;

*⚠️ Chamar no login, não na inicialização do DM.*

---

## 🐛 TROUBLESHOOTING RÁPIDO

| Erro | Solução |
|------|---------|
| Unit X not found | Verificar paths em OtherUnitFiles no .lpi |
| Invalid compiler mode | Adicionar {$mode delphiunicode} |
| TFDConnection does not exist | Substituir por TZConnection + uses ZConnection |
| RESTRequest4D not found | Verificar path do RestRequest4Delphi |
| JsonDataObjects not found | Verificar path do Json4Delphi |
| Erro na compilação do .lfm | Abrir formulário no IDE Lazarus e salvar novamente |
| Executável não inicia | Verificar DLLs em lib/ |
| System.Generics.Collections | Substituir por Generics.Collections |

---

## 📚 Referências Detalhadas

- references/templates.md — Templates completos de .lpi, compile.bat, migration_log.md
- references/units_guide.md — Guia completo de substituição de units e exemplos REST/JSON