#!/bin/bash
# Shared help/info printing functions
# Expects port variables to be set (from .env)

print_armory_info() {
    echo "Kannika Armory:"
    echo "  Console:  http://localhost:${ARMORY_CONSOLE_PORT}"
    echo "  API:      http://localhost:${ARMORY_API_PORT}"
    if [ -n "${ARMORY_USERNAME}" ]; then
        echo "  Username: ${ARMORY_USERNAME}"
        echo "  Password: ${ARMORY_PASSWORD}"
    fi
}

print_kafka_info() {
    echo "Kafka:"
    echo "  Source console: http://localhost:${KAFKA_SOURCE_CONSOLE_PORT}"
    echo "  Target console: http://localhost:${KAFKA_TARGET_CONSOLE_PORT}"
}

print_teardown_info() {
    echo "Teardown:"
    echo "  ./teardown.sh              # Kind cluster only"
    echo "  ./teardown.sh --all        # Kind cluster and Kafka"
}

print_next_steps_armory() {
    echo "Next steps:"
    echo "  ./setup kafka              # Set up Kafka clusters"
    echo "  ./setup <tutorial-name>    # Run a tutorial (includes Kafka)"
    echo "  ./setup list               # See available tutorials"
}
