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
docs — the skill can only make them true.

## Status

Initial release in progress: procedure, seven reference docs, two scripts, the
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

Manual test against a real repo: run both scripts inside a clone of
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
- Both scripts avoid bash-isms deliberately: no arrays, no `[[`, no `local`.

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

Don't duplicate content across these; link.

## Docs are part of the change

If your change makes any statement in a doc untrue, fix that doc in the same
commit. Which doc:

| If you change… | Update |
|---|---|
| A principle, a mode, a step, the tier model | `SKILL.md`; the matching sections of `README.md`; `CHANGELOG.md` (minor) |
| The detail behind a step | the `reference/*.md` that owns it; `SKILL.md` only if the step's *summary* changed |
| A script's behaviour, flags, exit codes or patterns | the script's header comment; "Commands" here; `README.md` layout table if the purpose changed; `CHANGELOG.md` (patch) |
| Which tools get pointer files | `reference/agents-md-structure.md` (the pointer table); `README.md` |
| The example | re-copy from the source repo, update the date in `examples/atlas/README.md` |
| CI | `.github/workflows/ci.yml`'s header comment; "CI" here |

Self-check before finishing: `sh scripts/doc-drift.sh` on your own diff.

## Decisions to preserve

- **Principles are the product.** `SKILL.md`'s seven principles and the
  verify-before-report step are what distinguish this from an AGENTS.md template.
  Changes to them go through an issue, not a drive-by PR.
- **No templates for stack-specific output.** A CI template would be wrong for
  most stacks and would be copied without thought. Principles + the agent's own
  discovery produce a workflow that fits.
- **Scripts are POSIX sh with no runtime dependency.** The audience includes
  Windows developers on Git Bash and repos with no Node or Python. Portability
  beats convenience.
- **Ship scripts *and* describe what they do.** Deterministic when they can run;
  the description lets an agent do the job by hand when they can't.
- **Examples are real.** A synthetic example would be a plausible doc — the thing
  this skill exists to prevent.

## Testing

No automated test suite for the scripts yet — `shellcheck`, `sh -n`, and the
self-scan in CI are the gates, plus the manual run against the ATLAS repo described
under Commands. A fixture-based test (a tiny generated git repo with a planted
token, a planted `.env`, and a doc that mentions a changed function) is the obvious
next step and is listed in KNOWN_ISSUES.md.

## CI

`.github/workflows/ci.yml`, on every PR and every push to `main`: parse both scripts
with `sh -n`, `shellcheck` them, run `scan-secrets.sh` against this repo (must exit
0), and smoke-run `doc-drift.sh HEAD~1`. One job; nothing here is slow enough to
split.

## Credentials

None. The scripts print findings; they never read or store credentials. Test
fixtures, when added, must use obviously-fake planted values (`not-a-real-…`) — the
scan's own placeholder filter would otherwise flag them.
