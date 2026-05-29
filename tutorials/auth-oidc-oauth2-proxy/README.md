# Authenticate with oauth2-proxy (Client Secret)

Resources for the Authenticate with oauth2-proxy tutorial.

This tutorial uses [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) as a reverse proxy
that handles OIDC authentication with a **confidential client** (client ID + client secret)
instead of the PKCE flow used in the [auth-oidc](../auth-oidc/) tutorial.

## Setup

```bash
./setup auth-oidc-oauth2-proxy
```

During setup you will be prompted to add `127.0.0.1 keycloak` to `/etc/hosts` (requires sudo).
This is needed so that both your browser and the Kubernetes pods reach Keycloak at the same hostname.

## How it works

```mermaid
sequenceDiagram
    participant Browser
    participant oauth2-proxy as oauth2-proxy (:4180)
    participant Keycloak as Keycloak (:8280)
    participant Console as Armory Console (:8080)

    Browser->>oauth2-proxy: GET /
    oauth2-proxy->>Browser: 302 Redirect to Keycloak
    Browser->>Keycloak: Login page
    Keycloak->>Browser: Authorization code
    Browser->>oauth2-proxy: Callback with code
    oauth2-proxy->>Keycloak: Exchange code for tokens (client ID + secret)
    Keycloak->>oauth2-proxy: Access token + ID token
    oauth2-proxy->>Browser: Set session cookie
    Browser->>oauth2-proxy: Subsequent requests (with cookie)
    oauth2-proxy->>Console: Proxy request
    Console->>oauth2-proxy: Response
    oauth2-proxy->>Browser: Response
```

### PKCE vs Client Secret

| | auth-oidc (PKCE) | auth-oidc-oauth2-proxy (Client Secret) |
|---|---|---|
| Client type | Public | Confidential |
| Secret stored | — | Server-side (oauth2-proxy) |
| PKCE | S256 | Not used |
| Token exchange | Browser (SPA) | Server (oauth2-proxy) |
| Use case | SPAs, mobile apps | Server-side apps, reverse proxies |

## Credentials

| Service          | URL                     | Username | Password |
|------------------|-------------------------|----------|----------|
| Keycloak Admin   | http://keycloak:8280    | admin    | admin    |
| Keycloak Demo    | —                       | demo     | demo     |
| Armory Console   | http://localhost:4180   | demo     | demo     |

> **Note:** Access the console through oauth2-proxy at port 4180, not directly at port 8080.

## Teardown

```bash
./teardown auth-oidc-oauth2-proxy
```

This stops oauth2-proxy and Keycloak, and offers to remove the `/etc/hosts` entry.

## Troubleshooting

### oauth2-proxy not starting

Check that Keycloak is running and the realm is accessible:

```bash
curl http://keycloak:8280/realms/kannika
```

Check oauth2-proxy logs:

```bash
docker logs oauth2-proxy
```

### "Invalid redirect URI" error

Make sure the redirect URI in Keycloak matches exactly:
`http://localhost:4180/oauth2/callback`

Check the client configuration in the Keycloak admin console under
Clients → kannika-armory-proxy → Settings → Valid Redirect URIs.

### CORS errors in the browser

CORS errors usually mask a Keycloak-side issue.
Open the Keycloak URL directly (http://keycloak:8280/realms/kannika) to see the actual error.

### Console not loading behind oauth2-proxy

Verify oauth2-proxy can reach the console:

```bash
docker exec oauth2-proxy wget -qO- http://host.docker.internal:8080 2>&1 | head -5
```

If this fails, check that the Armory console is running:

```bash
kubectl get pods -n kannika-system
```
