# 0005. Examples are real

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh
- **Links:** b6934d2, 99812a3, `examples/atlas/`

## Context
The skill exists to replace plausible documentation with verified documentation.

## Decision
Every example comes from a real repository. `after-*` files are verbatim copies
of the source repo at a stated date, refreshed by copying, never by editing.

## Alternatives considered
A synthetic example: rejected because it would be a plausible doc — the thing
this skill exists to prevent.

## Cost to change
Low in effort, high in credibility: a synthetic example would undercut the
skill's central claim.
