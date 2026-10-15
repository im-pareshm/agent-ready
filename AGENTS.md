# AGENTS.md

This repository *is* a skill: a procedure (`SKILL.md`) plus reference docs and two
shell scripts that make other repositories ready for AI-assisted development. It was
set up by following its own procedure. If something here is wrong, that's a bug in
the procedure too.

## What this is

A tool-agnostic skill that produces **verified, self-maintaining docs** for coding
agents — `AGENTS.md` plus tool pointers, `KNOWN_ISSUES.md`, and docs derived from
code — and the conventions that keep them true. For any developer using any AI
coding tool; extracted from a real project (`examples/atlas/`).

Out of scope by decision (from the design discussion, 2026-09-16): CI templates
(the stack decides; the skill ships principles), generating requirements or design
docs (intent comes from the human), and any claim that agents will *follow* the
docs — the skill can only make them true. See
[0006](docs/decisions/0006-out-of-scope.md).

## Status

Initial release in progress: procedure, eight reference docs, three scripts, the
ATLAS example, and CI are written. Not yet: a second worked example on a non-Node
stack, and the optional "interface inventory" audit sub-step noted in SKILL.md.

## Commands

There is no build. Everything runs with `sh`, `git`, `grep`, `awk` — verified on Git
Bash (Windows), and in CI on Ubuntu.

- `sh -n scripts/<name>.sh` — parse check; the cheap gate.
- `npx --yes shellcheck -s sh scripts/*.sh` — lint (CI installs shellcheck via apt;
  locally `npx` fetches a binary). Both scripts pass clean; keep it that way.
- `sh scripts/scan-secrets.sh [repo]` — the secrets scan. Exit 0 clean, 1 findings,
  2 not a git repo. Run it on this repo before every push: it must exit 0.
- `sh scripts/doc-drift.sh [range|--ids-only]` — doc-mention lookup for a diff. Always
  exits 0; prints a message for an invalid range.
- `sh scripts/coverage-summary.sh [--base <ref>] <lcov>...` — lcov → Markdown
  coverage report: totals per lcov file, and with `--base` each changed file's
  coverage, flagging 0% and changed source files missing from the report. Exit 0
  report printed (never fails over a number), 2 bad usage / unreadable lcov /
  unknown ref. Verified 2026-10-15 on Git Bash against a hand-written fixture
  (Windows `SF:` paths, CRLF, relative paths) and real `node --test` lcov
  output (Node 24).

Manual test against a real repo: run `scan-secrets` and `doc-drift` inside a clone of
`examples/atlas`'s source (https://github.com/im-pareshm/ATLAS). Expected as of
2026-09-16: `scan-secrets` reports 0 HIGH, 4 REVIEW (the historical test password in
four commits), 2 INFO; `doc-drift d8844df~1..d8844df` resolves `setCap` to one
`API.md` row.

## Key implementation facts

- `SKILL.md` frontmatter (`name`, `description`) is the trigger: the description is
  what a tool matches a request against. Keep it a plain list of the phrasings
  people actually use.
- Scripts write nothing to the target repo; they print. Temp files go to a
  `mktemp -d` directory removed on exit.
- `scan-secrets.sh` scans **added lines only** across `git log -p --all`, skips
  lockfiles/minified/vendored/binary paths, and excludes Markdown from the REVIEW
  bucket (docs quote example values). Placeholders are filtered by a pattern list
  in the script — `not-a-real`, `ci-only`, `<…>`, `${…}`, `example`, and dotted
  references like `TEST_USER.password`.
- `doc-drift.sh` reads hunk headers as well as changed lines — that is how a
  body-only change to `setCap` still yields the identifier `setCap`. Basenames of
  changed files count only when unique in the repo (eight `actions.ts` files would
  otherwise make "actions" an identifier).
- `coverage-summary.sh` makes every `SF:` path repo-relative: backslashes become
  `/`, `D:/` and `/d/` are one form, absolute paths lose the repo-root prefix, and
  relative paths are tried against each directory from the lcov file's up to the
  root (Vitest writes them relative to the package). The lcov directory comes from
  `git rev-parse --show-prefix`, not `pwd` — Git Bash's `/tmp` mount gives `pwd`
  a different spelling of the same directory. "Changed" means since the merge
  base, plus uncommitted and untracked files, so it works before a commit too.
- All scripts avoid bash-isms deliberately: no arrays, no `[[`, no `local`.

## Source-of-truth docs

- **`SKILL.md`** — the procedure. Authoritative for *what the skill does*.
- **`reference/*.md`** — the detail each step points to. Authoritative for *how*.
- **`README.md`** — for developers: problem, modes, install, usage. Never the place
  for procedure detail; link to `SKILL.md` or `reference/`.
- **`examples/atlas/`** — a real result; `after-*` files are verbatim copies of the
  source repo at a stated date and are refreshed by copying, not editing.
- **`CHANGELOG.md`** — versions. A change to a principle or a step is a minor bump;
  a reference-doc or script-pattern change is a patch.
- **`KNOWN_ISSUES.md`** — parked problems. Skim before starting work.
- **`docs/decisions/`** — one record per decision, indexed in its `README.md`.
  Authoritative for *why* something is the way it is.

