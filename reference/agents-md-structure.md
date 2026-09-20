# AGENTS.md — section by section

AGENTS.md is read at the start of every agent session. It has two jobs: tell the
agent what is true, and tell it where to look. It is not a place for detail — detail
lives in the owning doc, linked. Target under ~250 lines; when a section outgrows
that, it has become its own doc.

Order matters a little: put what an agent needs in the first five minutes first.

## 1. What this is (intent)

Two to five lines, **from the human's answer**, attributed if the wording is theirs.
One sentence on what it does and for whom; one on the core idea if there is one;
then the non-goals and deferrals as a short list.

```
ATLAS is a single-user monthly money worksheet: plan what's due, tick it off as
paid, keep casual spending under a cap, always know the cash left. INR only.
Out of scope by decision: multi-currency, multiple accounts. Deferred to v2:
full investment tracking, CSV import.
```

Not here: marketing copy, feature lists (that's the README), anything you inferred
rather than were told.

## 2. Status

One paragraph: what is built, what is in progress, what the next step is. Dated
if it will go stale ("as of 2026-09"). If there are parked problems, one line
pointing at KNOWN_ISSUES.md.

## 3. Commands

Every command an agent will need, each **verified by running it**, with one clause
on what it is for and any gotcha you hit:

```
- `npm run build` — production build + full typecheck; use this as the check.
- `npm run db:migrate` — `prisma migrate dev`. After a migration, restart the dev
  server: it caches the old generated client.
```

Not here: commands you didn't run, commands that exist but nobody uses, the
package manager's generic help.

## 4. Key implementation facts

The things a stranger would otherwise spend an hour discovering: where the money
math lives, how auth is split, what the routes are, which file is the composition
root, naming quirks (`proxy.ts` is Next 16's middleware). Bullets, each one a fact
with a file path.

Not here: explanations of the framework, code walkthroughs, anything the code
comments already say.

## 5. Source-of-truth docs

The list of docs that own something, one line each on what they own, and which
wins when two disagree. Mark superseded docs as superseded. End with the
instruction not to duplicate their content in AGENTS.md.

## 6. Docs are part of the change

The rule, then the ownership table. See `docs-ownership.md` for building the
table. The rule text that has worked:

> If your change makes any statement in a doc untrue, fix that doc **in the same
> commit**. Never leave a note saying a doc is outdated — fix the doc. Cheap
> self-check before you finish: grep the `*.md` files for the names you touched
> (function, route, script, env var, screen); if one appears, re-read that passage
> and decide whether it still holds.

## 7. Decisions to preserve

The patterns that are deliberate, each with the **why** the human gave. This is the
section that stops an agent "simplifying" something load-bearing. Format:

```
- **Money is integer paise.** Floats round; SQLite has no Decimal. Forms post
  rupees, actions convert once, nothing stores a float.
- **Lazy recurring generation on page load, no cron.** Personal-scale app; "next
  time I open it" is soon enough, and it needs no infrastructure.
```

If a decision has grown a page of context, that page is `DECISIONS.md` and this
section links to it.

Not here: decisions you inferred without confirmation — those go in the report's
"needs you" list until confirmed.

## 8. Data model (if there is one)

Five lines naming the entities and the one or two things about them that surprise
people (enums are strings; the budget row also holds income). Link to the schema
file and the data-model doc. The ER diagram lives in the doc, not here.

## 9. Testing

What suites exist and **what each actually covers** — with the negative stated:

```
Six e2e suites: auth, dashboard, navigation, recurring, accessibility, attention.
No e2e coverage for expenses, known, people, funds, history, categories.
```

Then: the conventions the tests rely on (isolation helper, where helpers are
imported from, selector scoping), and the **exact incantation** for running the
suite against a throwaway store — every env var, every flag. See
`testing-safety.md`. This is the paragraph that prevents someone wiping their
local database.

## 10. CI

What runs where: which jobs on PRs, which on the default branch, why the split.
Name the default branch. If a job is expected to be red, say why and link the
KNOWN_ISSUES entry.

## 11. Git

How change enters the repo, **as observed** — not the workflow you would choose.
Each line is a fact from the log, the hooks, the host's settings, or the human's
answer. An agent reads this section right before its first commit; make it enough
to produce a commit that looks like the others.

- **Branch model.** Commits land on the default branch directly, or via branches
  and PRs (merged how: merge commit, squash, rebase). The branch naming in use.
  Whether the default branch is protected and what it requires —
  `Unknown — check <host> settings` if you couldn't see it.
- **Commit messages.** The convention the log actually follows, with a real
  subject quoted. Say "Conventional Commits" only if the log uses it or a hook
  enforces it; otherwise describe what is there ("`Scope: what changed`, imperative,
  no body unless the why isn't obvious").
- **Checks before commit or push.** What the hooks run (`.husky/`, pre-commit,
  lefthook, `core.hooksPath`) and the manual equivalent for an agent whose tooling
  skips hooks. Whether commits are signed.
- **What needs asking first.** The git actions this repo cares about an agent not
  taking alone: force-push, rewriting published history, pushing to the default
  branch, amending someone else's commit. List only the ones that apply here,
  with the reason (e.g. "users update with `git pull`"); don't list all four by
  reflex. Pre-fill the Step 2 question with "never rewrite history — amend,
  rebase, reset, force-push — unless explicitly asked"; the human confirms or
  narrows it, and it goes in attributed and dated.
- **Releases.** Tags, a version file, a changelog — and which commit bumps them.

```
Linear history on `main`, no merge commits. Never touch history unless explicitly
asked (decision, 2026-09-20); on `main` users also update with `git pull`.
Subjects are `Scope: what changed` ("Scripts: scan-secrets.sh and doc-drift.sh
(POSIX sh)"); no hook enforces anything. Before every push:
`sh scripts/scan-secrets.sh` exits 0. Releases are tags (`v0.1.0`) on a commit
that updates CHANGELOG.md.
```

If the human wants a convention the log doesn't yet show, write it as the rule,
attributed, and say that history before that date predates it — so the log and the
rule don't look like a contradiction to the next reader.

Not here: git tutorials; a branching model the repo doesn't use; message rules no
hook enforces and no human asked for; the pre-publish checklist (that's the
skill's, run once).

## 12. Credentials

Where each kind lives and the rule that none lives in the repo:

```
Local dev: ADMIN_EMAIL/ADMIN_PASSWORD in the gitignored .env, consumed by the
seed. E2E/CI: the fixed, obviously-fake account in tests/helpers/test-data.ts,
mirrored in ci.yml. Production: set at deploy time, must differ from both. The
repo is public.
```

## 13. Known issues pointer

One line: "Before starting work, skim KNOWN_ISSUES.md; if your task touches a
listed item, fix it or update the entry in the same commit." The rules live in
that file, not here.

## Things that never belong in AGENTS.md

- Content copied from another doc (link instead).
- Private local values: a dev password, a personal path. Say where they live.
- Historical narrative ("we originally planned…"). Mark the old doc superseded.
- Anything tool-specific. `CLAUDE.md` and friends are pointers to this file.
- Aspirations. If it isn't true yet, it goes in Status as "next", or in a
  KNOWN_ISSUES entry, not in a section that reads as fact.

## Pointer files

Each is the same short paragraph. Write only the ones for tools in use, plus any
the human names:

| Tool | File |
|---|---|
| Claude Code | `CLAUDE.md` |
| GitHub Copilot (editor chat) | `.github/copilot-instructions.md` |
| Gemini CLI | `GEMINI.md` |
| Codex, Cursor, Jules, Amp, Zed, Copilot coding agent | read `AGENTS.md` directly — no file |

```
# CLAUDE.md

This project's guidance for coding agents lives in AGENTS.md — read it first. It
applies to <tool> exactly as written. This file exists only so a tool that looks
for <this filename> still finds guidance. If you edit the guidance, edit AGENTS.md,
not this file, so the two never drift apart.
```

## Monorepos

A root AGENTS.md carries intent, the shared rules, the ownership table and the
cross-package facts. Each package gets its own AGENTS.md with its commands, tests
and facts, and a first line pointing at the root. Don't duplicate the rules
downward.
