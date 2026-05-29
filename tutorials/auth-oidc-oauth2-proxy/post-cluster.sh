#!/bin/bash
# Start Keycloak and oauth2-proxy, connect Kind to the Keycloak network.

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
docker-compose -f "${TUTORIAL_DIR}/docker-compose.keycloak.yml" up -d --force-recreate keycloak

print_info "Waiting for Keycloak to be ready..."
until curl -sf http://keycloak:8280/realms/kannika > /dev/null 2>&1; do
    sleep 2
done
print_info "Keycloak is ready."

print_info "Starting oauth2-proxy..."
docker-compose -f "${TUTORIAL_DIR}/docker-compose.keycloak.yml" up -d --force-recreate oauth2-proxy

print_info "Waiting for oauth2-proxy to be ready..."
until curl -sf http://localhost:4180/ping > /dev/null 2>&1; do
    sleep 2
done
print_info "oauth2-proxy is ready."

print_info "Connecting Kubernetes to Keycloak network..."
for node in $(docker ps --format '{{.Names}}' | grep -E "^${CLUSTER_NAME}-(control-plane|worker)"); do
    docker network connect keycloak "$node" 2>/dev/null || true
done
