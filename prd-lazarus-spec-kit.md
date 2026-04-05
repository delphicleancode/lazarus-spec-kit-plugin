Aqui está um plano estruturado para adicionar o recurso Lazarus OTA no projeto lazarus-spec-kit, com integração inicial à Groq para gerar planos SDD (Spec-Driven Development) via wizard que usa skills de IA. O foco é criar um plugin dockable na IDE Lazarus, inspirado em ferramentas como Kiro e Claude Code, alinhado ao seu expertise em Lazarus e automação de desenvolvimento. [perplexity](https://www.perplexity.ai/search/d175f4af-4d9b-4317-b3bf-f50331bb7570)

## Visão Geral

O recurso usará OTA (Open Tools API) do Lazarus para injetar um wizard com chat em modos Agent/Plan/Ask, gerando specs SDD baseadas no lazarus-spec-kit e prompts com skills (ex: Clean Code, LGPD, DB refactor). Inicialmente, integra Groq API para inferência rápida com modelos como Llama 3.3, expandindo para Ollama local depois. [console.groq](https://console.groq.com/docs/api-reference)

## Requisitos Iniciais

- **Funcional**: Wizard dockable com input de specs, geração de units/tests via IA, memória de contexto local. Modos: Ask (consulta simples), Plan (SDD gerado), Agent (iterativo com skills).
- **Não Funcional**: Compatível Lazarus 3.x+, JSON/HTTP via FpHTTPClient + fpjson, LGPD-compliant (dados locais). MVP em 3-4 semanas solo. [scribd](https://www.scribd.com/document/330220396/The-Delphi-IDE-Open-Tools-API-Version-1-1)
- **Dependências**: Clone lazarus-spec-kit, adicione ToolsAPI.pas (de Lazarus source). [gexperts](https://www.gexperts.org/open-tools-api-faq/)

## Arquitetura Técnica

```
Lazarus IDE (OTA Host)
├── Wizard Principal (IOTAProjectWizard/IOTAWizard)
│   ├── Form Dockable (TForm com TMemo input/output)
│   ├── Groq Client (THTTPClient + TJSONParser)
│   └── SDD Engine (Skills do spec-kit como prompts)
└── Package (.lpk): LazarusSpecWizard.lpk
```

O wizard registra via GetIDString no OTA, executa chamadas Groq (/chat/completions) com specs do repositório. [github](https://github.com/jmpessoa/LazCWizard)

## Passos de Implementação

1. **Setup Projeto**: Clone <https://github.com/delphicleancode/lazarus-spec-kit>, crie novo package (.lpk) com requires DesignIDE. Adicione unit WizardMain com IOTAWizard. [gexperts](https://www.gexperts.org/open-tools-api-faq/)
2. **Groq Integração**: Crie TSpecGroqClient com fphttpclient.Post para endpoint <https://api.groq.com/openai/v1/chat/completions>. Use API key via env var, modelo "llama3-70b-8192". Exemplo prompt: "Gere SDD para [unit] usando skills: SOLID, PostgreSQL." [console.groq](https://console.groq.com/docs/api-reference)
3. **Wizard UI**: Form com TButton modes, TMemo specs/output. Registre no Initialize: IDE.AddCustomizer(Self). [scribd](https://www.scribd.com/document/330220396/The-Delphi-IDE-Open-Tools-API-Version-1-1)
4. **SDD Geração**: Carregue specs do spec-kit como skills (JSON/array), injete em prompt Groq. Gere código/tests via response, aplique via IOTAEditWriter. [arxiv](https://arxiv.org/abs/2602.00180)
5. **Teste/Instalação**: Compile .lpk, Package > Install. Teste em projeto Lazarus vazio. [github](https://github.com/jmpessoa/LazCWizard)

## Cronograma e Roadmap

| Fase | Duração | Entregas |
|------|---------|----------|
| MVP (Chat + Groq Ask) | 1 semana | Wizard básico com specs simples. [console.groq](https://console.groq.com/docs/api-reference) |
| SDD Completo (Plan/Agent) | 2 semanas | Skills do spec-kit, memória local.
| Polish/Expand | 1 semana | Docker Ollama, docs. |
