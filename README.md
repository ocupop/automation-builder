# Ocupop Automation AI

- Modules are in develop right now

```
# To Pull
git pull --recurse-submodules

# Once pulled pull the submodules
git submodule update --init --recursive --progress
```

**Quick Start**

1. Run the starter kit fully on CPU:

   ```bash
   python start_services.py --profile cpu
   ```

2. Run Ollama on your Mac for faster inference, and connect to that from the n8n instance:
   ```bash
   python start_services.py --profile none
   ```

[Local AI Package Repo](https://github.com/coleam00/local-ai-packaged)

**Connect via command line to psql**

```bash
psql 'postgres://postgres.<POOLER_TENANT_ID>:<POSTGRES_PASSWORD>@localhost:5432/postgres'
```

**Start Each Service Individually**

```bash
# Supabase
docker compose -p localai -f supabase/docker/docker-compose.yml up -d

# Self-hosted AI Package
docker compose -p localai -f lib/local-ai-packaged/docker-compose.yml up -d

# Base Services
docker compose -p localai -f docker-compose.yml up -d
```

**To stop all services**

```bash
docker compose -p localai down
```
