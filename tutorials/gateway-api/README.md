Expose Armory via the Kubernetes Gateway API using Envoy Gateway.

This tutorial installs [Envoy Gateway](https://gateway.envoyproxy.io/) as a Gateway API controller
and configures `HTTPRoute` resources to route traffic to the Armory API and Console.
It includes both HTTP and HTTPS listeners with a self-signed TLS certificate.

See the [networking documentation](https://docs.kannika.io/installation/configuration/networking/#gateway-api)
for details on the Gateway API resources.

## Setup

```bash
./setup gateway-api
```

## Access

After setup completes, the port-forward command is printed.
Envoy Gateway appends a hash to the service name, so find it first:

```bash
kubectl get svc -n envoy-gateway-system | grep kannika
```

Then port-forward:

```bash
kubectl port-forward -n envoy-gateway-system svc/<envoy-service-name> 8443:443 8080:80
```

| Service | URL |
| :--- | :--- |
| Console (HTTPS) | https://localhost:8443 |
| Console (HTTP) | http://localhost:8080 |
| GraphQL API | https://localhost:8443/gql |
| REST API | https://localhost:8443/rest |

> The HTTPS URLs use a self-signed certificate.
> Your browser will show a security warning that you can safely accept.

## What's included

| Resource | Kind | Namespace |
| :--- | :--- | :--- |
| `kannika` | Gateway | kannika-system |
| `api` | HTTPRoute | kannika-system |
| `console` | HTTPRoute | kannika-system |
| `kannika-tls` | Secret (TLS) | kannika-system |

## Troubleshooting

### Gateway not getting Programmed

Check if Envoy Gateway is running:

```bash
kubectl get pods -n envoy-gateway-system
```

Check Gateway status:

```bash
kubectl describe gateway kannika -n kannika-system
```

### Routes not working

Verify the HTTPRoutes are accepted:

```bash
kubectl get httproute -n kannika-system
```

Check the route status for any errors:

```bash
kubectl describe httproute api -n kannika-system
kubectl describe httproute console -n kannika-system
```

### Port-forward not working

Envoy Gateway names the proxy service `envoy-<namespace>-<gateway-name>-<hash>`.
Find the exact name:

```bash
kubectl get svc -n envoy-gateway-system | grep kannika
```
