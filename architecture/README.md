# Batch Matrix Routing — Architecture Documentation

[arc42](https://arc42.org/) architecture reference for Batch Search API, Batch Routing API, and Matrix Routing v1 (collectively Batch&Matrix).

## Sections

| # | File | Description |
|---|------|-------------|
| 1 | [Introduction and Goals](01-introduction-and-goals.md) | Quality goals, stakeholders, and top-level requirements |
| 2 | [Architecture Constraints](02-architecture-constraints.md) | Technical and organisational constraints that shape decisions |
| 3 | [Context and Scope](03-context-and-scope.md) | System boundaries and external interfaces |
| 4 | [Solution Strategy](04-solution-strategy.md) | Fundamental decisions addressing throughput, isolation, and resilience |
| 5 | [Building Block View](05-building-block-view.md) | Static decomposition of the system into components |
| 6 | [Runtime View](06-runtime-view.md) | Dynamic behaviour: async submission, processing, and result delivery |
| 7 | [Deployment View](07-deployment-view.md) | Multi-region Azure infrastructure layout |
| 8 | [Cross-Cutting Concepts](08-concepts.md) | Fairness, quota enforcement, and lifecycle concepts applied system-wide |
| 9 | Architecture Decisions | _Not yet written_ — ADR log for key design choices |
| 10 | Quality Requirements | _Not yet written_ — detailed quality scenarios and acceptance criteria |
| 11 | Risks and Technical Debt | _Not yet written_ — known risks and tracked debt items |
| 12 | Glossary | _Not yet written_ — domain and technical term definitions |

## Building the PDF

From the repo root:

```bash
make architecture-pdf
```

The PDF is output to `dist/`.

## Diagrams

[Mermaid](https://mermaid.js.org/) source files live in [../diagrams/](../diagrams/). Generate PNGs from `.mmd` files with:

```bash
make diagrams
```

Run this command before building the PDF to ensure all diagrams are up to date.

## Related

- [Oncall setup](../oncall/setup.md) — on-call rotation, escalation paths, and tooling prerequisites
- [Diagrams](../diagrams/) — Mermaid source for all architecture diagrams
