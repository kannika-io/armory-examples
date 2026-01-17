#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/env.sh"
__env_load

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-kannika-kind}"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Tear down Kannika Armory environment.

OPTIONS:
    -h, --help              Show this help message
    -c, --cluster NAME      Kind cluster name (default: kannika-kind)
    -a, --all               Also stop Kafka clusters (docker-compose down)

EXAMPLES:
    $0                      # Delete Kind cluster only
    $0 --all                # Delete Kind cluster and stop Kafka
    $0 -c my-cluster --all  # Delete custom cluster and stop Kafka

EOF
}

DELETE_KAFKA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -a|--all)
            DELETE_KAFKA=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

print_info "Tearing down Kannika Armory environment..."
echo ""

# Delete Kind cluster
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_info "Deleting Kind cluster: ${CLUSTER_NAME}..."
    kind delete cluster --name "${CLUSTER_NAME}"
    print_info "Kind cluster deleted."
else
    print_warning "Kind cluster '${CLUSTER_NAME}' not found. Skipping."
fi

# Stop Kafka if requested
if [ "$DELETE_KAFKA" = true ]; then
    if [ -f "docker-compose.yml" ]; then
        print_info "Stopping Kafka clusters..."
        docker-compose down -v
        print_info "Kafka clusters stopped."
    else
        print_warning "docker-compose.yml not found. Skipping Kafka teardown."
    fi
fi

echo ""
print_info "Teardown complete."
