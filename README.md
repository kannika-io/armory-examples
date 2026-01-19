# Kannika Armory Examples

A collection of examples for Kannika Armory https://kannika.io

## Quick Start

Run a tutorial without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/kannika-io/armory-examples/refs/heads/main/install.sh | bash -s -- migrate-consumer-groups
```

Or clone and run locally:

```bash
./setup migrate-consumer-groups
```

List available tutorials:

```bash
./setup list
```

## Setup Commands

```bash
./setup <tutorial>    # Run a tutorial (sets up everything)
./setup armory        # Set up Kannika Armory only
./setup kafka         # Set up Kafka clusters only
./setup list          # List available tutorials
```

## Services

After setup, services are available at:

| Component | Service | URL |
|-----------|---------|-----|
| Kannika Armory | Console | http://localhost:8080 |
| Kannika Armory | API | http://localhost:8081 |
| Kafka Source | Broker | localhost:9092 |
| Kafka Source | Console | http://localhost:8180 |
| Kafka Target | Broker | localhost:9093 |
| Kafka Target | Console | http://localhost:8181 |

## Prerequisites

- Docker
- kind (or use `./scripts/install-kind.sh`)
- kubectl v1.28+ (or use `./scripts/install-kubectl.sh`)
- helm v3.9+ (or use `./scripts/install-helm.sh`)

## Teardown

```bash
./teardown.sh          # Delete Kind cluster only
./teardown.sh --all    # Delete Kind cluster and stop Kafka
```

## Resources

- [Kannika Documentation](https://docs.kannika.io/)
- [Kannika Installation Guide](https://docs.kannika.io/installation/)
- [Free Trial License](https://kannika.io/free-trial)

## Community

Questions or feedback? Join us on [Slack](https://kannika-io.slack.com/) or get in touch at [hello@kannika.io](mailto:hello@kannika.io).
