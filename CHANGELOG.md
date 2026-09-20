# Changelog

All notable changes to this skill. Versions are git tags; the procedure in
`SKILL.md` is the thing being versioned — a change to a principle or a step is a
minor bump, a change to a reference doc or script pattern is a patch.

## Unreleased

- Git conventions are part of the procedure (minor). Discovery records how change
  enters the repo — branch model, the commit-message convention actually in the
  log, hooks and local checks, signing, host rules, releases
  (`reference/discovery.md` §5). Step 2 asks which of that is deliberate and what
  an agent must never do without asking. AGENTS.md gets a "Git" section
  (`reference/agents-md-structure.md` §11); the audit checks documented
  conventions against the log (`reference/audit-checklist.md` §9); the ownership
  table gets a row. Agent commits made by the skill follow the recorded
  convention. This repo's own AGENTS.md gets its Git section: history is never
  rewritten unless explicitly asked; subjects are `Scope: what changed`.

## v0.1.0 — 2026-09-16

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
