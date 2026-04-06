# Como Obter a API Key do OpenRouter

Este guia mostra como obter sua chave de API para usar o **OpenRouter** no Lazarus Spec Kit Plugin.

---

## O que é o OpenRouter?

O **OpenRouter** é um agregador de modelos de IA que oferece acesso a **dezenas de modelos** de diferentes provedores (OpenAI, Anthropic, Google, Meta, Mistral e mais) através de uma **única API key**.

### Vantagens do OpenRouter

✅ **Uma API key** para todos os modelos  
✅ **Modelos gratuitos** disponíveis (Google Gemini, Meta Llama, etc.)  
✅ **Preços competitivos** — pague apenas pelo que usar  
✅ **Comparação fácil** de modelos para encontrar o melhor custo-benefício  
✅ **Sem necessidade de contas múltiplas** em cada provedor  

---

## Passo 1: Acesse o OpenRouter

1. Abra o navegador e acesse: **https://openrouter.ai/**
2. Clique em **Sign Up** (canto superior direito)
3. Crie uma conta usando:
   - E-mail e senha
   - Google
   - GitHub
   - Discord

> 💡 O cadastro é **gratuito** e não requer cartão de crédito.

---

## Passo 2: Obtenha sua API Key

1. Após fazer login, clique no seu **perfil** (canto superior direito)
2. Selecione **Keys** no menu
3. Ou acesse diretamente: **https://openrouter.ai/keys**

4. Clique no botão **Create Key**

5. Dê um nome à sua chave (ex: `Lazarus IDE`)

6. Clique em **Create**

7. A chave será gerada e exibida. Ela se parece com:
   ```
   sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

8. ⚠️ **Copie a chave imediatamente!** Por segurança, ela só é exibida uma vez.

---

## Passo 3: Configure no Lazarus Spec Kit

1. Abra o **Lazarus IDE**
2. Vá em **Tools → Spec Wizard** (ou `Ctrl+Shift+K`)
3. Clique no ícone ⚙️ **Settings**
4. No campo **Provider**, selecione **OpenRouter**
5. No campo **API Key**, cole sua chave (`sk-or-v1-xxxxx...`)
6. No campo **Provider URL**, verifique se está:
   ```
   https://openrouter.ai/api/v1
   ```
7. Escolha o modelo desejado:
   - `meta-llama/llama-3.3-70b-instruct` — excelente para código **(recomendado)**
   - `anthropic/claude-3.5-sonnet` — alta qualidade
   - `google/gemini-2.0-flash-exp:free` — **gratuito**
   - `mistralai/mistral-large` — boa relação custo-benefício
8. Clique em **Test Connection** para verificar
9. Clique em **OK** para salvar

---

## Modelos Populares no OpenRouter

| Modelo | Provedor | Preço | Ideal para |
|--------|----------|-------|------------|
| `google/gemini-2.0-flash-exp:free` | Google | **Grátis** | Testes, uso básico |
| `meta-llama/llama-3.3-70b-instruct` | Meta | ~$0.0007/1K tokens | **Código (recomendado)** |
| `anthropic/claude-3.5-sonnet` | Anthropic | ~$0.015/1K tokens | Código complexo, planejamento |
| `mistralai/mistral-large` | Mistral | ~$0.003/1K tokens | Uso geral |
| `openai/gpt-4o` | OpenAI | ~$0.015/1K tokens | Máxima qualidade |
| `deepseek/deepseek-chat` | DeepSeek | ~$0.0003/1K tokens | Econômico |

> 💡 A lista completa de modelos está em: https://openrouter.ai/models

---

## Como Funcionam os Preços

O OpenRouter cobra por **1.000 tokens** (aproximadamente 750 palavras):

- **Modelos gratuitos**: Sem custo algum
- **Modelos econômicos**: $0.0001 - $0.001 por 1K tokens
- **Modelos premium**: $0.01 - $0.06 por 1K tokens

> 💡 Você pode adicionar créditos na página **Credits** do seu perfil. O mínimo é $5.

---

## Dicas de Uso

### Para desenvolvimento econômico:
1. Use `google/gemini-2.0-flash-exp:free` para testes
2. Use `meta-llama/llama-3.3-70b-instruct` para código (barato e eficiente)
3. Reserve `anthropic/claude-3.5-sonnet` para tarefas complexas

### Para máxima qualidade:
1. `anthropic/claude-3.5-sonnet` — excelente para código
2. `openai/gpt-4o` — melhor resposta geral
3. `google/gemini-pro-1.5` — bom para contextos longos

---

## Troubleshooting

### Erro: "API key is not configured"
- Verifique se colou a chave corretamente no campo **API Key**
- Certifique-se de que o provider **OpenRouter** está selecionado

### Erro: "HTTP request failed"
- Verifique sua conexão com a internet
- Confirme que a URL está correta: `https://openrouter.ai/api/v1`
- Teste a chave no botão **Test Connection**

### Erro: "Unknown API error" ou resposta vazia
- Sua chave pode ter expirado — crie uma nova
- Verifique se há créditos na sua conta OpenRouter
- O modelo selecionado pode estar indisponível — tente outro

### Erro de SSL/OpenSSL
- Certifique-se de que o **OpenSSL** está instalado no Windows
- Os arquivos `libssl-3-x64.dll` e `libcrypto-3-x64.dll` devem estar no PATH

---

## Links Úteis

- 🌐 [OpenRouter Website](https://openrouter.ai/)
- 🔑 [Gerenciar API Keys](https://openrouter.ai/keys)
- 📚 [Lista de Modelos](https://openrouter.ai/models)
- 💰 [Preços](https://openrouter.ai/pricing)
- 📖 [Documentação da API](https://openrouter.ai/docs)

---

*Lazarus Spec Kit Plugin — OpenRouter Integration*
