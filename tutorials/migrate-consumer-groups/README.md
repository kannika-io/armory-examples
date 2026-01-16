# Migrate Consumer Groups Tutorial

Resources for the [Migrate Consumer Groups](https://docs.kannika.io/tutorials/environment-cloning/migrate-consumer-groups/) tutorial.

## Setup

```bash
./setup migrate-consumer-groups
```

## Troubleshooting

### Restore has no status

If you're watching a restore and it shows no status:

```bash
kubectl get restore -w
```

```
NAME                 STATUS
restore-prod-to-qa
```

This means the operator is not reconciling resources, typically because it does not have a valid license loaded.

**Solution:** Load a valid license into the cluster:

```bash
kubectl create secret generic kannika-license \
  --namespace kannika-system \
  --from-file=license=<path-to-license-file> \
  --type=kannika.io/license
```

You can request a free license at: https://kannika.io/free-trial
