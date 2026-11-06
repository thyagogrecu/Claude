#!/usr/bin/env bash
# Instala os plugins/ferramentas do Claude Code em ordem de prioridade.
#
#   ./scripts/install.sh            -> passos 1 a 4 (recomendado)
#   ./scripts/install.sh --router   -> também instala o Claude Code Router (passo 5, opcional)
#
# Requisitos: git, curl, Node.js >= 22, uv (https://docs.astral.sh/uv/) e o Claude Code (`claude`).
set -euo pipefail

WITH_ROUTER=0
[[ "${1:-}" == "--router" ]] && WITH_ROUTER=1

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Falta '$1' no PATH. Instale e rode de novo."; exit 1; }; }

need git; need curl; need node; need npx; need uv
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# 1) NVIDIA SkillSpector — scanner de segurança de skills.
#    Vem primeiro porque é ele que valida as skills que vamos instalar depois.
# ---------------------------------------------------------------------------
say "1/5 NVIDIA SkillSpector (segurança de skills)"
uv tool install --force git+https://github.com/NVIDIA/skillspector.git
skillspector --version
if command -v claude >/dev/null 2>&1; then
  claude mcp add --scope user skillspector -- skillspector mcp 2>/dev/null \
    || echo "(MCP 'skillspector' já estava registrado)"
fi

# ---------------------------------------------------------------------------
# 2) rtk (Rust Token Killer) — comprime a saída dos comandos Bash antes de
#    chegar no contexto do Claude. Economia de tokens no dia a dia.
# ---------------------------------------------------------------------------
say "2/5 rtk (economia de tokens)"
if ! command -v rtk >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install rtk
  else
    # Fixa a versão para não depender da API do GitHub (rate limit).
    RTK_VERSION="${RTK_VERSION:-v1.1.0}" \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh)"
  fi
fi
rtk --version   # tem que dizer "rtk 1.x" (existe outro pacote chamado rtk que não é este)
rtk init -g     # instala o hook PreToolUse global do Claude Code

# ---------------------------------------------------------------------------
# 3) ccusage — mostra quanto você está gastando (tokens/custo) por dia,
#    sessão e janela de 5h. Não precisa instalar, roda via npx.
# ---------------------------------------------------------------------------
say "3/5 ccusage (monitor de uso)"
npx -y ccusage@latest daily --offline | tail -n 15 || true

# ---------------------------------------------------------------------------
# 4) find-skills (vercel-labs) — skill que procura outras skills.
#    Escaneada com o SkillSpector ANTES de instalar.
# ---------------------------------------------------------------------------
say "4/5 find-skills (skill que procura skills)"
TMP="$(mktemp -d)"
git clone -q --depth 1 https://github.com/vercel-labs/skills.git "$TMP/skills"
skillspector scan "$TMP/skills/skills/find-skills" --no-llm --format json --output "$TMP/report.json"
REC="$(node -e 'const r=require(process.argv[1]);console.log(String(r.recommendation||r.risk_assessment?.recommendation||"").toUpperCase())' "$TMP/report.json" 2>/dev/null || true)"
echo "SkillSpector: ${REC:-desconhecido}"
if [[ "$REC" == *SAFE* ]]; then
  DISABLE_TELEMETRY=1 npx -y skills add vercel-labs/skills --skill find-skills -g -a claude-code -y
else
  echo "Scan não retornou SAFE — veja $TMP/report.json antes de instalar."
fi

# ---------------------------------------------------------------------------
# 5) Claude Code Router (opcional) — usa outros modelos (DeepSeek, Gemini,
#    OpenRouter, locais...) dentro do Claude Code. Use OU este OU o OmniRoute.
# ---------------------------------------------------------------------------
if [[ $WITH_ROUTER -eq 1 ]]; then
  say "5/5 Claude Code Router (opcional)"
  npm install -g @musistudio/claude-code-router
  echo "Rode 'ccr ui' (abre http://127.0.0.1:3458) para cadastrar provedores."
else
  say "5/5 Router pulado (rode com --router se quiser)"
fi

say "Pronto! Reinicie o Claude Code para carregar o hook do rtk e a skill find-skills."
echo "Dicas: 'rtk gain' mostra a economia | 'npx ccusage@latest blocks --live' acompanha a janela de 5h"
echo "Antes de instalar qualquer skill nova: skillspector scan <pasta|url-git>"
