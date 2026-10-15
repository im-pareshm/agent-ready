# Changelog

All notable changes to this skill. Versions are git tags; the procedure in
`SKILL.md` is the thing being versioned — a change to a principle or a step is a
minor bump, a change to a reference doc or script pattern is a patch.

## Unreleased

- This repo's own decisions move to `docs/decisions/` (eight records and an
  index), following principle 9; AGENTS.md "Decisions to preserve" now holds the
  rule, the index link and the four most at risk.
- Principle 9: decisions are part of the change (minor). A choice someone could
  reasonably undo — a dependency, a pattern over an obvious alternative, a scope
  cut, a trade-off, a reversal — is recorded in the same commit: one file per
  decision (`docs/decisions/NNNN-slug.md`) and a one-line row in an index with
  status, date and who decided; the file is authoritative. An agent's own choice
  is *proposed* until the human accepts it; reversing one supersedes it, and
  accepted records are never deleted. Existing ADR conventions win. New
  `reference/decision-records.md`; DECISIONS.md (ADR-lite) is replaced by these
  records in tier 3; AGENTS.md "Decisions to preserve" becomes the rule, the
  index link and the few decisions most at risk; the ownership table gets a
  decisions row; audit checks records against code both ways
  (`reference/audit-checklist.md` §15).
- Coverage summary, locally and in CI — report only (minor). Discovery records
  whether the runner writes lcov and at what dependency cost; Step 2 offers the
  summary; bootstrap copies `scripts/coverage-summary.sh` into the repo and wires
  a job-summary step (`reference/ci-principles.md` §12, with an lcov-flags table
  per runner). The tests rule gains "run the summary before finishing; a changed
  file at 0% or not in the report isn't reached". Coverage percentages never go
  in docs; audit treats one as a finding (`reference/audit-checklist.md` §2).
- `scripts/coverage-summary.sh` (patch): one or more lcov files → a Markdown
  coverage report — totals per file (suites not merged), and with `--base` each
  changed file's coverage, flagging 0% and changed source files missing from the
  report. Report only: exit 0 whatever the numbers, 2 for bad input. Resolves
  absolute (POSIX, Windows, Git Bash) and package-relative `SF:` paths to
  repo-relative ones. CI smoke-tests it on an inline lcov.
- Principle 8: tests are part of the change (minor). A bug fix lands with a test
  that fails without the fix; new or changed behaviour lands with a test at the
  cheapest layer that can see it; a refactor changes no assertions; a layer with
  no harness is parked in KNOWN_ISSUES.md, never skipped silently. Discovery maps
  each kind of change to where its test goes; Step 2 asks about untested layers
  and an optional CI gate; AGENTS.md "Testing" gets the rule text and a "where
  tests go" table (`reference/agents-md-structure.md` §9), checked in Step 4.
  CI gains the test-gate shape — a diff check with a `Test-exempt:` trailer, not a
  coverage threshold (`reference/ci-principles.md` §11). Audit checks commits since
  the rule was adopted for untested behaviour (`reference/audit-checklist.md` §14),
  and a bug fixed during an audit comes with its failing test.
- "Docs are part of the change" covers omission, not just drift (minor).
  Principle 3 and the rule text now require documenting new behaviour in the same
  commit, alongside fixing what the change made untrue: a falsification test only
  fires on a statement that exists, so behaviour no doc mentioned used to satisfy
  the rule by saying nothing. The self-check is now two-directional — the grep for
  drift, the ownership table read backwards for omission, which no script can do
  (`reference/agents-md-structure.md` §6, `reference/docs-ownership.md`). Audit
  mode gains a code→docs pass and an *Undocumented* triage bucket
  (`reference/audit-checklist.md` §13); bootstrap's verify step gains the backwards
  check. Ownership-table rows must now name the kind of change recognisably
  enough to match a diff against, since that is what the backwards read needs.
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
