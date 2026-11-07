# Setup do Claude Code

Ferramentas do vídeo "5 plugins pro seu claude code ficar INFINITO" + a skill find-skills, em ordem de prioridade.

| # | Ferramenta | O que faz | Por que nessa posição |
|---|---|---|---|
| 1 | [NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector) | Escaneia skills atrás de código malicioso, exfiltração de dados, prompt injection | Vem primeiro porque checa todas as outras skills antes de você instalar |
| 2 | [rtk](https://github.com/rtk-ai/rtk) | Hook que comprime a saída dos comandos Bash antes de chegar no Claude | Maior ganho no dia a dia: menos tokens e o limite dura mais |
| 3 | [ccusage](https://github.com/ccusage/ccusage) | Relatório de tokens/custo por dia, sessão e janela de 5h | Mostra se o rtk está funcionando e quanto do limite sobra |
| 4 | [find-skills](https://github.com/vercel-labs/skills) | Skill que procura outras skills (`npx skills find`) | Útil, mas só depois de ter o scanner |
| 5 | [Claude Code Router](https://github.com/musistudio/claude-code-router) / [OmniRoute](https://github.com/diegosouzapw/OmniRoute) | Usa outros modelos (DeepSeek, Gemini, OpenRouter, locais) dentro do Claude Code | **Opcional.** Os dois fazem a mesma coisa, então escolha um só. Seu código passa a ir para provedores de terceiros |

## Instalar no Windows

Abra o PowerShell e rode:

```powershell
winget install --id Git.Git -e
git clone -b claude/gallant-dirac-a4m1b1 https://github.com/thyagogrecu/claude.git
cd claude
powershell -ExecutionPolicy Bypass -File scripts\install.ps1
```

## Instalar (macOS / Linux / WSL)

Requisitos: `git`, `curl`, Node.js 22 ou mais novo, [`uv`](https://docs.astral.sh/uv/getting-started/installation/) e o Claude Code.

```bash
git clone https://github.com/thyagogrecu/claude.git && cd claude
./scripts/install.sh            # passos 1–4
./scripts/install.sh --router   # passos 1–5 (inclui o Claude Code Router)
```

Depois, reinicie o Claude Code.

### Na mão, passo a passo

```bash
# 1. SkillSpector
uv tool install git+https://github.com/NVIDIA/skillspector.git
claude mcp add --scope user skillspector -- skillspector mcp

# 2. rtk
brew install rtk   # ou: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
rtk gain           # confira que é o rtk certo (existe outro pacote com o mesmo nome)
rtk init -g        # instala o hook global

# 3. ccusage (não precisa instalar)
npx ccusage@latest daily
npx ccusage@latest blocks --live

# 4. find-skills (escaneie antes)
skillspector scan https://github.com/vercel-labs/skills.git --no-llm
npx skills add vercel-labs/skills --skill find-skills -g -a claude-code -y

# 5. (opcional) Claude Code Router
npm install -g @musistudio/claude-code-router && ccr ui
#    ...ou OmniRoute:  npx omniroute   (endpoint em http://localhost:20128/v1)
```

No Windows: `winget install rtk-ai.rtk` para o rtk. Os outros comandos funcionam igual no PowerShell.

## O que já vem neste repositório

- `.claude/skills/find-skills/`: a skill find-skills (vercel-labs/skills @ `d3701c1`) no escopo do projeto. Ela já funciona em qualquer sessão aberta neste repo, inclusive no Claude Code na web.
  Resultado do SkillSpector v2.12.0 (`--no-llm`): **score 12/100, LOW, SAFE**. Os avisos são só sobre `npx skills` sem versão fixa.

## Regra de ouro

Antes de instalar qualquer skill nova (inclusive as que o find-skills sugerir):

```bash
skillspector scan <pasta | arquivo SKILL.md | url-git> --no-llm
```

Sem `--no-llm`, o SkillSpector também faz uma análise com LLM. Para isso ele precisa de uma chave de API (`SKILLSPECTOR_PROVIDER` mais a chave do provedor) e envia o conteúdo da skill para esse provedor.
