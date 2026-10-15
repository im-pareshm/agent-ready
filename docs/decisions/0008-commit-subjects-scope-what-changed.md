# 0008. Commit subjects are `Scope: what changed`

- **Status:** accepted
- **Date:** 2026-09-20
- **Decided by:** Paresh
- **Links:** 10f9b92, AGENTS.md "Git"

## Context
Every commit before the decision already followed this form; the decision made
it the rule.

## Decision
The subject is the area touched — Scripts, Reference docs, Example, CI, Release,
Procedure, Dogfood — then what changed, in plain words: "Scripts: scan-secrets.sh and
doc-drift.sh (POSIX sh)". No hook enforces it; match it by hand.

## Alternatives considered
Conventional Commits: rejected because nothing here consumes a `type:` prefix
(`CHANGELOG.md` is written by hand), so the ceremony would buy nothing.

## Cost to change
Applies to future commits only; existing history keeps the old form
([0007](0007-never-rewrite-history.md)).
