# AGENTS.md

## Working agreement

Before changing a module, read [`README.md`](README.md),
[`references.md`](references.md) and the module's own README. Treat executable
Terraform, tests and CI as the implementation authority when an older design
document disagrees. Treat [`references.md`](references.md) as the authority for
external contracts (Terraform, AWS Backup, DynamoDB); record material drift in
the ticket and update the affected doc.

## References

Authoritative external sources live in [`references.md`](references.md). If a
module or test disagrees with a source there, treat it as a defect: fix it or
record the drift in the ticket. A new external contract gets a row in
`references.md` in the same change that depends on it.

## Agent skills

### Issue tracker

Issues live as GitHub issues (use the `gh` CLI), on the `jit-guard` monorepo
tracker until the split completes.

### Triage labels

Use the repo's label vocabulary: `triage`, `ready-for-agent`, `ready-for-human`,
`wontfix`.

### Module docs

Each module keeps its own `README.md`; `references.md` is the external-source
index for the repo.
