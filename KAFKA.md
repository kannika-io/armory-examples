# Kafka Migration Setup

This setup provides two Kafka clusters for simulating Kafka migrations with Kannika Armory.

## Overview

The `docker-compose.yml` file sets up:
- **kafka-source**: Source Kafka cluster (localhost:9092)
- **kafka-target**: Target Kafka cluster (localhost:9093)
- **kafka-ui-source**: Web console for source cluster (http://localhost:8080)
- **kafka-ui-target**: Web console for target cluster (http://localhost:8081)

Both clusters use Kafka KRaft mode (no ZooKeeper required) and are connected via the `kafka-migration` Docker network.

## Quick Start

### Start the Clusters

```bash
docker-compose up -d
```

### Verify the Clusters

```bash
# Check all services are running
docker-compose ps

# Check source cluster logs
docker-compose logs kafka-source

# Check target cluster logs
docker-compose logs kafka-target
```

### Access the Web Consoles

- **Source Cluster UI**: http://localhost:8080
- **Target Cluster UI**: http://localhost:8081

## Connecting from Localhost

The clusters are accessible from your local machine:

- **Source Kafka**: `localhost:9092`
- **Target Kafka**: `localhost:9093`

### Test with Kafka Console Tools

If you have Kafka tools installed locally:

```bash
# Create a topic on source cluster
kafka-topics.sh --bootstrap-server localhost:9092 --create --topic test-topic --partitions 3 --replication-factor 1

# List topics on source cluster
kafka-topics.sh --bootstrap-server localhost:9092 --list

# Produce messages to source cluster
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic test-topic

# Consume messages from source cluster
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

### Test with Docker Exec

Alternatively, use the Kafka tools included in the containers:

```bash
# Create a topic on source cluster
docker exec kafka-source kafka-topics --bootstrap-server kafka-source:29092 --create --topic test-topic --partitions 3 --replication-factor 1

# Create a topic on target cluster
docker exec kafka-target kafka-topics --bootstrap-server kafka-target:29092 --create --topic test-topic --partitions 3 --replication-factor 1

# List topics on source cluster
docker exec kafka-source kafka-topics --bootstrap-server kafka-source:29092 --list

# Produce messages
docker exec -it kafka-source kafka-console-producer --bootstrap-server kafka-source:29092 --topic test-topic

# Consume messages
docker exec kafka-source kafka-console-consumer --bootstrap-server kafka-source:29092 --topic test-topic --from-beginning --max-messages 10
```

## Connecting from Kind Cluster

To allow your Kind cluster to access the Kafka clusters, use the provided script:

```bash
./connect-kafka-to-kind.sh
```

This script will:
- Check that Docker and the Kafka network are running
- Find the Kind cluster control plane container
- Connect it to the kafka-migration network
- Verify the connection

### Manual Connection (Alternative)

If you prefer to connect manually or need to connect a different Kind cluster:

### 1. Connect Kind Network to Kafka Network

First, find your Kind cluster's network and connect it to the kafka-migration network:

```bash
# Find the Kind cluster network
docker network ls | grep kind

# Connect the Kind control plane to kafka-migration network
docker network connect kafka-migration <kind-control-plane-container>

# For default setup, this would typically be:
docker network connect kafka-migration kannika-kind-control-plane
```

### 2. Access Kafka from Pods

Once connected, pods in your Kind cluster can access Kafka using the internal Docker DNS names:

- **Source Kafka**: `kafka-source:29092`
- **Target Kafka**: `kafka-target:29092`

Example Kubernetes ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-config
data:
  source-bootstrap-servers: "kafka-source:29092"
  target-bootstrap-servers: "kafka-target:29092"
```

### 3. Test Connection from Kind

Deploy a test pod to verify connectivity:

```bash
# Create a test pod
kubectl run kafka-test --image=confluentinc/cp-kafka:7.6.0 --rm -it --restart=Never -- bash

# Inside the pod, test connection to source cluster
kafka-topics --bootstrap-server kafka-source:29092 --list

# Test connection to target cluster
kafka-topics --bootstrap-server kafka-target:29092 --list
```

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Localhost                                                    │
│  - kafka-source: localhost:9092                             │
│  - kafka-target: localhost:9093                             │
│  - kafka-ui-source: http://localhost:8080                   │
│  - kafka-ui-target: http://localhost:8081                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │
┌─────────────────────────────────────────────────────────────┐
│ Docker Network: kafka-migration                             │
│                                                              │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │  kafka-source   │              │  kafka-target   │      │
│  │  :29092 (int)   │              │  :29092 (int)   │      │
│  │  :9092 (ext)    │              │  :9093 (ext)    │      │
│  └─────────────────┘              └─────────────────┘      │
│          │                                  │               │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │ kafka-ui-source │              │ kafka-ui-target │      │
│  │   :8080 (ext)   │              │   :8081 (ext)   │      │
│  └─────────────────┘              └─────────────────┘      │
│                                                              │
│  ◄─── Kind Cluster (when connected via docker network) ───► │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Details

### Kafka Source Cluster
- **Container Name**: `kafka-source`
- **Internal Address**: `kafka-source:29092`
- **External Address**: `localhost:9092`
- **UI Console**: http://localhost:8080
- **Data Volume**: `kafka-source-data`

### Kafka Target Cluster
- **Container Name**: `kafka-target`
- **Internal Address**: `kafka-target:29092`
- **External Address**: `localhost:9093`
- **UI Console**: http://localhost:8081
- **Data Volume**: `kafka-target-data`

### Key Features
- **KRaft Mode**: No ZooKeeper dependency
- **Persistent Storage**: Data persists across container restarts
- **Dual Network Access**: Both localhost and Docker network connectivity
- **Web UI**: Visual management and monitoring

## Managing the Environment

### Stop the Clusters

```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Slate)

```bash
docker-compose down -v
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f kafka-source
docker-compose logs -f kafka-ui-source
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart kafka-source
```

## Troubleshooting

### Kafka Not Starting

1. Check if ports are already in use:
   ```bash
   lsof -i :9092
   lsof -i :9093
   lsof -i :8080
   lsof -i :8081
   ```

2. Check container logs:
   ```bash
   docker-compose logs kafka-source
   docker-compose logs kafka-target
   ```

### Cannot Connect from Kind

1. Verify network connection:
   ```bash
   docker network inspect kafka-migration
   ```

2. Ensure the Kind control plane is connected:
   ```bash
   docker inspect <kind-control-plane-container> | grep kafka-migration
   ```

3. Test DNS resolution from a pod:
   ```bash
   kubectl run busybox --image=busybox --rm -it --restart=Never -- nslookup kafka-source
   ```

### UI Console Not Loading

1. Verify Kafka is running and healthy:
   ```bash
   docker-compose ps
   ```

2. Check UI logs:
   ```bash
   docker-compose logs kafka-ui-source
   docker-compose logs kafka-ui-target
   ```

## Advanced Usage

### Custom Configuration

You can customize the setup by editing `docker-compose.yml`:

- Change ports to avoid conflicts
- Adjust resource limits
- Add more brokers for multi-node clusters
- Configure additional Kafka settings

### Multiple Brokers

To add more brokers to either cluster, duplicate the service configuration and adjust:
- `KAFKA_NODE_ID`
- Port mappings
- `KAFKA_CONTROLLER_QUORUM_VOTERS`

### Integration with Kannika Armory

Once both Kafka clusters are running and accessible from your Kind cluster:

1. Configure Kannika to connect to source cluster (`kafka-source:29092`)
2. Configure target cluster (`kafka-target:29092`)
3. Set up migration policies
4. Monitor the migration via Kafka UI consoles

## References

- [Confluent Kafka Docker Images](https://hub.docker.com/r/confluentinc/cp-kafka)
- [Kafka UI](https://github.com/provectus/kafka-ui)
- [Kafka KRaft Mode](https://kafka.apache.org/documentation/#kraft)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
