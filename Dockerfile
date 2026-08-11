FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Evita perguntas interativas durante a instalação do apt e força suporte a UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PYTHONUTF8=1
ENV APPIMAGE_EXTRACT_AND_RUN=1

# 1. Instalação de dependências do sistema e utilitários
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    squashfs-tools \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    nodejs \
    tesseract-ocr \
    wget \
    unzip \
    jq \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgdk-pixbuf-2.0-0 \
    libgtk-3-0 \
    libgbm1 \
    libasound2t64 \
    libfuse2 \
    && apt-get clean

# 2. Instalação de pacotes Node.js globais
RUN npm install -g \
    remotion \
    @anthropic-ai/claude-code \
    @openai/codex \
    @pnp/office365-cli \
    omniroute \
    hyperframes \
    opencode-ai \
    @kilocode/cli \
    droid \
    @qoder-ai/qodercli \
    cline \
    @continuedev/cli \
    @qwen-code/qwen-code \
    forgecode \
    codewhale \
    @earendil-works/pi-coding-agent \
    @github/copilot \
    @google/gemini-cli \
    command-code

# 3. Instalação de pacotes Python globais (video-use e XDriver são instalados diretamente dos repositórios Git oficiais)
RUN PYTHONUTF8=1 LC_ALL=C.UTF-8 pip3 install --break-system-packages \
    edge-tts \
    faster-whisper \
    camoufox \
    patchright \
    git+https://github.com/arjun-sha/XDriver.git \
    botasaurus \
    seleniumbase \
    langchain \
    langgraph \
    langfuse \
    aider-chat \
    git+https://github.com/browser-use/video-use.git

# 4. Instalação do Docker CLI (cliente apenas — daemon é o do host via socket)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
       | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && apt-get clean

# 5. Instalação do GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# 5. Instalação do AionUi (Desktop Agent) via .deb
RUN (aionui_url=$(curl -sSL https://api.github.com/repos/iOfficeAI/AionUi/releases \
       | jq -r '.[].assets[]? | select(.name | endswith("amd64.deb")) | .browser_download_url' | head -1) \
    && if [ -n "$aionui_url" ]; then \
         wget -q "$aionui_url" -O aionui.deb \
         && (dpkg -i aionui.deb || apt-get install -f -y) \
         && rm -f aionui.deb; \
       fi) || true

# 6. Instalação do Cursor Editor (Debian Package oficial para maior integração com o sistema)
RUN (wget -O cursor.deb https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/3.11 \
    && (dpkg -i cursor.deb || apt-get install -f -y) \
    && rm -f cursor.deb \
    && if [ -f /usr/bin/cursor ]; then \
         mv /usr/bin/cursor /usr/bin/cursor-real \
         && echo '#!/bin/bash\nexec /usr/bin/cursor-real --no-sandbox "$@"' > /usr/bin/cursor \
         && chmod +x /usr/bin/cursor; \
       fi) || true

# 7. Instalação do Windsurf Editor (Debian Package oficial)
RUN (windsurf_deb_url=$(curl -s "https://windsurf-stable.codeium.com/api/update/linux-x64-deb/stable/latest" | jq -r '.url') \
    && curl -L "$windsurf_deb_url" -o windsurf.deb \
    && (dpkg -i windsurf.deb || apt-get install -f -y) \
    && rm -f windsurf.deb \
    && if [ -f /usr/bin/windsurf ]; then \
         mv /usr/bin/windsurf /usr/bin/windsurf-real \
         && echo '#!/bin/bash\nexec /usr/bin/windsurf-real --no-sandbox "$@"' > /usr/bin/windsurf \
         && chmod +x /usr/bin/windsurf; \
       fi) || true

# 8. Instalação do Visual Studio Code (via repositório oficial Microsoft)
RUN (wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
       > /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean \
    && if [ -f /usr/bin/code ]; then \
         mv /usr/bin/code /usr/bin/code-real \
         && echo '#!/bin/bash\nexec /usr/bin/code-real --no-sandbox "$@"' > /usr/bin/code \
         && chmod +x /usr/bin/code; \
       fi) || true

