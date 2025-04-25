# Ocupop Automation AI

A comprehensive automation platform that integrates various AI services to streamline workflows and enhance productivity.

## Setup

### Requirements

- [Python](https://www.python.org/downloads/) (3.8 or higher) - Required to run the setup script
- [Git/GitHub Desktop](https://desktop.github.com/) - For easy repository management
- [Docker/Docker Desktop](https://www.docker.com/products/docker-desktop/) - Required to run all services
- Minimum 8GB RAM recommended for running all services

### Installation

```bash
# Clone the repository
git clone https://github.com/ocupop/automation-builder.git
cd automation-builder

# Initialize and update submodules
git submodule update --init --recursive --progress
```

### Quick Start

1. Run the starter kit fully on CPU (recommended for most systems):
   ```bash
   python start_services.py --profile cpu
   ```

2. Run Ollama on your Mac for faster inference, and connect to that from the n8n instance:
   ```bash
   python start_services.py --profile none
   ```

3. Wait for all services to initialize (this may take a few minutes on first run)

### Updating Services
```
docker compose -p localai -f docker-compose.yml -f supabase/docker/docker-compose.yml -f lib/local-ai-packaged/docker-compose.yml pull
```

### Environment Configuration

The platform uses various environment variables for configuration. A default `.env` file is provided, but you may need to customize it for your specific needs:

- `N8N_HOST` - Hostname for n8n service
- `N8N_PROTOCOL` - Protocol for n8n (http/https)
- `N8N_WEBHOOK_URL` - URL for n8n webhooks
- `N8N_WEBHOOK_TEST_URL` - Test URL for n8n webhooks
- `WEBHOOK_TUNNEL_URL` - Optional tunnel URL for webhooks
- `N8N_BASIC_AUTH` - Optional basic auth settings for n8n

## Services

The Automation AI platform integrates several key services:

### Supabase
A PostgreSQL database with authentication and real-time capabilities, used for data storage and management.

### n8n
Workflow automation tool running on port 5678, with webhook functionality for triggering workflows from external sources. Data is persisted in the `n8n_data` Docker volume.

### Flowise
Low-code AI workflow builder that integrates with n8n for complex automation scenarios.

### SearXNG
Privacy-focused metasearch engine that aggregates results from multiple search services.

### Local AI Services
Self-hosted AI models for various tasks, configured through the profile settings.

## Contribution

We welcome contributions to improve the Automation AI platform:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the project's coding standards and includes appropriate documentation.

## Troubleshooting

### Starting Services Individually

If you encounter issues with the main startup script, you can start each service individually:

```bash
# Supabase
docker compose -p automation_ai -f supabase/docker/docker-compose.yml up -d

# Self-hosted AI Package
docker compose -p automation_ai -f lib/local-ai-packaged/docker-compose.yml up -d

# Base Services
docker compose -p automation_ai -f docker-compose.yml up -d
```

### Stopping Services

To stop all services:
```bash
docker compose -p automation_ai down
```

### Common Issues

1. **Docker Memory Issues**: If Docker crashes or services fail to start, try increasing the memory allocation in Docker Desktop settings.

2. **Port Conflicts**: Ensure the required ports (5678 for n8n, etc.) are not already in use by other applications.

3. **Submodule Issues**: If you encounter problems with submodules, try:
   ```bash
   git submodule update --init --recursive --force
   ```

4. **SearXNG Configuration**: If SearXNG fails to start, check that the symlink from `lib/local-ai-packaged/searxng` to the root directory is correctly set up.
