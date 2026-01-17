#!/bin/bash
#
# Initialize tutorial resources for: Migrate Consumer Groups
#
# Creates:
#   - orders-prod topic with 5 messages (source)
#   - orders-qa topic (target)
#   - order-processor consumer group at offset 3
#   - Kubernetes resources (eventhub, storage, backup)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/kafka-helpers.sh"

print_info "Setting up tutorial data..."

# Clean up existing topics
kafka_delete_topic kafka-source orders-prod
kafka_delete_topic kafka-target orders-qa

# Create topics
kafka_create_topic kafka-source orders-prod
kafka_create_topic kafka-target orders-qa

# Produce messages and create consumer group
kafka_produce_jsonl kafka-source orders-prod "${SCRIPT_DIR}/orders.jsonl"
kafka_consume kafka-source order-processor orders-prod 3

echo ""
echo "Resources created:"
echo "  - Topic: orders-prod (5 messages) on kafka-source"
echo "  - Topic: orders-qa (empty) on kafka-target"
echo "  - Consumer group: order-processor (offset: 3)"
echo ""
echo "Consumer group status:"
kafka_describe_group kafka-source order-processor

# Apply Kubernetes resources
print_info "Applying Kubernetes resources..."
kubectl apply -f "${SCRIPT_DIR}/eventhub.yaml"
kubectl apply -f "${SCRIPT_DIR}/storage.yaml"
kubectl apply -f "${SCRIPT_DIR}/backup.yaml"

echo ""
print_info "Setup complete. Verify with: kubectl get eventhub,storage,backup"
