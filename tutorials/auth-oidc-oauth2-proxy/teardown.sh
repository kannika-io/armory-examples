#!/bin/bash
# Teardown Keycloak and oauth2-proxy.

print_info "Stopping oauth2-proxy and Keycloak..."
docker-compose -f "${TUTORIAL_DIR}/docker-compose.keycloak.yml" down -v 2>/dev/null || true

if grep -q "# kannika-armory-tutorial" /etc/hosts 2>/dev/null; then
    read -p "Remove 'keycloak' entry from /etc/hosts? (requires sudo) [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo sed -i.bak '/# kannika-armory-tutorial/d' /etc/hosts
    fi
fi
