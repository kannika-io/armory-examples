# Schedule Backup Snapshots Tutorial

Resources for the [Schedule Backup Snapshots](https://docs.kannika.io/tutorials/compliance/schedule-snapshots/) tutorial.

## Setup

```bash
./setup schedule-snapshots
```

## Troubleshooting

### CronJob not creating new Storage

If the CronJob runs but no new Storage is created, check the job logs:

```bash
kubectl get jobs -n kannika-data
kubectl logs job/<job-name> -n kannika-data
```

Check that the ServiceAccount has the required permissions:

```bash
kubectl auth can-i create storages.kannika.io --as=system:serviceaccount:kannika-data:backup-storage-rotate-sa -n kannika-data
```

### Backup stuck in Paused state

If the backup remains paused after rotation:

```bash
kubectl patch backup compliance-backup -n kannika-data \
  --type merge \
  -p '{"spec":{"enabled":true}}'
```
