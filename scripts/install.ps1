# Instalador para Windows (PowerShell). Rode:
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1
# Ordem: 1) SkillSpector  2) rtk + hook  3) ccusage  4) find-skills
$ErrorActionPreference = "Stop"

function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Yellow }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
              "$env:USERPROFILE\.local\bin"
}

Say "0/4 Pre-requisitos (git, Node.js, uv)"
foreach ($id in @("Git.Git", "OpenJS.NodeJS", "astral-sh.uv")) {
  winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent
}
Refresh-Path

Say "1/4 NVIDIA SkillSpector"
uv tool install --force git+https://github.com/NVIDIA/skillspector.git
Refresh-Path
skillspector --version
if (Get-Command claude -ErrorAction SilentlyContinue) {
  claude mcp add --scope user skillspector -- skillspector mcp
}

Say "2/4 rtk + hook do Claude Code"
winget install --id rtk-ai.rtk -e --accept-source-agreements --accept-package-agreements --silent
Refresh-Path
rtk --version
rtk init -g

Say "3/4 ccusage"
npx -y ccusage@latest daily --offline

Say "4/4 find-skills (escaneada antes)"
$tmp = Join-Path $env:TEMP ("skills-" + [guid]::NewGuid())
git clone -q --depth 1 https://github.com/vercel-labs/skills.git $tmp
skillspector scan "$tmp\skills\find-skills" --no-llm --format json --output "$tmp\report.json"
$rec = (Get-Content "$tmp\report.json" -Raw | ConvertFrom-Json).risk_assessment.recommendation
Write-Host "SkillSpector: $rec"
if ($rec -eq "SAFE") {
  $env:DISABLE_TELEMETRY = "1"
  npx -y skills add vercel-labs/skills --skill find-skills -g -a claude-code -y
} else {
  Write-Host "Nao deu SAFE - veja $tmp\report.json antes de instalar."
}

Say "Pronto! Feche e abra o Claude Code. Teste com: rtk gain"
