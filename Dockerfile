# Ultimate JavaScript Development Workspace
FROM ubuntu:22.04

# Build arguments
ARG NODE_VERSION=22
ARG CODE_SERVER_VERSION=4.101.2
ARG CLAUDE_CODE_VERSION=1.0.48
ARG DENO_VERSION=2.4
ARG BUN_VERSION=1.2.17
ARG NVM_VERSION=0.40.3
ARG PYTHON_VERSION=3.13
ARG MINICONDA_VERSION=py313_24.7.1-0
ARG UV_VERSION=0.7.20
ARG RUFF_VERSION=0.12.0

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    USER=developer \
    USER_UID=1000 \
    USER_GID=1000 \
    HOME=/home/developer \
    NVM_DIR=/home/developer/.nvm \
    NODE_VERSION=${NODE_VERSION} \
    PYTHON_VERSION=${PYTHON_VERSION} \
    CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH

# Create developer user
RUN groupadd -g ${USER_GID} ${USER} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install base system packages
RUN apt-get update && apt-get install -y \
    # Basic tools
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    jq \
    zip \
    unzip \
    build-essential \
    # Python dependencies
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    libssl-dev \
    libffi-dev \
    # SSH server
    openssh-server \
    # Process management
    supervisor \
    # Docker dependencies
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    # Network tools
    iptables \
    iproute2 \
    # Webmin dependencies
    perl \
    libnet-ssleay-perl \
    openssl \
    libauthen-pam-perl \
    libpam-runtime \
    libio-pty-perl \
    libtime-piece-perl \
    shared-mime-info \
    # Other utilities
    sudo \
    locales \
    tzdata \
    net-tools \
    iputils-ping \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Configure locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install Docker CE for Docker-in-Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
    usermod -aG docker ${USER} && \
    rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install Webmin
RUN wget -q -O- https://download.webmin.com/developers-key.asc | apt-key add - && \
    echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y webmin && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Configure Webmin
RUN sed -i 's/ssl=1/ssl=0/' /etc/webmin/miniserv.conf && \
    echo "allow=0.0.0.0/0" >> /etc/webmin/miniserv.conf && \
    echo "root:webmin" | chpasswd && \
    /etc/webmin/changepass.pl /etc/webmin root webmin

# Install Python from deadsnakes PPA for latest version
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-distutils && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 && \
    rm -rf /var/lib/apt/lists/*

# Install pip for the new Python version
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}

# Install Python development tools as root
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install pipx virtualenv poetry ipython && \
    pipx ensurepath

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx

# Install ruff (Python linter)
RUN curl -LsSf https://astral.sh/ruff/${RUFF_VERSION}/install.sh | sh && \
    mv /root/.local/bin/ruff /usr/local/bin/ruff && \
    chmod +x /usr/local/bin/ruff

# Install pyright (Python type checker)
RUN export NVM_DIR="/home/developer/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    npm install -g pyright

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniconda.sh && \
    ${CONDA_DIR}/bin/conda clean -afy && \
    ln -s ${CONDA_DIR}/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". ${CONDA_DIR}/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    echo "conda activate base" >> /etc/bash.bashrc && \
    chown -R ${USER}:${USER} ${CONDA_DIR}

# Create necessary directories
RUN mkdir -p /workspace /var/log/supervisor ${HOME}/.ssh ${HOME}/.config \
    /var/lib/tailscale /home/developer/.cache && \
    chown -R ${USER}:${USER} /workspace ${HOME} /home/developer/.cache

# Switch to developer user for installations
USER ${USER}
WORKDIR ${HOME}

# Install NVM and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    . ${NVM_DIR}/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm alias default ${NODE_VERSION} && \
    nvm use default && \
    npm install -g yarn pnpm

# Install Deno
RUN curl -fsSL https://deno.land/install.sh | sh -s v${DENO_VERSION} && \
    echo 'export DENO_INSTALL="${HOME}/.deno"' >> ${HOME}/.bashrc && \
    echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ${HOME}/.bashrc

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}" && \
    echo 'export BUN_INSTALL="${HOME}/.bun"' >> ${HOME}/.bashrc && \
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ${HOME}/.bashrc

# Configure shell for NVM and Python tools
RUN echo 'export NVM_DIR="${HOME}/.nvm"' >> ${HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ${HOME}/.bashrc && \
    echo 'export PATH="${HOME}/.local/bin:$PATH"' >> ${HOME}/.bashrc && \
    echo '. ${CONDA_DIR}/etc/profile.d/conda.sh' >> ${HOME}/.bashrc

# Configure pipx for user
RUN pipx ensurepath

# Switch back to root for system installations
USER root

# Install Claude Code CLI from npm (ensure Node.js is in PATH)
RUN export NVM_DIR="/home/developer/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Install Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

# Create directories for web IDEs
RUN mkdir -p /opt/claude-code-ui /opt/vs-code-server

# Download and setup Claude Code UI
RUN cd /opt/claude-code-ui && \
    git clone https://github.com/siteboon/claudecodeui.git . && \
    chown -R ${USER}:${USER} /opt/claude-code-ui

# Setup VS Code Server (using code-server as VS Code Server alternative)
# Note: Official VS Code Server requires tunnel setup, using code-server for web access
RUN mkdir -p /opt/vs-code-server/extensions && \
    chown -R ${USER}:${USER} /opt/vs-code-server

# Install Gemini CLI (placeholder - actual installation depends on availability)
# Since there's no official Gemini CLI from Google, we'll create a placeholder
RUN echo '#!/bin/bash\necho "Gemini CLI placeholder - please install actual CLI when available"' > /usr/local/bin/gemini && \
    chmod +x /usr/local/bin/gemini

# Create supervisord configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
EXPOSE 2222 8080 8081 8082 2375 10000

# Set working directory
WORKDIR /workspace

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]