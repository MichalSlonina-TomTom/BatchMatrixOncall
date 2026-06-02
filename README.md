# Batch Matrix Routing — Oncall Documentation

Batch Matrix Routing is a TomTom platform that accepts up to 10,000 queries per submission, executes them against underlying services (Routing API, Search API, and others) using the client's API key, and returns aggregated results. It supports both synchronous and asynchronous operation modes. The platform covers three products: Batch Search API, Batch Routing API, and Matrix Routing (v1 and v2), each with distinct architectures and repositories.

## Repository Structure

| Path | Contents |
|---|---|
| `architecture/` | Arc42 architecture documentation |
| `diagrams/` | Mermaid source files and rendered PNGs |
| `oncall/` | Oncall setup guide, runbooks, and fire-drill exercises |
| `dist/` | Generated PDF outputs |
| `Makefile` | Build targets for PDFs and diagrams |

## Quick Start

Build all PDFs and render diagrams:

```
make all
```

Prerequisites:

- [pandoc](https://pandoc.org/installing.html)
- [Node.js](https://nodejs.org/)
- Mermaid CLI: `npm install -g @mermaid-js/mermaid-cli`

## Key Documents

- [`architecture/README.md`](architecture/README.md) — Arc42 architecture overview covering system context, components, and deployment
- [`oncall/setup.md`](oncall/setup.md) — **NEW ONCALL ENGINEER START HERE** — access setup, tooling, and first-day checklist

## Public API Documentation

All products are documented on [developer.tomtom.com](https://developer.tomtom.com):

- [Batch Search API](https://developer.tomtom.com/search-api/documentation/batch-search/batch-search)
- [Batch Routing API](https://developer.tomtom.com/routing-api/documentation/batch-routing/batch-routing-service)
- [Matrix Routing v1](https://developer.tomtom.com/routing-api/documentation/matrix-routing/matrix-routing-service)
- [Matrix Routing v2](https://developer.tomtom.com/routing-api/documentation/matrix-routing-v2/matrix-routing-v2-service)

## Grafana Dashboards

| Dashboard | URL |
|---|---|
| Batch platform (prod) | https://grafana.prod.batch.tt4.nl |
| APIM / quota | https://grafana.api-system.tomtom.com |
| Cloud Logs | https://grafana.tomtomgroup.com |

## GitHub Repositories

All repositories are in the `tomtom-internal` GitHub organization:

| Repository | Purpose |
|---|---|
| [`batch-service2`](https://github.com/tomtom-internal/batch-service2) | Matrix Routing v2 service |
| [`batch-service2-1.2`](https://github.com/tomtom-internal/batch-service2-1.2) | Batch Search, Batch Routing, and Matrix Routing v1 |
| [`batch-service2-infra`](https://github.com/tomtom-internal/batch-service2-infra) | Infrastructure (Terraform, Helm, pipelines) |
| [`batch-service2-testing-tools`](https://github.com/tomtom-internal/batch-service2-testing-tools) | Load and integration test tooling |
| [`batch-service2-pulsar`](https://github.com/tomtom-internal/batch-service2-pulsar) | Apache Pulsar configuration and tooling |

## Confluence

The team knowledge base lives in Confluence. Start with the [Batch & Matrix knowledge page](https://tomtom.atlassian.net/wiki/spaces/~1cca41ed-de92-4455-812e-a4a463fc61a9/pages/315602085).

## CI / Jenkins

Build pipelines: https://ci.dev.batch.tt4.nl
