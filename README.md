# agent-ready

[![CI](https://github.com/im-pareshm/agent-ready/actions/workflows/ci.yml/badge.svg)](https://github.com/im-pareshm/agent-ready/actions/workflows/ci.yml)

**Verified, self-maintaining docs for AI-assisted development.** A skill that makes a
repository ready for any coding agent — Claude Code, Codex, Cursor, Copilot, Gemini
CLI, or a human starting cold — by producing documentation the agent can trust, and
the conventions that keep it true afterwards.

It writes `AGENTS.md` (plus a pointer for every tool), `KNOWN_ISSUES.md`, and — only
where the code has the substance for it — a data-model doc with an ER diagram and an
interface inventory. Then it **verifies every claim** before reporting.

## The problem

Every AI coding tool now reads `AGENTS.md`. Most repos have none, or have one written
in five minutes that is wrong within a week. Agents read it and believe it.

The repo this skill was extracted from ([examples/atlas/](examples/atlas/)) *had* an
AGENTS.md. It said the end-to-end suite "covers auth, every screen, and
accessibility" — 5 of 12 spec files worked. Its design doc described a Budget
Planning screen that was never built and a navigation sidebar that didn't exist. A
note had been added bending the spec to match a formatting bug rather than fixing
the bug. None of this was carelessness. An agent wrote what seemed plausible.

**Plausible docs are worse than no docs.** This skill exists to produce the other
kind.

## What it does

Three modes:

| Mode | When | What you get |
|---|---|---|
| **bootstrap** | No agent docs, or boilerplate | The full set of files below, every command in them run, a secrets scan, and a report of what still needs you |
| **audit** | Docs exist; are they true? | A findings table — claim by claim, doc against code — with drift fixed in place, product questions asked, parked items filed |
| **pre-publish** | About to go public | History-wide secrets scan, test-credential hygiene, ignore coverage, branch/CI consistency, license, README |

### What gets generated

The skill separates what can be **derived from code** (and verified) from what only a
**human knows** (and must be asked for). It never invents the second kind.

| Tier | Files | Source |
|---|---|---|
| **Always** | `AGENTS.md` with an Intent section · `CLAUDE.md` and pointers for the tools you use (`.github/copilot-instructions.md`, `GEMINI.md`, …) · `KNOWN_ISSUES.md` | Your answers + verified discovery |
| **Derived, when there's substance** | Data-model doc with a Mermaid ER diagram · interface inventory (`API.md`) · a verified README quick-start | The code |
| **Offered, needs you** | `DECISIONS.md` (ADR-lite: the agent lists the patterns it observed, you supply the *why*) · `USER_GUIDE.md` (screen-by-screen draft from the code, you add the workflow) | Code-seeded, human-completed |

Also, when discovery finds the gap: a CI workflow shaped for your stack, an env
example whose paths actually work, `.gitignore` additions for uncovered secrets.

Nothing is created as a stub. If a repo has nothing to derive, a single complete
`AGENTS.md` is the right output — it is the fallback owner for every kind of
knowledge until a section outgrows it.

### What it deliberately doesn't do

Write requirements or design docs (it can't know them; it inventories and links
whatever exists) · generate lint or formatter config · impose a folder layout,
branching model or commit format on a repo that has one (it records the one in
use, and asks what an agent must never do alone) · promise agents will follow the
rules. It documents what *is*, verifiably, and gives future changes a place to
land.

## The principles

Each one was earned the hard way in the example repo.

1. **Verify, don't invent.** A command is documented after it was run. A coverage
   claim after it was counted. Unknowns are written as *Unknown*, never guessed.
2. **Intent comes from the human.** Purpose, non-goals, deferrals, and the *why*
   behind decisions are asked for and attributed.
3. **Docs are part of the change.** An ownership table in AGENTS.md maps kinds of
   change to the docs they affect; the rule is fix-in-the-same-commit.
4. **A parked fix gets an entry.** Exclusions, skips and workarounds go in
   `KNOWN_ISSUES.md` in the commit that parks them, linked both ways to the code.
   Fixing it deletes the entry.
5. **Tests must be safe to run.** Know what a suite resets before running it; point
   it at a throwaway store; import app helpers into tests, never copy them.
6. **AGENTS.md stays small and tool-agnostic.** Pointers, not copies, for each tool.
7. **Respect what exists.** Layouts, docs and conventions are mapped, not replaced.

## Install

The skill is a folder with a `SKILL.md` — the open Agent Skills format — so one copy
serves every tool that reads it.

**Claude Code, available in every repo:**

```bash
git clone https://github.com/im-pareshm/agent-ready.git ~/.claude/skills/agent-ready
```

**Any tool that reads project skills from `.agents/skills/`** (add it to one repo):

```bash
git clone https://github.com/im-pareshm/agent-ready.git .agents/skills/agent-ready
```

Update with `git pull` in the same folder. Releases are tagged; see
[CHANGELOG.md](CHANGELOG.md).

## Use

In Claude Code, from the repo you want to set up:

```
/agent-ready                      # picks a mode from the state of the repo and says which
/agent-ready bootstrap
/agent-ready audit
/agent-ready pre-publish
```

In other tools, ask in plain words — "make this repo agent-ready", "audit the docs
against the code", "check for leaked secrets before I publish" — and the skill's
description triggers it.

Expect a conversation on first run. Discovery is automatic; the intent questions
(what is this for, what's out of scope, why is that pattern there) are not, and the
skill won't guess them.

## What it looks like

[examples/atlas/](examples/atlas/) holds the `AGENTS.md` and `KNOWN_ISSUES.md` from
a real personal-finance app, with a before/after of what the docs claimed versus
what the code did. Reading the docs closely also surfaced four real bugs there — a
Save button that never submitted, a nav rendered four times, a cap-clearing action
that deleted the month's income, and an env example whose database path sent a fresh
clone to the wrong file. Audit mode finds bugs. Expect it.

## Repository layout

```
SKILL.md                    the procedure — what an agent reads
reference/                  the detail each step points to
  discovery.md              stack-agnostic discovery checklist
  agents-md-structure.md    what belongs in each AGENTS.md section, and what doesn't
  docs-ownership.md         building the ownership table
  known-issues.md           KNOWN_ISSUES.md rules and entry format
  testing-safety.md         throwaway stores, isolation, single-source helpers
  audit-checklist.md        the claim types that drift, and how to check each
  ci-principles.md          the shape of a sound workflow, whatever the stack
scripts/
  scan-secrets.sh           history + working-tree secrets scan (POSIX sh, git, grep)
  doc-drift.sh              identifiers in a diff → every doc line mentioning them
examples/atlas/             a real result, with before/after
AGENTS.md                   this repo's own, produced by the skill
CLAUDE.md                   pointer to AGENTS.md (what the skill writes for Claude Code)
KNOWN_ISSUES.md             this repo's own parked-fix ledger
CHANGELOG.md                versions; the procedure is what's versioned
.github/workflows/ci.yml    parse + shellcheck + self-scan
```

## Contributing

Pattern additions to `scripts/scan-secrets.sh`, new tool pointer formats, and
discovery rules for stacks not yet covered are the most useful contributions. Open
an issue first for anything that changes the procedure in `SKILL.md` — the
principles are the product.

## License

MIT — see [LICENSE](LICENSE).
