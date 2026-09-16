# Changelog

All notable changes to this skill. Versions are git tags; the procedure in
`SKILL.md` is the thing being versioned — a change to a principle or a step is a
minor bump, a change to a reference doc or script pattern is a patch.

## Unreleased

- Initial procedure: bootstrap, audit and pre-publish modes; seven principles;
  tiered outputs (always / derived / offered).
- Reference docs: discovery, AGENTS.md structure, docs ownership, known issues,
  testing safety, audit checklist, CI principles.
- `scripts/scan-secrets.sh`: history-wide token scan (added lines, every branch),
  credential-like assignments for review, working-tree and ignore coverage,
  env-example placeholder check. Exit codes 0/1/2.
- `scripts/doc-drift.sh`: identifiers from a diff (including hunk-header
  declarations and unique file basenames) → every Markdown line mentioning them.
- `examples/atlas/`: before/after from the repo the procedure was extracted from.
- This repo's own AGENTS.md, CLAUDE.md and KNOWN_ISSUES.md, produced by the
  procedure; CI that parses, lints and self-scans.
