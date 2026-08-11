FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Evita perguntas interativas durante a instalação do apt
ENV DEBIAN_FRONTEND=noninteractive

# Instalação de dependências absolutamente básicas e seguras
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    wget \
    unzip \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configuração de permissões e diretórios padrão do linuxserver
RUN chmod 1777 /tmp
