# Authenticate with OIDC Tutorial

Resources for the [Authenticate with OIDC](https://docs.kannika.io/tutorials/security/auth-oidc/) tutorial.

## Setup

```bash
./setup auth-oidc
```

During setup you will be prompted to add `127.0.0.1 keycloak` to `/etc/hosts` (requires sudo).
This is needed so that both your browser and the Kubernetes pods reach Keycloak at the same hostname.

## Credentials

| Service          | URL                     | Username | Password |
|------------------|-------------------------|----------|----------|
| Keycloak Admin   | http://keycloak:8280    | admin    | admin    |
| Keycloak Demo    | —                       | demo     | demo     |
| Kannika Console  | http://localhost:8080   | demo     | demo     |

## Teardown

```bash
./teardown auth-oidc
```

This stops Keycloak and offers to remove the `/etc/hosts` entry.

## Troubleshooting

### Keycloak not starting

Check that port 8280 is not in use:

```bash
lsof -i :8280
```

### CORS errors in the browser

CORS errors usually mask a Keycloak-side issue.
Open the Keycloak URL directly (http://keycloak:8280/realms/kannika) to see the actual error.

### Console not redirecting to Keycloak

Verify the Helm values were applied:

```bash
helm get values kannika -n kannika-system
```

Check that `console.config.security.oidc.enabled` is `true`.

### API returns 401

Make sure the `/etc/hosts` entry is in place and that Keycloak is reachable at http://keycloak:8280.
The API validates the token issuer (`iss` claim) against the configured `issuerUri` — both must use the same hostname and port.
