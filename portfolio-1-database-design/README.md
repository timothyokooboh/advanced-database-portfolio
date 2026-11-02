# Portfolio 1: Database Design and Modelling

This portfolio defines the relational foundation for AsterMart Retail & Fulfilment Ltd. It translates the business scenario into entities, relationships, keys, constraints, and a normalized PostgreSQL schema.

## Evidence in this portfolio

- [Case study and requirements](docs/case-study-and-requirements.md)
- [Entity relationship model](diagrams/astermart-erd.mmd)
- [Relational schema](schema/001_relational_schema.sql)
- Data dictionary and normalization analysis are added as the next focused part of this milestone.

The Mermaid source can be rendered directly by GitHub or with the Mermaid CLI. The model uses crow's-foot cardinality: `||` means exactly one, `o|` zero or one, `o{` zero or many, and `|{` one or many.

## Design boundaries

The model covers product cataloguing, branch stock, customer addresses, sales orders, payments, and fulfilment. Promotions, suppliers, procurement, returns, and accounting are deliberately outside the first release so the portfolio remains deep enough to analyse without becoming unfocused.

The SQL targets PostgreSQL 16 or later. Day 1 defines the schema; later portfolios add seed data, performance experiments, transaction demonstrations, and distributed deployment evidence.
