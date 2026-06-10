# Lead Machine Lite

Landing page publica com diagnostico empresarial automatico via IA. O lead preenche um formulario, o sistema conduz um chat de ate 10 perguntas geradas pelo Claude e entrega um relatorio completo com estado atual, gargalos e futuro com IA.

Voce ve tudo no dashboard local e chega na call ja sabendo o perfil do lead.

## Como funciona

```
Lead acessa URL publica
       |
       v
Preenche nome / email / empresa
       |
       v
Claude faz ate 10 perguntas personalizadas (FastAPI + Anthropic SDK)
       |
       v
Relatorio gerado: estado atual, gargalos, futuro com IA
       |
       v
Voce ve no dashboard: http://127.0.0.1:8792/dashboard
```

## Stack

- **Backend**: Python 3.10+ + FastAPI + Uvicorn
- **LLM**: Claude API (Anthropic SDK) — usa sua propria chave, sem mensalidade
- **Tunnel**: Cloudflare Tunnel (trycloudflare.com) — URL publica gratuita
- **Storage**: JSON local em `~/zx-leads/` — dados 100% seus
- **Rate limiting**: slowapi

## Instalacao (Windows)

**Pre-requisitos**: Python 3.10+, cloudflared instalado

```powershell
# 1. Clone e instale dependencias
git clone https://github.com/Dimitrearaujo/lead-machine-lite
cd lead-machine-lite
python -m venv venv
venv\Scripts\pip install -r requirements.txt

# 2. Configure o .env
copy .env.example .env
# Edite o .env com sua ANTHROPIC_API_KEY e gere um ALUNO_TOKEN

# 3. Inicie
powershell -ExecutionPolicy Bypass -File scripts\start.ps1
```

## Configuracao (.env)

```env
ANTHROPIC_API_KEY=sk-ant-...        # console.anthropic.com/settings/keys
PORT=8792
LEADS_DIR=~/zx-leads
MODEL=claude-sonnet-4-6
ALUNO_TOKEN=                        # gere com: python -c "import secrets; print(secrets.token_urlsafe(24))"
```

## Endpoints

| Metodo | Rota | Descricao |
|---|---|---|
| GET | `/health` | Status do backend |
| POST | `/lead/new` | Cria lead e retorna primeira pergunta |
| POST | `/lead/answer` | Envia resposta e recebe proxima pergunta |
| GET | `/lead/status/{id}` | Status do diagnostico |
| GET | `/lead/result/{id}` | Relatorio final |
| GET | `/dashboard` | Dashboard do operador (requer ALUNO_TOKEN) |
| GET | `/api/leads` | Lista leads (requer ALUNO_TOKEN) |
| POST | `/lead/generate-copy` | Gera copy de marketing para o lead |
| POST | `/lead/generate-kit` | Gera kit comercial completo para o lead |

## Scripts Windows (pasta scripts/)

```powershell
scripts\start.ps1    # sobe backend + tunnel, salva URL em tunnel-url.txt
scripts\stop.ps1     # para tudo
scripts\restart.ps1  # reinicia
scripts\status.ps1   # mostra estado, URL e ultimos logs
```

## Nota sobre Windows

O `fcntl.py` na raiz e um shim para compatibilidade — substitui o modulo Unix `fcntl` por no-ops seguros para uso em servidor local single-process.

## Licenca

MIT
