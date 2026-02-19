# Backup with S3 Storage (MinIO) Tutorial

Resources for the [Backup with S3 Storage](https://docs.kannika.io/tutorials/disaster-recovery/backup-with-s3-storage/) tutorial.

## Setup

```bash
./setup s3-minio-backup
```

## Troubleshooting

### MinIO not reachable from pods

If the backup cannot connect to MinIO, verify the Kind nodes are connected to the MinIO network:

```bash
docker network inspect minio
```

If the Kind nodes are not listed, reconnect them:

```bash
docker network connect minio kannika-kind-control-plane
```

### Backup stuck in Pending state

Check the backup pod logs for S3 connectivity errors:

```bash
kubectl get backup prod-backup -n kannika-data
kubectl logs -l io.kannika/backup=prod-backup -n kannika-data
```

Verify the credentials secret exists:

```bash
kubectl get secret s3-minio-creds -n kannika-data
```