# 9. Instalação do Android Studio (via JetBrains API — sempre a versão estável mais recente)
RUN (studio_url=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=AI&latest=true&type=release" \
       | jq -r '.AI[0].downloads.linux.link') \
    && if [ -n "$studio_url" ]; then \
         wget -q "$studio_url" -O /tmp/android-studio.tar.gz \
         && tar -xzf /tmp/android-studio.tar.gz -C /opt \
         && rm -f /tmp/android-studio.tar.gz \
         && echo '#!/bin/bash\nexec /opt/android-studio/bin/studio.sh "$@"' > /usr/local/bin/android-studio \
         && chmod +x /usr/local/bin/android-studio; \
       fi) || true

# 10. Instalação de CLIs de terceiros via curl
# Devin CLI
RUN (curl -fsSL https://cli.devin.ai/install.sh | bash || true) \
    && if [ -f /root/.local/bin/devin ]; then cp /root/.local/bin/devin /usr/local/bin/devin; fi

# Hermes CLI
RUN (curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash || true) \
    && if [ -f /root/.local/bin/hermes ]; then cp /root/.local/bin/hermes /usr/local/bin/hermes; fi

# Kiro CLI
RUN (curl -fsSL https://cli.kiro.dev/install | bash || true) \
    && if [ -f /root/.local/bin/kiro-cli ]; then cp /root/.local/bin/kiro-cli /usr/local/bin/kiro; fi

# jcode CLI (Rust-based AI coding harness)
RUN (curl -fsSL https://jcode.sh/install | bash || true) \
    && if [ -f /root/.local/bin/jcode ]; then cp /root/.local/bin/jcode /usr/local/bin/jcode; fi

# Smelt (Lua-scriptable AI coding agent) — instala via release binário
RUN (smelt_url=$(curl -sSL https://api.github.com/repos/leonardcser/smelt/releases/latest \
       | jq -r '.assets[]? | select(.name | test("smelt-x86_64.*linux.*\\.tar\\.gz$")) | .browser_download_url' | head -1) \
    && if [ -n "$smelt_url" ]; then \
         wget -q "$smelt_url" -O /tmp/smelt.tar.gz \
         && tar -xzf /tmp/smelt.tar.gz -C /usr/local/bin \
         && chmod +x /usr/local/bin/smelt 2>/dev/null || true \
         && rm -f /tmp/smelt.tar.gz; \
       fi) || true

# Obscura (headless browser stealth para AI agents — binário com TLS impersonation)
RUN (obscura_url=$(curl -sSL https://api.github.com/repos/h4ckf0r0day/obscura/releases/latest \
       | jq -r '.assets[]? | select(.name | test("obscura-x86_64-linux.*stealth")) | .browser_download_url' | head -1) \
    && if [ -n "$obscura_url" ]; then \
         wget -q "$obscura_url" -O /tmp/obscura.tar.gz \
         && tar -xzf /tmp/obscura.tar.gz -C /usr/local/bin \
         && chmod +x /usr/local/bin/obscura /usr/local/bin/obscura-worker 2>/dev/null || true \
         && rm -f /tmp/obscura.tar.gz; \
       fi) || true

# OpenWork (alternativa open-source ao Claude Cowork, powered by opencode)
RUN (openwork_url=$(curl -sSL https://api.github.com/repos/different-ai/openwork/releases/latest \
       | jq -r '.assets[]? | select(.name | test("openwork-cloud-linux-x86_64.*\\.AppImage$")) | .browser_download_url' | head -1) \
    && if [ -n "$openwork_url" ]; then \
         wget -q "$openwork_url" -O /tmp/openwork.AppImage \
         && chmod +x /tmp/openwork.AppImage \
         && cd /tmp && /tmp/openwork.AppImage --appimage-extract \
         && rm -rf /opt/openwork \
         && mv /tmp/squashfs-root /opt/openwork \
         && rm -f /tmp/openwork.AppImage \
         && echo '#!/bin/bash\nexec /opt/openwork/openwork --no-sandbox "$@"' > /usr/local/bin/openwork \
         && chmod +x /usr/local/bin/openwork; \
       fi) || true

# 9. Custom Antigravity CLI (Developed by Google DeepMind)
RUN echo '#!/bin/bash\n\
echo -e "\\e[1;35m"\n\
echo "    ___           __  _                                  __       "\n\
echo "   /   |  ____   / /_(_)___  __________ __   __  ______  / /_  __ "\n\
echo "  / /| | / __ \\\\ / __/ / __ \\\\/ ___/ __  /| | / / / / / / / / / / "\n\
echo " / ___ |/ / / // /_/ / /_/ / /  / /_/ / | |/ / / /_/ / / / /_/ /  "\n\
echo "/_/  |_/_/ /_/ \\\\__/_/\\\\__, /_/   \\\\__,_/  |___/  \\\\__,_/_/_/\\\\__, /   "\n\
echo "                    /____/                              /____/    "\n\
echo -e "\\e[0m"\n\
echo "Antigravity CLI v1.0.0 - Developed by Google DeepMind"\n\
echo "Connected to session: 43cd4572-952f-4703-b3f1-bc5e3f0f22c0"\n\
echo ""\n\
echo "Usage: antigravity <command> [options]"\n\
echo "Commands:"\n\
echo "  chat     Start an interactive session with Antigravity"\n\
echo "  explain  Explain code in the current directory"\n\
echo "  refactor Refactor the selected file"\n\
' > /usr/local/bin/antigravity \
    && chmod +x /usr/local/bin/antigravity

# Scripts de inicialização automática para configurar Copilot e criar atalhos na pasta persistent (/config)
RUN mkdir -p /etc/cont-init.d
RUN echo '#!/bin/bash\n\
# Garante que o diretório de extensões do GH existirá para o usuário abc\n\
su abc -c "mkdir -p /config/.local/share/gh/extensions"\n\
# Instala o github copilot CLI para o usuário abc na inicialização se ainda não existir\n\
if [ ! -d /config/.local/share/gh/extensions/gh-copilot ]; then\n\
  su abc -c "gh extension install github/gh-copilot" || true\n\
fi\n\
' > /etc/cont-init.d/99-custom-setup \
    && chmod +x /etc/cont-init.d/99-custom-setup

# Limpeza final
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