Don't duplicate content across these; link.

## Docs are part of the change

If your change makes any statement in a doc untrue, fix that doc in the same
commit. If it adds behaviour no doc states — a new script, flag, exit code,
principle, step or reference doc — document that in the same commit too. Which
doc:

| If you change… | Update |
|---|---|
| A principle, a mode, a step, the tier model | `SKILL.md`; the matching sections of `README.md`; `CHANGELOG.md` (minor) |
| The detail behind a step | the `reference/*.md` that owns it; `SKILL.md` only if the step's *summary* changed |
| A script's behaviour, flags, exit codes or patterns | the script's header comment; "Commands" here; `README.md` layout table if the purpose changed; `CHANGELOG.md` (patch) |
| Which tools get pointer files | `reference/agents-md-structure.md` (the pointer table); `README.md` |
| The example | re-copy from the source repo, update the date in `examples/atlas/README.md` |
| CI | `.github/workflows/ci.yml`'s header comment; "CI" here |
| How commits, tags or releases are made | "Git" here; `CHANGELOG.md`'s header if what a version means changes |
| A decision: a script's language or dependencies, a template added, scope, a convention, reversing an earlier one | a new record in `docs/decisions/` and its index row; the one-liners in "Decisions to preserve" if it's one an agent would undo |

Self-check before finishing, both directions:

- *Drift* — `sh scripts/doc-drift.sh` on your own diff, and re-read every doc it
  names. Note it excludes `*.md`, so a docs-only change gives "no changes to
  inspect"; that is the script working, not a clean bill of health.
- *Omission* — read the table above backwards: for the kind of change you just
  made, does the doc it names describe it now? No script catches this.

## Decisions to preserve

**Decisions are part of the change.** A change that makes a choice someone could
reasonably undo — a dependency, a pattern over an obvious alternative, a scope
cut, a trade-off — records it in the same commit: a new file in
`docs/decisions/` and a row in its index. If you made the choice yourself, its
status is *proposed* until Paresh accepts it. Reversing a decision is a new
record that supersedes the old one; accepted records are never deleted. Format:
`reference/decision-records.md`.

Index: [docs/decisions/README.md](docs/decisions/README.md) — check it before
changing a script's language, adding a template, or touching history. The ones
most often undone by accident:

- Scripts are POSIX sh, no runtime dependency — [0003](docs/decisions/0003-posix-sh-scripts.md)
- No templates for stack-specific output — [0002](docs/decisions/0002-no-stack-specific-templates.md)
- Examples are real — [0005](docs/decisions/0005-examples-are-real.md)
- Never rewrite history unless explicitly asked — [0007](docs/decisions/0007-never-rewrite-history.md)

## Testing

No automated test suite for the scripts yet — `shellcheck`, `sh -n`, and the
self-scan in CI are the gates, plus the manual run against the ATLAS repo described
under Commands. A fixture-based test (a tiny generated git repo with a planted
token, a planted `.env`, and a doc that mentions a changed function) is the obvious
next step and is listed in KNOWN_ISSUES.md.

Tests are part of the change (principle 8) here too. Until that harness exists, a
script change is covered by the manual run under Commands — the ATLAS clone for
`scan-secrets` and `doc-drift`, a hand-written lcov fixture plus real runner
output for `coverage-summary` — and its result goes in the commit message; once
the harness exists, a script change adds a fixture case.

## CI

`.github/workflows/ci.yml`, on every PR and every push to `main`: parse every
script with `sh -n`, `shellcheck` them, run `scan-secrets.sh` against this repo
(must exit 0), smoke-run `doc-drift.sh HEAD~1`, and run `coverage-summary.sh` on
a two-line inline lcov (must print `50.0% (1/2)`). One job; nothing here is slow
enough to split.

## Git

- Linear history on `main`, no merge commits (six commits, one author, as of
  2026-09-20). Branch protection: Unknown — check the repository settings on
  GitHub; `gh` is not installed locally.
- **Never touch history unless explicitly asked**
  ([0007](docs/decisions/0007-never-rewrite-history.md)): no amend, rebase, reset
  or force-push on any branch without an instruction that names it. New commits
  only.
- **Subjects are `Scope: what changed`**
  ([0008](docs/decisions/0008-commit-subjects-scope-what-changed.md)): the scope
  is the area touched — Scripts, Reference docs, Example, CI, Release, Procedure,
  Dogfood — then what changed, in plain words. "Scripts: scan-secrets.sh and
  doc-drift.sh (POSIX sh)". No hooks, no `core.hooksPath`, no signing config —
  match it by hand.
- Before every push: `sh scripts/scan-secrets.sh` exits 0, and `sh -n` +
  shellcheck if a script changed (see Commands). CI repeats both.
- Releases are tags (`v0.1.0`) on a commit that moves CHANGELOG.md's "Unreleased"
  entries under the version. A change to a principle or step goes through an
  issue first (README, Contributing).

## Credentials

None. The scripts print findings; they never read or store credentials. Test
fixtures, when added, must use obviously-fake planted values (`not-a-real-…`) — the
scan's own placeholder filter would otherwise flag them.
