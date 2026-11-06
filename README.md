# Advanced Database Systems Portfolio

This repository contains the practical portfolio for **MIT 8103 - Advanced Database Systems**. It applies relational, NoSQL, transactional, optimisation, and distributed database concepts to one consistent simulated organisation.

## Selected organisation

**AsterMart Retail & Fulfilment Ltd.** is a simulated Nigerian multi-branch retailer. Customers can shop online, pay electronically, and request home delivery or branch pickup. Staff manage products, branch inventory, orders, payments, and fulfilment.

The portfolio uses PostgreSQL for structured operational data and MongoDB for data whose shape or access pattern benefits from a document model. All names and records used in the project are fictional.

## Portfolio roadmap

| Portfolio | Focus | Status |
| --- | --- | --- |
| 1 | Database design and modelling | Complete |
| 2 | Query processing and optimisation | Complete |
| 3 | Transactions and concurrency | Complete |
| 4 | NoSQL and advanced data models | Complete |
| 5 | Distributed and cloud databases | Complete |

## Repository structure

```text
advanced-database-portfolio/
|-- portfolio-1-database-design/
|-- portfolio-2-query-optimisation/
|-- portfolio-3-transactions-concurrency/
|-- portfolio-4-nosql/
|-- portfolio-5-distributed-cloud/
`-- README.md
```

Each portfolio directory contains its implementation evidence and a README explaining the design, commands, tests, and observations.

## Final documentation

- [LMS portfolio documentation](output/pdf/Okooboh_Timothy_301915902_Portfolio_Documentation.pdf) - verified three-page A4 PDF.
- [Editable summary source](final-documentation/Okooboh_Timothy_301915902_Portfolio_Summary.md).
- [AI use declaration](AI_USE_DECLARATION.md).
- [References](REFERENCES.md).
- [Final submission checklist](FINAL_SUBMISSION_CHECKLIST.md).

## Local execution

Start the PostgreSQL and MongoDB portfolio databases:

```bash
docker compose up -d
docker compose ps
```

Run the isolated logical-replication exercise:

```bash
./portfolio-5-distributed-cloud/scripts/setup_and_verify_replication.sh
```

Every portfolio README contains its exact commands, expected evidence, and validation steps. Credentials in the Compose files are development-only defaults; `.env` is ignored by Git.
