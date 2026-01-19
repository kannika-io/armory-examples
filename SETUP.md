# Setup Guide

This guide provides detailed instructions for setting up Kannika Armory on a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/).

## Prerequisites

Before running setup, ensure you have the following:

1. **Docker** - Container runtime
   - [Installation Guide](https://docs.docker.com/get-docker/)
   - Verify: `docker --version`

2. **kind** - Kubernetes IN Docker
   - [Installation Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
   - Verify: `kind --version`

3. **kubectl** - Kubernetes CLI (v1.28+)
   - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
   - Verify: `kubectl version --client`

4. **helm** - Kubernetes package manager (v3.9+)
   - [Installation Guide](https://helm.sh/docs/intro/install/)
   - Verify: `helm version`

Install kind, kubectl, and helm locally (to `.bin`, git-ignored):

```bash
./setup tools
```

## Quick Start

Run a tutorial (sets up everything automatically):

```bash
./setup <TUTORIAL>
```

Or run without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/kannika-io/armory-examples/main/install.sh \
  | bash -s -- <TUTORIAL>
```

## Commands

```bash
./setup <TUTORIAL>    # Run a tutorial (Armory + Kafka + tutorial resources)
./setup armory        # Set up Kannika Armory only (Kind + Helm)
./setup kafka         # Set up Kafka clusters only (docker-compose)
./setup tools         # Install kind, kubectl, helm to .bin
./setup list          # List available tutorials
./teardown            # Delete Kind cluster and stop Kafka
```

## Setup Modes

### Running a Tutorial

```bash
./setup <TUTORIAL>
```

This will:
1. Create a Kind cluster with Kannika Armory
2. Start source and target Kafka clusters
3. Connect Kind to the Kafka network
4. Initialize tutorial-specific resources
5. Print access URLs and credentials

### Armory Only

Set up just Kannika Armory without Kafka:

```bash
./setup armory
```

Options can be passed through:

```bash
./setup armory --version 0.13.0 --license /path/to/license.key
```

### Kafka Only

Set up just the Kafka clusters:

```bash
./setup kafka
```

If a Kind cluster is detected, you'll be prompted to connect them.

## Services

After setup, services are available at:

| Component | Service | URL |
|-----------|---------|-----|
| Kannika Armory | Console | http://localhost:8080 |
| Kannika Armory | API | http://localhost:8081 |
| Kafka Source | Broker | localhost:9092 |
| Kafka Source | Console | http://localhost:8180 |
| Kafka Target | Broker | localhost:9093 |
| Kafka Target | Console | http://localhost:8181 |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLUSTER_NAME` | `kannika-kind` | Kind cluster name |
| `KANNIKA_VERSION` | `0.13.0` | Kannika version to install |
| `KANNIKA_SYSTEM_NS` | `kannika-system` | System namespace |
| `KANNIKA_DATA_NS` | `kannika-data` | Data namespace |
| `LICENSE_PATH` | - | Path to license file |

### Armory Options

When running `./setup armory`, you can pass options:

```bash
./setup armory --cluster my-cluster --version 0.13.0
./setup armory --license /path/to/license.key
./setup armory --namespace kannika-system --data-namespace kannika-data
```

| Option | Description |
|--------|-------------|
| `-c, --cluster` | Kind cluster name |
| `-v, --version` | Kannika version |
| `-n, --namespace` | System namespace |
| `-d, --data-namespace` | Data namespace |
| `-l, --license` | License file path |

### Kind Cluster Configuration

The setup uses `kind-config.yaml` in the repository root, which configures port mappings:
- Port 8080 → Kannika Console (NodePort 30080)
- Port 8081 → Kannika API (NodePort 30081)

To add worker nodes, modify `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
    - containerPort: 30080
      hostPort: 8080
      protocol: TCP
    - containerPort: 30081
      hostPort: 8081
      protocol: TCP
- role: worker
- role: worker
```

## Licensing

If you didn't provide a license during setup, you can add one later.

Get a free license at: https://www.kannika.io/free-trial

```bash
kubectl create secret generic kannika-license \
  --namespace kannika-system \
  --from-file=license=/path/to/license.key \
  --type=kannika.io/license
```

## Teardown

Remove everything:

```bash
./teardown
```

This deletes the Kind cluster and stops Kafka containers.

To remove only specific components:

```bash
# Delete Kind cluster only
kind delete cluster --name kannika-kind

# Stop Kafka only
docker-compose down -v
```

## Troubleshooting

### Docker Not Running

```
Docker is not running. Please start Docker and try again.
```

- macOS/Windows: Start Docker Desktop
- Linux: `sudo systemctl start docker`

### Cluster Already Exists

The setup skips cluster creation if it already exists. To start fresh:

```bash
./teardown
./setup <command>
```

### Installation Timeout

Check pod status:

```bash
kubectl get pods -n kannika-system
kubectl describe pod <pod-name> -n kannika-system
kubectl logs -n kannika-system <pod-name>
```

### Kafka Connection Issues

Verify the Kind cluster is connected to the Kafka network:

```bash
docker network inspect kafka
```

Reconnect if needed:

```bash
./scripts/connect-kafka-to-kind.sh
```

### Missing Tools

Install locally with:

```bash
./setup tools
```

Or install system-wide following the links in [Prerequisites](#prerequisites).

## Resources

- [Kannika Documentation](https://docs.kannika.io/)
- [Kannika Installation Guide](https://docs.kannika.io/installation/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Free Trial License](https://kannika.io/free-trial)
