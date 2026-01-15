# Kannika Armory Examples

A collection of examples for Kannika Armory https://kannika.io

## Getting Started

### Setup Kannika Armory on Kind

Quickly set up Kannika Armory on a local Kubernetes cluster using kind (Kubernetes IN Docker).

```bash
./setup-kannika-armory.sh
```

For detailed instructions, see [SETUP.md](SETUP.md).

## Contents

- **setup-kannika-armory.sh** - Automated setup script for installing Kannika Armory on a kind cluster
- **SETUP.md** - Comprehensive guide for setting up and using Kannika Armory locally
- **docker-compose.yml** - Two Kafka clusters setup for simulating migrations
- **KAFKA.md** - Guide for using the Kafka migration environment
- **scripts/** - Optional installation scripts for kind, kubectl, and helm

## Prerequisites

- Docker
- kind (or use `./scripts/install-kind.sh`)
- kubectl v1.28+ (or use `./scripts/install-kubectl.sh`)
- helm v3.9+ (or use `./scripts/install-helm.sh`)

## Resources

- [Kannika Documentation](https://docs.kannika.io/)
- [Kannika Installation Guide](https://docs.kannika.io/installation/)

## Kafka Migration Setup

To set up two Kafka clusters for testing migrations, see [KAFKA.md](KAFKA.md).

```bash
docker-compose up -d
```

