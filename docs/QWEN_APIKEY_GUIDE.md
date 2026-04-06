# Como Obter a API Key do DashScope (Qwen)

Este guia mostra como obter sua chave de API para usar os modelos **Qwen** no Lazarus Spec Kit Plugin.

---

## Pré-requisitos

- Conta no [Alibaba Cloud](https://www.alibabacloud.com/) (crie gratuitamente)
- Navegador web

---

## Passo 1: Acesse o Alibaba Cloud

1. Abra o navegador e acesse: **https://www.alibabacloud.com/**
2. Clique em **Sign Up** (canto superior direito) para criar uma conta gratuita, ou **Sign In** se já tiver uma.

> 💡 A conta é gratuita e o Alibaba Cloud oferece créditos de teste para novos usuários.

---

## Passo 2: Acesse o Console do DashScope

1. Após fazer login, acesse o **DashScope Console**:
   - **Internacional:** https://dashscope.console.aliyun.com/
   - **China:** https://dashscope.console.aliyun.com/ (mesma URL)

2. Se solicitado, aceite os **Termos de Serviço** do DashScope.

---

## Passo 3: Crie uma API Key

1. No painel lateral esquerdo, clique em **API-KEY Management** (ou **Keys**).

2. Clique no botão **Create New API Key** (ou **Create Key**).

3. A chave será gerada e exibida na tela. Ela se parece com:
   ```
   sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. ⚠️ **Copie a chave imediatamente!** Por segurança, ela só é exibida uma vez.

---

## Passo 4: Configure no Lazarus Spec Kit

1. Abra o **Lazarus IDE**
2. Vá em **Tools → Spec Wizard** (ou `Ctrl+Shift+K`)
3. Clique no ícone ⚙️ **Settings**
4. No campo **Provider**, selecione **Qwen**
5. No campo **API Key**, cole sua chave (`sk-xxxxx...`)
6. No campo **Ollama URL / Qwen URL**, verifique se está:
   ```
   https://dashscope.aliyuncs.com/compatible-mode/v1
   ```
7. Escolha o modelo desejado:
   - `qwen-turbo` — mais rápido e econômico
   - `qwen-plus` — equilíbrio entre qualidade e velocidade **(recomendado)**
   - `qwen-max` — máxima qualidade de resposta
   - `qwen-long` — para contextos longos (até 1M tokens)
8. Clique em **Test Connection** para verificar
9. Clique em **OK** para salvar

---

## Modelos Disponíveis

| Modelo | Descrição | Ideal para |
|--------|-----------|------------|
| `qwen-turbo` | Rápido e econômico | Autocomplete, tarefas simples |
| `qwen-plus` | Equilíbrio custo/benefício | **Uso geral (recomendado)** |
| `qwen-max` | Máxima qualidade | Planejamento, código complexo |
| `qwen-long` | Contexto ultra-longo | Análise de arquivos grandes |
| `qwen-vl-max` | Multimodal (visão + texto) | Não usado no plugin |

---

## Preços

O DashScope oferece um **tier gratuito generoso** para novos usuários:

| Modelo | Preço aprox. |
|--------|-------------|
| `qwen-turbo` | Gratuito (limitado) / ~$0.0003/1K tokens |
| `qwen-plus` | ~$0.001/1K tokens |
| `qwen-max` | ~$0.004/1K tokens |

> 💡 Consulte a [página de preços](https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qianwen-qwen-metering-and-billing) para valores atualizados.

---

## Troubleshooting

### Erro: "API key is not configured"
- Verifique se colou a chave corretamente no campo **API Key**
- Certifique-se de que o provider **Qwen** está selecionado

### Erro: "HTTP request failed"
- Verifique sua conexão com a internet
- Confirme que a URL está correta: `https://dashscope.aliyuncs.com/compatible-mode/v1`
- Teste a chave no botão **Test Connection**

### Erro: "Unknown API error" ou resposta vazia
- Sua chave pode ter expirado — crie uma nova no console
- Verifique se há saldo/créditos na sua conta Alibaba Cloud
- O modelo selecionado pode estar indisponível — tente outro

### Erro de SSL/OpenSSL
- Certifique-se de que o **OpenSSL** está instalado no Windows
- Os arquivos `libssl-3-x64.dll` e `libcrypto-3-x64.dll` devem estar no PATH

---

## Links Úteis

- 🌐 [DashScope Console](https://dashscope.console.aliyun.com/)
- 📖 [Documentação da API Qwen](https://help.aliyun.com/zh/dashscope/developer-reference/api-reference)
- 💰 [Preços](https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qianwen-qwen-metering-and-billing)
- 🏠 [Alibaba Cloud](https://www.alibabacloud.com/)

---

*Lazarus Spec Kit Plugin — Qwen/DashScope Integration*
