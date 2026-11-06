# AI Use Declaration

## Tool used

OpenAI Codex was used as a learning and development assistant for this portfolio.

## How it was used

Codex assisted with:

- breaking the assessment into practical milestones;
- proposing the fictional AsterMart scenario;
- drafting and reviewing PostgreSQL, MongoDB, Docker Compose, shell, and documentation files;
- explaining database-design, indexing, transaction, concurrency, NoSQL, and replication concepts;
- identifying test cases and helping format the final portfolio summary.

## Review, correction, testing, and verification

All generated material was kept in a private Git repository and developed through focused commits. The SQL and MongoDB scripts were executed locally using PostgreSQL 16 and MongoDB 7 containers. Outputs, query plans, row counts, rollback behaviour, concurrency locking, schema validation, and logical replication were checked against the running databases.

Generated content was corrected when testing exposed issues. For example, the first seed-data run violated an order-total constraint and was repaired before commit; the concurrency demonstration was verified with two competing sessions; and MongoDB validation was tested with an intentionally invalid document. Official PostgreSQL and MongoDB documentation was consulted for technical claims.

The student remains responsible for reviewing, understanding, explaining, and submitting the work. This declaration should be updated if any additional AI tool or use occurs before submission.
