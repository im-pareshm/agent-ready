# Known Issues

Verified engineering problems that have a workaround in place, or fixes that were
deliberately deferred. Each entry should let someone pick the problem up cold
without redoing the investigation.

This is **not a backlog**. If something is cheaper to fix than to write up here,
fix it.

## Rules

- **Park a fix → add the entry in the same commit.** Whatever carries the debt, the
  entry lands with it.
- **Fix it → delete the entry in the same commit.** Git history is the archive.
  There is no "Resolved" section.
- **Link both ways.** Every entry names the code carrying its workaround, and that
  code comments `See KNOWN_ISSUES.md "<entry title>"`.
- **A review that ends with unfixed findings ends with entries here.**

Entry format: **Symptom** · **Cause** (verified, with pointers) · **Workaround in
place** (and why it must stay) · **Fix plan** (ends with "delete this entry") ·
**Since**.

---

## The scripts have no automated tests

**Symptom.** `scripts/scan-secrets.sh` and `scripts/doc-drift.sh` are verified by
`sh -n`, `shellcheck`, a self-scan in CI, and a manual run against the ATLAS repo
(expected results recorded in AGENTS.md "Commands"). `scripts/coverage-summary.sh`
has one CI smoke case (totals of a two-line lcov) and a manual fixture run. A
change to a pattern, the identifier extraction or the lcov path resolution has no
test that would catch a regression.

**Cause.** The scripts were written against one real repository and checked by
hand. No fixture repo exists.

**Workaround in place.** The manual checks in AGENTS.md "Commands": run
`scan-secrets` and `doc-drift` in a clone of the ATLAS repo and compare with the
recorded expectations; run `coverage-summary` on a fixture lcov and on real runner
output. They must be done before a release that touches any script.

**Fix plan.** A `tests/` directory with a POSIX script that builds a throwaway git
repo (`git init` in `mktemp -d`) containing: a planted JWT-shaped token in one
commit, a committed `.env`, an env example with a non-placeholder value, a source
file with `function setBudget` changed in its body only, and a doc that mentions
`setBudget`. Assert `scan-secrets` exits 1 with 2 HIGH and 1 REVIEW, and
`doc-drift` names `setBudget` once. For `coverage-summary`: an lcov with a
relative `SF:` under a package dir, a Windows absolute `SF:` with CRLF endings, a
changed file at 0%, and a changed source file absent from the lcov; assert both
paths resolve, the 0% row and the "not in report" row appear, and a test file and
a Markdown file are not listed. Wire it into CI, then delete this entry.

**Since.** Initial commit (2026-09-16).
