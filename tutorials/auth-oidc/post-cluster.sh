#!/bin/bash
# Start Keycloak and connect Kind to its network.

if ! grep -q "# kannika-armory-tutorial" /etc/hosts 2>/dev/null; then
    echo ""
    print_info "This tutorial needs to add '127.0.0.1 keycloak' to /etc/hosts"
    print_info "so that both your browser and Kubernetes can reach Keycloak at the same hostname."
    read -p "Add entry to /etc/hosts? (requires sudo) [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo sh -c 'echo "127.0.0.1 keycloak # kannika-armory-tutorial" >> /etc/hosts'
    else
        print_warning "Skipped. You may need to add '127.0.0.1 keycloak' to /etc/hosts manually."
    fi
fi

print_info "Starting Keycloak..."
docker-compose -f "${TUTORIAL_DIR}/docker-compose.keycloak.yml" up -d --force-recreate

print_info "Waiting for Keycloak to be ready..."
until curl -sf http://keycloak:8280/realms/kannika > /dev/null 2>&1; do
    sleep 2
done
print_info "Keycloak is ready."

print_info "Connecting Kubernetes to Keycloak..."
for node in $(docker ps --format '{{.Names}}' | grep -E "^${CLUSTER_NAME}-(control-plane|worker)"); do
    docker network connect keycloak "$node" 2>/dev/null || true
done
