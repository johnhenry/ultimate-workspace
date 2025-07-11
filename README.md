# Ultimate JavaScript Development Workspace

A comprehensive Docker-based development environment featuring multiple JavaScript runtimes, web-based IDEs, and AI-powered development tools.

## Features

### JavaScript Runtimes
- **Node.js** (via NVM) - Default v22 LTS, configurable
- **Deno** - v2.4 for secure TypeScript/JavaScript runtime
- **Bun** - v1.2.17 for fast all-in-one JavaScript runtime

### Python Development
- **Python 3.13** - Latest stable Python version
- **Package Managers**: pip, pipx, conda (Miniconda), uv/uvx
- **Development Tools**: ruff, pyright, poetry, virtualenv, ipython
- **Scientific Computing**: Full conda ecosystem support

### Development Tools
- **Claude Code CLI** - AI-powered coding assistant
- **Claude Code UI** - Web interface for Claude Code
- **Gemini CLI** - Google's AI assistant (placeholder)
- **Git** - Latest version
- **Docker-in-Docker** - Run containers inside the workspace

### Web-Accessible IDEs
- **Code Server** (Port 8081) - VS Code in the browser
- **VS Code Server** (Port 8082) - Alternative VS Code instance
- **Claude Code UI** (Port 8080) - AI coding interface

### System Features
- **SSH Server** (Port 2222) - Secure remote access
- **Supervisor** - Process management
- **Ubuntu 22.04 LTS** - Stable base system
- **Tailscale** - Mesh VPN for secure networking
- **Webmin** (Port 10000) - Web-based system administration

## Quick Start

### Using Docker Compose (Recommended)

1. Clone this repository:
```bash
git clone <repository-url>
cd ultimate-workspace
```

2. Create a `.env` file with your configuration:
```bash
# Required for SSH access
SSH_PUBLIC_KEY="your-ssh-public-key-here"

# API Keys (optional)
CLAUDE_API_KEY="your-claude-api-key"
GEMINI_API_KEY="your-gemini-api-key"

# Code Server password (auto-generated if not set)
CODE_SERVER_PASSWORD="your-secure-password"

# Node.js version (default: 22)
NODE_VERSION=22

# Python version (default: 3.13)
PYTHON_VERSION=3.13

# Tailscale auth key (optional)
TAILSCALE_AUTHKEY="your-tailscale-auth-key"

# Webmin password (default: webmin)
WEBMIN_PASSWORD="your-secure-password"
```

3. Start the container:
```bash
docker-compose up -d
```

4. Access the services:
- Code Server: http://localhost:8081
- VS Code Server: http://localhost:8082
- Claude Code UI: http://localhost:8080
- Webmin: http://localhost:10000 (root/webmin or your password)
- SSH: `ssh developer@localhost -p 2222`

### Using Docker CLI

```bash
docker build -t ultimate-js-workspace .

docker run -d \
  --name js-workspace \
  --privileged \
  -p 2222:2222 \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -v $(pwd)/workspace:/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  -e CLAUDE_API_KEY="your-api-key" \
  -e CODE_SERVER_PASSWORD="your-password" \
  ultimate-js-workspace
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SSH_PUBLIC_KEY` | SSH public key for authentication | None |
| `CLAUDE_API_KEY` | API key for Claude Code CLI | None |
| `GEMINI_API_KEY` | API key for Gemini CLI | None |
| `CODE_SERVER_PASSWORD` | Password for Code Server | Auto-generated |
| `NODE_VERSION` | Default Node.js version | 22 |
| `PYTHON_VERSION` | Python version | 3.13 |
| `TAILSCALE_AUTHKEY` | Tailscale authentication key | None |
| `WEBMIN_PASSWORD` | Webmin admin password | webmin |
| `CONDA_ENV` | Default conda environment | base |

### Volumes

| Path | Description |
|------|-------------|
| `/workspace` | Main development directory |
| `/home/developer` | User home directory |
| `/var/run/docker.sock` | Docker socket for DinD |
| `/var/lib/tailscale` | Tailscale state persistence |
| `/opt/conda/pkgs` | Conda package cache |

### Ports

| Port | Service |
|------|---------|
| 2222 | SSH Server |
| 8080 | Claude Code UI |
| 8081 | Code Server |
| 8082 | VS Code Server |
| 10000 | Webmin |
| 2375 | Docker Daemon (optional) |

## Usage Examples

### SSH Access
```bash
# Add your SSH key to the container
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"

# Connect via SSH
ssh developer@localhost -p 2222
```

### Using JavaScript Runtimes
```bash
# Inside the container
node --version      # Node.js via NVM
deno --version      # Deno
bun --version       # Bun

# Switch Node versions
nvm install 20
nvm use 20
```

### Using Claude Code CLI
```bash
# Inside the container (requires CLAUDE_API_KEY)
claude "Write a hello world Express server"
```

### Python Development
```bash
# Use uv for fast package management
uv pip install fastapi uvicorn
uv pip sync requirements.txt

# Use conda for data science
conda create -n ml python=3.13 scikit-learn pandas jupyter
conda activate ml

# Lint and format with ruff
ruff check --fix .
ruff format .

# Type check with pyright
pyright
```

### Docker-in-Docker
```bash
# Inside the container
docker run hello-world
docker build -t myapp .
```

### Tailscale Networking
```bash
# Check Tailscale status
tailscale status

# Access services via Tailscale IP (no port forwarding needed)
# Example: http://100.x.x.x:8081 for Code Server
```

### System Administration with Webmin
Access Webmin at http://localhost:10000
- Manage users and groups
- Configure system services
- Monitor system resources
- Manage Docker containers
- Configure firewall rules

## Security Considerations

1. **SSH Access**: Only public key authentication is enabled
2. **Passwords**: Set strong passwords for Code Server
3. **API Keys**: Never commit API keys to version control
4. **Privileged Mode**: Required for Docker-in-Docker but use with caution
5. **Network**: Consider using custom networks for isolation

## Troubleshooting

### Check Service Status
```bash
docker exec js-workspace supervisorctl status
```

### View Logs
```bash
# Container logs
docker logs js-workspace

# Individual service logs
docker exec js-workspace tail -f /var/log/supervisor/code-server.stdout.log
```

### Common Issues

1. **Code Server password not working**
   - Check logs for the generated password
   - Set `CODE_SERVER_PASSWORD` environment variable

2. **SSH connection refused**
   - Ensure `SSH_PUBLIC_KEY` is set correctly
   - Check SSH service status

3. **Docker commands not working**
   - Ensure container is running with `--privileged` flag
   - Check Docker daemon logs

## Advanced Configuration

### Custom Node.js Versions
```dockerfile
# In Dockerfile
ARG NODE_VERSION=20
# Rebuild with: docker-compose build --build-arg NODE_VERSION=20
```

### Additional VS Code Extensions
```bash
# Inside container
code-server --install-extension <extension-id>
```

### Persistent Configuration
Mount additional volumes for persistence:
```yaml
volumes:
  - ./config/code-server:/home/developer/.config/code-server
  - ./config/ssh:/home/developer/.ssh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and development purposes.

## Acknowledgments

- [Code Server](https://github.com/coder/code-server)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Node Version Manager](https://github.com/nvm-sh/nvm)
- [Deno](https://deno.land/)
- [Bun](https://bun.sh/)