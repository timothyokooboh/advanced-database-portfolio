# Final Submission Checklist

## Completed technical checks

- [x] AsterMart is clearly identified and used consistently across all five portfolios.
- [x] Portfolio 1 includes the ER model, relational schema, keys, constraints, and normalization explanation.
- [x] Portfolio 2 includes SQL queries, results, before/after execution plans, indexes, and measured analysis.
- [x] Portfolio 3 includes commit, rollback, isolation, row locking, concurrency output, and automated postcondition checks.
- [x] Portfolio 4 includes a MongoDB document model, validation, indexes, queries, explain evidence, and suitability analysis.
- [x] Portfolio 5 includes executable logical replication, initial and incremental synchronization evidence, monitoring, and distributed/cloud analysis.
- [x] PostgreSQL, MongoDB, and replication validation scripts passed locally.
- [x] All five portfolio README files explain implementation and testing.
- [x] References and an AI-use declaration are included.
- [x] The LMS documentation is three A4 pages and names the organisation, activities, repository, evidence, reflection, references, and AI use.
- [x] The PDF filename follows `Surname_Firstname_StudentID_DocumentType` with no spaces.
- [x] The submission folder is named `Okooboh_Timothy_301915902`.
- [x] No `.env` file or real credentials are tracked; committed passwords are explicitly local development defaults.
- [x] The local Git working tree was reviewed and `main` was synchronized with `origin/main` after the final commit.

## Student actions before the one-attempt LMS submission

- [ ] Read the final reflection and AI declaration and revise them if they do not accurately express your own experience and understanding.
- [ ] Open the PDF yourself and confirm your name, student ID, module, repository link, and page count.
- [ ] In GitHub, grant the assessor access to the private repository and verify the link while signed out or using the assessor invitation state.
- [ ] Confirm that the institution accepts PDF for the LMS documentation.
- [ ] Upload `Okooboh_Timothy_301915902_Portfolio_Documentation.pdf` using the submission form, not the original question document.
- [ ] Confirm the similarity/originality result is within the permitted threshold and that citations/bibliography are excluded where applicable.
- [ ] Perform the LMS preview/download check before pressing the final submit button because the assessment allows one attempt.

## Technical verification preparation

Be ready to explain:

1. why `order_item.unit_price` is a historical snapshot rather than a normalization error;
2. why each performance index matches its query predicate/order;
3. how `SELECT ... FOR UPDATE` prevented overselling;
4. why MongoDB availability is a projection and PostgreSQL is authoritative at checkout;
5. why logical replication improves reporting but is not automatic high availability;
6. what was corrected after testing and what trade-offs remain.
