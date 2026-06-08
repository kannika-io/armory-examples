# Armory Examples — Kafka Management Tutorials by Kannika.io

> Hands-on tutorials for [Kannika Armory](https://kannika.io) — the Kafka management and operations platform.  
> Maintained by [Kannika.io](https://kannika.io).

This repository contains runnable, self-contained tutorial environments for Kannika Armory. Each tutorial spins up a full local Kafka stack using Docker and Kubernetes (kind), so you can explore real Kafka operations — cluster migrations, consumer group management, schema handling, and more — without touching production.

## What is Kannika Armory?

[Kannika Armory](https://kannika.io) is the Kafka management platform by [Kannika.io](https://kannika.io). It gives platform and data engineering teams a single control plane for operating Kafka clusters — with a web console, REST API, and automation-first design.

- **Console:** `http://localhost:8080`
- **API:** `http://localhost:8081`
- **Docs:** [docs.kannika.io](https://kannika.io/docs)
- **Free trial:** available at [kannika.io](https://kannika.io)

---

## Quick Start

Run a tutorial without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/kannika-io/armory-examples/refs/heads/main/install.sh \
  | bash -s -- migrate-consumer-groups
```

Or clone and run locally:

```bash
./setup migrate-consumer-groups
```

List available tutorials:

```bash
./setup list
```

## Commands

```bash
./setup <tutorial>    # Run a tutorial (sets up everything)
./setup armory        # Set up Kannika Armory only
./setup kafka         # Set up Kafka clusters only
./setup network       # Connect Kind cluster to Kafka network
./setup tools         # Install kind, kubectl, helm to .bin
./setup list          # List available tutorials
./teardown            # Delete Kind cluster and stop Kafka
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
- kind, kubectl, helm (or use `./setup tools`)

## Adding a Tutorial

Create a new directory under `tutorials/`. The directory name is the tutorial name:

```
tutorials/my-tutorial/           # Run with: ./setup my-tutorial
├── README.md        # First line used as description in ./setup list
├── help.txt         # Printed after setup completes
├── values.yaml      # Helm values merged into Armory install
├── k8s/             # Kubernetes resources applied automatically
├── pre-setup.sh     # Hook: before anything starts
├── pre-cluster.sh   # Hook: before Kind cluster creation
├── post-cluster.sh  # Hook: after Kind cluster creation
├── pre-install.sh   # Hook: before Armory Helm install
├── post-install.sh  # Hook: after Armory install and k8s/ resources applied
├── post-setup.sh    # Hook: after everything completes
└── teardown.sh      # Hook: run by ./teardown <tutorial>
```

All files are optional. Hook scripts must be executable.

## Resources

- [Kannika Documentation](https://docs.kannika.io/)
- [Kannika Installation Guide](https://docs.kannika.io/installation/)
- [Free Trial License](https://kannika.io/free-trial)

## Community

Questions or feedback? Join us on [Slack](https://kannika-io.slack.com/) or get in touch at [hello@kannika.io](mailto:hello@kannika.io).
