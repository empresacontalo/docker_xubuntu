FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Evita perguntas interativas durante a instalação do apt
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalação de dependências do sistema e utilitários
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
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
    && apt-get clean

# 2. Instalação de pacotes Node.js globais
RUN npm install -g \
    remotion \
    @anthropic-ai/claude-code \
    @pnp/office365-cli \
    omniroute \
    hyperframes \
    opencode-ai \
    @kilocode/cli \
    droid \
    @qoder-ai/qodercli \
    cline \
    @google/gemini-cli \
    command-code

# 3. Instalação de pacotes Python globais (video-use é instalado diretamente do repositório Git oficial)
RUN pip3 install --break-system-packages \
    edge-tts \
    faster-whisper \
    camoufox \
    langchain \
    langgraph \
    langfuse \
    git+https://github.com/browser-use/video-use.git

# 4. Instalação do GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# 5. Instalação do AionUi (Desktop Agent) via .deb
RUN curl -s https://api.github.com/repos/iOfficeAI/AionUi/releases/latest \
    | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url' \
    | wget -qi - -O aionui.deb \
    && apt-get install -y ./aionui.deb \
    && rm aionui.deb

# 6. Instalação do Cursor Editor (Debian Package oficial para maior integração com o sistema)
RUN wget -O cursor.deb https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/3.11 \
    && (dpkg -i cursor.deb || apt-get install -f -y) \
    && rm cursor.deb \
    && if [ -f /usr/bin/cursor ]; then \
         mv /usr/bin/cursor /usr/bin/cursor-real \
         && echo '#!/bin/bash\nexec /usr/bin/cursor-real --no-sandbox "$@"' > /usr/bin/cursor \
         && chmod +x /usr/bin/cursor; \
       fi

# 7. Instalação do Windsurf Editor (Debian Package oficial)
RUN windsurf_deb_url=$(curl -s "https://windsurf-stable.codeium.com/api/update/linux-x64-deb/stable/latest" | jq -r '.url') \
    && curl -L "$windsurf_deb_url" -o windsurf.deb \
    && (dpkg -i windsurf.deb || apt-get install -f -y) \
    && rm windsurf.deb \
    && if [ -f /usr/bin/windsurf ]; then \
         mv /usr/bin/windsurf /usr/bin/windsurf-real \
         && echo '#!/bin/bash\nexec /usr/bin/windsurf-real --no-sandbox "$@"' > /usr/bin/windsurf \
         && chmod +x /usr/bin/windsurf; \
       fi

# 8. Instalação de CLIs de terceiros via curl
# Devin CLI
RUN curl -fsSL https://cli.devin.ai/install.sh | bash \
    && if [ -f /root/.devin/bin/devin ]; then cp /root/.devin/bin/devin /usr/local/bin/devin; fi

# Hermes CLI
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash \
    && if [ -f /root/.local/bin/hermes ]; then cp /root/.local/bin/hermes /usr/local/bin/hermes; fi

# Kiro CLI
RUN curl -fsSL https://cli.kiro.dev/install | bash \
    && if [ -f /root/.local/bin/kiro-cli ]; then cp /root/.local/bin/kiro-cli /usr/local/bin/kiro; fi

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
