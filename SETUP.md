# Kannika Armory Setup on Kind

This guide provides instructions for setting up Kannika Armory on a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) (Kubernetes IN Docker).

## Prerequisites

Before running the setup script, ensure you have the following tools installed:

1. **Docker** - Container runtime
   - [Installation Guide](https://docs.docker.com/get-docker/)
   - Verify: `docker --version`

2. **kind** - Kubernetes IN Docker
   - [Installation Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
   - Verify: `kind --version`

3. **kubectl** - Kubernetes command-line tool (v1.28+)
   - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
   - Verify: `kubectl version --client`

4. **helm** - Kubernetes package manager (v3.9+)
   - [Installation Guide](https://helm.sh/docs/intro/install/)
   - Verify: `helm version`

## Quick Start

The simplest way to set up Kannika Armory:

```bash
./setup-kannika-armory.sh
```

This will:
1. Create a kind cluster named `kannika-kind`
2. Install Kannika CRDs version 0.12.4
3. Create the `kannika-system` namespace
4. Install Kannika Armory version 0.12.4
5. Verify the installation

## Usage

### Basic Usage

```bash
./setup-kannika-armory.sh
```

### With Custom Options

```bash
# Custom cluster name
./setup-kannika-armory.sh --cluster my-kannika-cluster

# Specific Kannika version
./setup-kannika-armory.sh --version 0.12.4

# Custom namespace
./setup-kannika-armory.sh --namespace my-namespace

# With license file
./setup-kannika-armory.sh --license /path/to/license.key

# Combine multiple options
./setup-kannika-armory.sh \
  --cluster production-kind \
  --version 0.12.4 \
  --namespace kannika \
  --license ./kannika-license.key
```

### Using Environment Variables

```bash
# Set environment variables
export CLUSTER_NAME=my-cluster
export KANNIKA_VERSION=0.12.4
export KANNIKA_NAMESPACE=kannika-system
export LICENSE_PATH=/path/to/license.key

# Run the script
./setup-kannika-armory.sh
```

## Command-Line Options

| Option | Environment Variable | Default | Description |
|--------|---------------------|---------|-------------|
| `--cluster`, `-c` | `CLUSTER_NAME` | `kannika-kind` | Name of the kind cluster to create |
| `--version`, `-v` | `KANNIKA_VERSION` | `0.12.4` | Version of Kannika Armory to install |
| `--namespace`, `-n` | `KANNIKA_NAMESPACE` | `kannika-system` | Kubernetes namespace for Kannika |
| `--license`, `-l` | `LICENSE_PATH` | (none) | Path to Kannika license file |
| `--help`, `-h` | - | - | Show help message |

## What the Script Does

1. **Prerequisites Check**: Verifies that Docker, kind, kubectl, and helm are installed and Docker is running.

2. **Create Kind Cluster**: Creates a new kind cluster with the specified name (skips if already exists).

3. **Install Kannika CRDs**: Installs Kannika Custom Resource Definitions using Helm.

4. **Create Namespace**: Creates the Kannika namespace in the cluster.

5. **Create License Secret** (optional): If a license path is provided, creates a Kubernetes secret with the license.

6. **Install Kannika Armory**: Installs Kannika Armory using Helm.

7. **Verify Installation**: Checks that all deployments are running correctly.

## Expected Output

After successful installation, you should see three main deployments:
- `api` - Kannika API server
- `console` - Kannika web console
- `operator` - Kannika operator for managing backups

## Post-Installation

### Verify the Installation

```bash
# Check all resources in the Kannika namespace
kubectl get all -n kannika-system

# Check deployment status
kubectl get deployments -n kannika-system

# Check pod logs (replace POD_NAME with actual pod name)
kubectl logs -n kannika-system POD_NAME
```

### Access the Cluster

```bash
# Set kubectl context to your kind cluster
kubectl config use-context kind-kannika-kind

# View cluster info
kubectl cluster-info
```

### Adding a License Later

If you didn't provide a license during setup, you can add it later:

```bash
kubectl create secret generic kannika-license \
  --namespace kannika-system \
  --from-file=license=/path/to/license.key \
  --type=kannika.io/license
```

## Troubleshooting

### Docker Not Running

If you see "Docker is not running" error:
- Start Docker Desktop (macOS/Windows)
- Start Docker daemon (Linux): `sudo systemctl start docker`

### Cluster Already Exists

If the cluster already exists, the script will skip creation and use the existing cluster. To start fresh:

```bash
kind delete cluster --name kannika-kind
./setup-kannika-armory.sh
```

### Installation Timeout

If the installation times out, you can check the status manually:

```bash
# Check pod status
kubectl get pods -n kannika-system

# Check pod events
kubectl describe pod POD_NAME -n kannika-system

# Check logs
kubectl logs -n kannika-system POD_NAME
```

### Missing Tools

If any prerequisite tools are missing, the script will report which ones need to be installed. Follow the installation links in the prerequisites section.

## Cleanup

To remove the kind cluster and all resources:

```bash
kind delete cluster --name kannika-kind
```

This will completely remove the cluster and all Kannika resources.

## Advanced Configuration

### Multi-Node Cluster

For a multi-node kind cluster, create a configuration file:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Then create the cluster manually before running the script:

```bash
kind create cluster --name kannika-kind --config kind-config.yaml
./setup-kannika-armory.sh
```

### Custom Helm Values

To customize Kannika installation, you can modify the script's `install_kannika_armory` function to include custom values:

```bash
helm install kannika oci://quay.io/kannika/charts/kannika \
  --namespace "${KANNIKA_NAMESPACE}" \
  --version "${KANNIKA_VERSION}" \
  --set key=value \
  --wait
```

## Resources

- [Kannika Documentation](https://docs.kannika.io/)
- [Kannika Installation Guide](https://docs.kannika.io/installation/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm Documentation](https://helm.sh/docs/)

## License

This script is part of the armory-examples repository. See the [LICENSE](LICENSE) file for details.
