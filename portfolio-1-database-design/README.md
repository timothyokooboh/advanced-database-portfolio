# Portfolio 1: Database Design and Modelling

This portfolio defines the relational foundation for AsterMart Retail & Fulfilment Ltd. It translates the business scenario into entities, relationships, keys, constraints, and a normalized PostgreSQL schema.

## Evidence in this portfolio

- [Case study and requirements](docs/case-study-and-requirements.md)
- [Entity relationship diagram](diagrams/README.md) and [detailed model source](diagrams/astermart-erd.mmd)
- [Relational schema](schema/001_relational_schema.sql)
- [Relational design, key mapping, and normalization analysis](docs/relational-design-and-normalisation.md)

The Mermaid source can be rendered directly by GitHub or with the Mermaid CLI. The model uses crow's-foot cardinality: `||` means exactly one, `o|` zero or one, `o{` zero or many, and `|{` one or many.

## Design boundaries

The model covers product cataloguing, branch stock, customer addresses, sales orders, payments, and fulfilment. Promotions, suppliers, procurement, returns, and accounting are deliberately outside the first release so the portfolio remains deep enough to analyse without becoming unfocused.

The SQL targets PostgreSQL 16 or later. Day 1 defines the schema; later portfolios add seed data, performance experiments, transaction demonstrations, and distributed deployment evidence.

## Day 1 verification

- Requirements, entities, and business rules were traced to schema constraints.
- ERD entity names and relationships were checked against the DDL.
- Markdown and SQL files pass whitespace/error checks with `git diff --check`.
- Runtime DDL execution is deferred to the reproducible local PostgreSQL environment in the next milestone; no unexecuted output is presented as runtime evidence.
