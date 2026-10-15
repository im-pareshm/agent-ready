# 0001. The principles are the product

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh
- **Links:** b6934d2 (AGENTS.md "Decisions to preserve"), `SKILL.md` "Principles", `README.md` "Contributing"

## Context
Without its principles, the skill is an AGENTS.md template — and a template
produces plausible docs, which is what the skill exists to prevent.

## Decision
`SKILL.md`'s principles and the verify-before-report step are what distinguish
this from an AGENTS.md template. Changes to them go through an issue, not a
drive-by PR.

## Alternatives considered
Not recorded when the decision was made.

## Cost to change
Low to edit, high to get wrong: every repo set up with the skill inherits the
principles through its AGENTS.md. A principle change is a minor version bump
(`CHANGELOG.md` header).
