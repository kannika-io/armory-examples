# Scripts

This directory contains scripts for setting up and managing Kannika Armory on a local Kind cluster.

## Setup Scripts

### setup-kannika-armory.sh

Main setup script that creates a Kind cluster and installs Kannika Armory.

**Usage:**
```bash
./scripts/setup-kannika-armory.sh

# With options
./scripts/setup-kannika-armory.sh --cluster my-cluster --version 0.14.0

# With license
./scripts/setup-kannika-armory.sh --license /path/to/license.key
```

**Options:**
| Option | Environment Variable | Default | Description |
|--------|---------------------|---------|-------------|
| `-c, --cluster` | `CLUSTER_NAME` | `kannika-kind` | Kind cluster name |
| `-v, --version` | `KANNIKA_VERSION` | `0.14.0` | Kannika version |
| `-n, --namespace` | `KANNIKA_SYSTEM_NS` | `kannika-system` | System namespace |
| `-d, --data-namespace` | `KANNIKA_DATA_NS` | `kannika-data` | Data namespace |
| `-l, --license` | `LICENSE_PATH` | - | Path to license file |

### connect-kafka-to-kind.sh

Connects the Kind cluster to the Kafka Docker network, allowing pods to access Kafka clusters.

**Usage:**
```bash
./scripts/connect-kafka-to-kind.sh

# With custom cluster name
./scripts/connect-kafka-to-kind.sh --cluster my-cluster
```

After connection, pods can access:
- Source Kafka: `kafka-source:29092`
- Target Kafka: `kafka-target:29092`

---

## Installation Scripts

Optional scripts for installing prerequisite tools locally without requiring system-wide installation or administrator privileges.

### install-kind.sh
Installs [kind](https://kind.sigs.k8s.io/) (Kubernetes IN Docker) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-kind.sh

# Or specify a custom version
KIND_VERSION=v0.31.0 ./scripts/install-kind.sh
```

**Default version:** v0.31.0

### install-kubectl.sh
Installs [kubectl](https://kubernetes.io/docs/reference/kubectl/) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-kubectl.sh

# Or specify a custom version
KUBECTL_VERSION=v1.31.4 ./scripts/install-kubectl.sh
```

**Default version:** v1.31.4

### install-helm.sh
Installs [helm](https://helm.sh/) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-helm.sh

# Or specify a custom version
HELM_VERSION=v3.17.0 ./scripts/install-helm.sh
```

**Default version:** v3.17.0

## How It Works

- Each script downloads the specified tool for your operating system and architecture
- Tools are installed to the `.bin` directory at the repository root
- The `.bin` directory is git-ignored, so these binaries won't be committed
- The main setup script (`setup-kannika-armory.sh`) automatically detects and uses tools from `.bin` if available

## Using Locally Installed Tools

After running the installation scripts, you can:

1. **Add `.bin` to your PATH** (for the current session):
   ```bash
   export PATH="$(pwd)/.bin:$PATH"
   ```

2. **Use the full path**:
   ```bash
   ./.bin/kind --version
   ./.bin/kubectl version --client
   ./.bin/helm version
   ```

3. **Run the setup script** (which automatically uses `.bin` tools):
   ```bash
   ./setup-kannika-armory.sh
   ```

## Supported Platforms

These scripts support:
- **Operating Systems:** Linux, macOS
- **Architectures:** x86_64 (amd64), aarch64/arm64

## Notes

- To update a tool, simply re-run the installation script with the desired version
- To remove locally installed tools, delete the `.bin` directory: `rm -rf .bin`

---

## Helper Libraries

These scripts are sourced by other scripts and provide reusable functions.

### kafka-helpers.sh

Reusable Kafka helper functions for tutorials. Source this file to use the functions.

**Usage:**
```bash
source scripts/kafka-helpers.sh

# Create a topic
kafka_create_topic kafka-source my-topic 3

# Produce a message
kafka_produce kafka-source my-topic "key1" "value1"

# Produce batch messages
kafka_produce_batch kafka-source my-topic 100 "test-value"

# Consume messages
kafka_consume kafka-source my-group my-topic 10

# Describe consumer group
kafka_describe_group kafka-source my-group
```

**Available functions:**
| Function | Description |
|----------|-------------|
| `kafka_check <container>` | Check if Kafka container is running |
| `kafka_create_topic <container> <topic> [partitions]` | Create a topic |
| `kafka_delete_topic <container> <topic>` | Delete a topic |
| `kafka_produce <container> <topic> <key> <value>` | Produce a single message |
| `kafka_produce_batch <container> <topic> <count> <value>` | Produce multiple messages |
| `kafka_produce_jsonl <container> <topic> <file>` | Produce messages from JSONL file |
| `kafka_consume <container> <group> <topic> <count>` | Consume messages |
| `kafka_describe_group <container> <group>` | Describe consumer group |
| `kafka_delete_records <container> <topic> <partition> <offset>` | Delete records up to offset |

### env.sh

Environment configuration helpers. Automatically sourced by setup scripts.

- Manages the `.env` file with port configurations
- Adds `.bin` directory to PATH if it exists

### print-help.sh

Shared help/info printing functions used by setup scripts. Provides consistent output formatting for service URLs and next steps.

