#!/bin/bash
# =============================================================================
# build-and-push.sh
# Build e push da imagem ghcr.io/empresacontalo/docker_xubuntu:latest
# Execute na VPS com: bash build-and-push.sh
# =============================================================================

set -e

IMAGE="ghcr.io/empresacontalo/docker_xubuntu:latest"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GH_USER="empresacontalo"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Docker Build & Push → GHCR${NC}"
echo -e "${BLUE}  Imagem: ${IMAGE}${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# --- 1. Verificar dependências ---
log "Verificando dependências..."
command -v docker >/dev/null 2>&1 || err "Docker não encontrado. Instale: https://docs.docker.com/engine/install/"
command -v git    >/dev/null 2>&1 || err "Git não encontrado."
ok "Docker $(docker --version | awk '{print $3}' | tr -d ',')"

# --- 2. Verificar espaço em disco ---
log "Verificando espaço em disco..."
AVAILABLE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
log "Espaço disponível: ${AVAILABLE_GB}GB"
if [ "$AVAILABLE_GB" -lt 50 ]; then
    warn "Menos de 50GB disponíveis (${AVAILABLE_GB}GB). Limpando Docker..."
    docker system prune -af --volumes || true
    AVAILABLE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    log "Espaço após limpeza: ${AVAILABLE_GB}GB"
fi
if [ "$AVAILABLE_GB" -lt 30 ]; then
    err "Espaço insuficiente: ${AVAILABLE_GB}GB. São necessários pelo menos 30GB."
fi
ok "Espaço suficiente: ${AVAILABLE_GB}GB"

# --- 3. Atualizar repositório ---
log "Atualizando repositório..."
cd "$REPO_DIR"
git fetch origin
git pull origin main
ok "Repositório atualizado ($(git log -1 --format='%h %s'))"

# --- 4. Login no GHCR ---
log "Autenticando no GitHub Container Registry..."
if [ -z "$GHCR_TOKEN" ]; then
    echo ""
    echo -e "${YELLOW}Token GHCR não encontrado na variável GHCR_TOKEN.${NC}"
    echo -e "Gere um token em: ${BLUE}https://github.com/settings/tokens${NC}"
    echo -e "(Permissões necessárias: ${GREEN}write:packages, read:packages${NC})"
    echo ""
    read -s -p "Cole seu GitHub Personal Access Token: " GHCR_TOKEN
    echo ""
fi
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
ok "Login no GHCR realizado com sucesso"

# --- 5. Build da imagem ---
log "Iniciando build da imagem (pode levar 20-60 minutos)..."
echo ""
START_TIME=$(date +%s)

docker build \
    --progress=plain \
    --tag "$IMAGE" \
    "$REPO_DIR"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))

echo ""
ok "Build concluído em ${MINUTES}m ${SECONDS}s"

# --- 6. Verificar imagem ---
log "Verificando imagem gerada..."
IMAGE_SIZE=$(docker image inspect "$IMAGE" --format='{{.Size}}' | awk '{printf "%.1fGB", $1/1024/1024/1024}')
ok "Imagem: ${IMAGE} (${IMAGE_SIZE})"

# --- 7. Smoke test rápido ---
log "Rodando smoke test..."
docker run --rm --entrypoint bash "$IMAGE" -c "
echo '  Node: '$(node --version)
echo '  Python: '$(python3 --version)
echo '  Claude: '$(claude --version 2>/dev/null | head -1 || echo 'ok')
echo '  Gemini: '$(gemini --version 2>/dev/null | head -1 || echo 'ok')
echo '  Docker CLI: '$(docker --version)
" && ok "Smoke test aprovado!" || warn "Smoke test falhou — verifique antes de fazer push"

# --- 8. Push para GHCR ---
echo ""
read -p "Fazer push para ${IMAGE}? [s/N] " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    log "Fazendo push da imagem para o GHCR..."
    docker push "$IMAGE"
    echo ""
    ok "Push concluído!"
    ok "Imagem disponível em: https://ghcr.io/empresacontalo/docker_xubuntu"
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  ✅ Imagem publicada com sucesso!${NC}"
    echo -e "${GREEN}  docker pull ${IMAGE}${NC}"
    echo -e "${GREEN}============================================${NC}"
else
    warn "Push cancelado. A imagem está disponível localmente."
fi
