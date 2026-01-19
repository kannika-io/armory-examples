#!/bin/bash
#
# Initialize tutorial resources for: Migrate Consumer Groups
#
# Creates:
#   - orders-prod topic with 5 messages at offsets 100-104 (source)
#   - orders-qa topic (target)
#   - order-processor consumer group at offset 103
#   - Kubernetes resources (eventhub, storage, backup)
#
set -e

TUTORIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TUTORIAL_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/env.sh"
__env_load
source "${REPO_ROOT}/scripts/kafka-helpers.sh"

print_info "Setting up tutorial data..."

# Clean up existing topics
kafka_delete_topic kafka-source orders-prod
kafka_delete_topic kafka-target orders-qa

# Create topics
kafka_create_topic kafka-source orders-prod
kafka_create_topic kafka-target orders-qa

# Produce 100 dummy messages to advance offset, then real orders
kafka_produce_batch kafka-source orders-prod 100 '{}'
kafka_produce_jsonl kafka-source orders-prod "${TUTORIAL_DIR}/orders.jsonl"

# Delete the first 100 records, leaving only offsets 100-104
kafka_delete_records kafka-source orders-prod 0 100

# Create consumer group at offset 103 (3 messages processed, 2 remaining)
kafka_consume kafka-source order-processor orders-prod 3

echo ""
echo "Resources created:"
echo "  - Topic: orders-prod (5 messages, starting at offset 100) on kafka-source"
echo "  - Topic: orders-qa (empty) on kafka-target"
echo "  - Consumer group: order-processor (offset: 103, 2 remaining)"
echo ""
echo "Consumer group status:"
kafka_describe_group kafka-source order-processor

# Apply Kubernetes resources
print_info "Applying Kubernetes resources..."
kubectl apply -f "${TUTORIAL_DIR}/setup/"

echo ""
print_info "Setup complete. Verify with: kubectl get eventhub,storage,backup"
