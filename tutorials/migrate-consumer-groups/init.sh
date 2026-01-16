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

source "${SCRIPT_DIR}/kafka-helpers.sh"

SOURCE_TOPIC="orders-prod"
TARGET_TOPIC="orders-qa"
CONSUMER_GROUP="order-processor"
MESSAGES_PROCESSED=3

print_info "Setting up tutorial data..."

# Clean up existing topics
kafka_delete_topic source "${SOURCE_TOPIC}"
kafka_delete_topic target "${TARGET_TOPIC}"
sleep 2

# Create topics
kafka_create_topic source "${SOURCE_TOPIC}"
kafka_create_topic target "${TARGET_TOPIC}"

# Produce messages and create consumer group
kafka_produce_jsonl "${SOURCE_TOPIC}" "${SCRIPT_DIR}/orders.jsonl"
kafka_consume "${CONSUMER_GROUP}" "${SOURCE_TOPIC}" "${MESSAGES_PROCESSED}"

echo ""
echo "Resources created:"
echo "  - Topic: ${SOURCE_TOPIC} (5 messages) on kafka-source"
echo "  - Topic: ${TARGET_TOPIC} (empty) on kafka-target"
echo "  - Consumer group: ${CONSUMER_GROUP} (offset: ${MESSAGES_PROCESSED})"
echo ""
echo "Consumer group status:"
kafka_describe_group "${CONSUMER_GROUP}"

# Apply Kubernetes resources
print_info "Applying Kubernetes resources..."
kubectl apply -f "${SCRIPT_DIR}/eventhub.yaml"
kubectl apply -f "${SCRIPT_DIR}/storage.yaml"
kubectl apply -f "${SCRIPT_DIR}/backup.yaml"
