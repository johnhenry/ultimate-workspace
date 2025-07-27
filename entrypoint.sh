#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[entrypoint] $1"
}

log "Starting Ultimate JavaScript Development Workspace initialization..."

# Parallel initialization for independent configurations
{
    # Configure SSH public key if provided
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        log "Configuring SSH public key authentication..."
        mkdir -p /home/developer/.ssh
        echo "$SSH_PUBLIC_KEY" > /home/developer/.ssh/authorized_keys
        chmod 700 /home/developer/.ssh
        chmod 600 /home/developer/.ssh/authorized_keys
        chown -R developer:developer /home/developer/.ssh
    fi
} &

{
    # Set up API keys in parallel
    if [ -n "$CLAUDE_API_KEY" ]; then
        log "Configuring Claude API key..."
        echo "export CLAUDE_API_KEY=$CLAUDE_API_KEY" >> /home/developer/.bashrc
        export CLAUDE_API_KEY=$CLAUDE_API_KEY
    fi

    if [ -n "$GEMINI_API_KEY" ]; then
        log "Configuring Gemini API key..."
        echo "export GEMINI_API_KEY=$GEMINI_API_KEY" >> /home/developer/.bashrc
        export GEMINI_API_KEY=$GEMINI_API_KEY
    fi

    # Set up Qwen API configuration if provided
    if [ -n "$QWEN_API_KEY" ]; then
        log "Configuring Qwen API key..."
        echo "export OPENAI_API_KEY=$QWEN_API_KEY" >> /home/developer/.bashrc
        export OPENAI_API_KEY=$QWEN_API_KEY
    fi

    if [ -n "$QWEN_BASE_URL" ]; then
        log "Configuring Qwen base URL..."
        echo "export OPENAI_BASE_URL=$QWEN_BASE_URL" >> /home/developer/.bashrc
        export OPENAI_BASE_URL=$QWEN_BASE_URL
    fi

    if [ -n "$QWEN_MODEL" ]; then
        log "Configuring Qwen model..."
        echo "export OPENAI_MODEL=$QWEN_MODEL" >> /home/developer/.bashrc
        export OPENAI_MODEL=$QWEN_MODEL
    fi
} &

# Set Code Server password (needs to be synchronous)
if [ -z "$CODE_SERVER_PASSWORD" ]; then
    CODE_SERVER_PASSWORD=$(openssl rand -base64 32)
    log "Generated Code Server password: $CODE_SERVER_PASSWORD"
else
    log "Using provided Code Server password"
fi
export CODE_SERVER_PASSWORD

# Configure Code Server
mkdir -p /home/developer/.config/code-server
cat > /home/developer/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:8081
auth: password
password: $CODE_SERVER_PASSWORD
cert: false
EOF
chown -R developer:developer /home/developer/.config

# Configure Tailscale if auth key provided (background process)
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    {
        log "Configuring Tailscale..."
        # Start tailscaled in background to allow auth
        /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
        sleep 5
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="js-workspace"
        # Kill the background tailscaled as supervisor will manage it
        pkill tailscaled || true
    } &
fi

# Create necessary directories
{
    mkdir -p /var/run/tailscale /var/lib/tailscale
    chmod 755 /var/run/tailscale /var/lib/tailscale
} &

# Set up Python environment variables
{
    echo "export PATH=/opt/conda/bin:\$PATH" >> /home/developer/.bashrc
    echo "export CONDA_DIR=/opt/conda" >> /home/developer/.bashrc
} &

# Ensure workspace directory has correct permissions
chown -R developer:developer /workspace

# Create log directory with correct permissions
mkdir -p /var/log/supervisor
chmod 755 /var/log/supervisor

# Initialize conda for the developer user (background)
{
    su - developer -c "conda init bash" 2>/dev/null || true
} &

# Wait for all background processes to complete
wait

# Quick health check function (only log failures)
quick_health_check() {
    local failures=()
    
    # Check critical services with timeout
    timeout 2 nc -z localhost 2222 2>/dev/null || failures+=("SSH:2222")
    timeout 2 docker version >/dev/null 2>&1 || failures+=("Docker")
    
    if [ ${#failures[@]} -gt 0 ]; then
        log "WARNING: Some services may not be ready: ${failures[*]}"
    else
        log "Core services initialized successfully"
    fi
}

# Create welcome message
cat > /workspace/WELCOME.md <<'EOF'
# Welcome to Ultimate JavaScript Development Workspace

## Services Available

- **SSH Server**: Port 2222
- **Claude Code UI**: http://localhost:8080
- **Code Server**: http://localhost:8081 (Password: check logs or set CODE_SERVER_PASSWORD)
- **VS Code Server**: http://localhost:8082
- **Copy Party**: http://localhost:8083 (File sharing and management)
- **Docker**: Available inside container
- **Tailscale**: VPN networking (configure with TAILSCALE_AUTHKEY)

## JavaScript Runtimes

- **Node.js**: Managed via NVM (default: v22)
- **Deno**: v2.4 installed
- **Bun**: v1.2.17 installed

## Python Development

- **Python**: v3.13 installed
- **Package Managers**: pip, pipx, conda, uv/uvx
- **Development Tools**: ruff, pyright, poetry, virtualenv, ipython
- **Conda**: Miniconda installed at /opt/conda

## Development Tools

- **Claude Code CLI**: Available as `claude` command
- **Qwen Code CLI**: Available as `qwen` command (requires API configuration)
- **Gemini CLI**: Placeholder installed (replace with actual when available)
- **Git**: Latest version
- **Docker**: Docker-in-Docker enabled
- **Tailscale**: Mesh VPN for secure networking
- **Copy Party**: Web-based file manager and sharing

## Environment Variables

Set these when running the container:
- `SSH_PUBLIC_KEY`: Your SSH public key for authentication
- `CLAUDE_API_KEY`: API key for Claude Code CLI
- `GEMINI_API_KEY`: API key for Gemini CLI
- `QWEN_API_KEY`: API key for Qwen Code CLI
- `QWEN_BASE_URL`: Base URL for Qwen API (default: Alibaba Cloud)
- `QWEN_MODEL`: Qwen model to use (default: qwen3-coder-plus)
- `CODE_SERVER_PASSWORD`: Password for Code Server (auto-generated if not set)
- `NODE_VERSION`: Default Node.js version (default: 22)
- `PYTHON_VERSION`: Python version (default: 3.13)
- `TAILSCALE_AUTHKEY`: Tailscale authentication key

## Getting Started

1. Access Code Server at http://localhost:8081 with the password from logs
2. SSH into the container: `ssh developer@localhost -p 2222`
3. All development happens in `/workspace` directory

## Python Quick Start

```bash
# Create virtual environment
python -m venv myenv
source myenv/bin/activate

# Use uv for fast package installation
uv pip install requests numpy pandas

# Use conda for scientific computing
conda create -n science python=3.13 numpy scipy matplotlib
conda activate science

# Lint and format code
ruff check .
ruff format .
```

## Networking with Tailscale

If TAILSCALE_AUTHKEY is provided, the container will automatically connect to your Tailscale network.
You can then access all services through your Tailscale IP without port forwarding.

## Troubleshooting

Check service logs: `docker logs <container-name>`
Check individual service logs in: `/var/log/supervisor/`
Tailscale status: `tailscale status`
EOF

chown developer:developer /workspace/WELCOME.md

log "Initialization complete. Starting supervisord..."

# Run quick health check after a short delay (background)
(sleep 10 && quick_health_check) &

# Execute the command passed to the container
exec "$@"