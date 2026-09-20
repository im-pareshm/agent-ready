# Building the docs-ownership table

The ownership table answers, for an agent that just changed something: *which doc
do I now have to re-read?* Without it, "keep the docs updated" is an instruction with
no way to follow it — an agent adding a screen can't know a user guide exists.

## The rule it serves

> If your change makes any statement in a doc untrue, fix that doc in the same
> commit. Never leave a note saying a doc is outdated — fix the doc.

The table makes the rule actionable; the grep self-check (`scripts/doc-drift.sh`, or
by hand: grep `*.md` for every identifier you touched) makes it checkable.

## Step 1 — enumerate the kinds of change

Start from this list and drop the rows that can't happen in the repo (a CLI has no
screens; a library has no deploy steps). Add rows for anything the repo has that
isn't here.

| Kind of change | Typical evidence in a diff |
|---|---|
| Data model / schema / migrations | schema file, migrations folder, model classes |
| Core business logic or a formula | the module the domain lives in; a derived number changes |
| A screen, page, view, or component's behaviour | UI files; labels, buttons, fields |
| The app shell: navigation, header, theme, layout | layout files, nav component |
| Visual tokens, typography, formatting rules | design tokens, CSS variables, formatters |
| Commands, scripts, file layout, entry points | manifest scripts, Makefile, new top-level dirs |
| Interfaces: routes, actions, CLI commands, public exports | handlers, actions files, command registry |
| Env vars, config, deploy steps | env example, config loaders, CI env blocks, infra files |
| Test setup, suites, coverage | test config, fixtures, new/deleted spec files |
| Feature scope: what's in, what's deferred | — (a product decision) |
| A fix you're parking | an exclusion, a `.skip`, a workaround |
| Default branch, CI triggers | workflow files |
| How change enters the repo: branch model, commit convention, hooks, releases | hook config, a PR template, CONTRIBUTING.md, tags, a version file |

## Step 2 — map each kind to the docs that exist

For each row, list every doc that *makes a statement* about that kind of thing. Use
the inventory from discovery. Include sections of AGENTS.md itself by name.

Where a kind of change has **no doc**, the owner is AGENTS.md — write the section
there. Do not create a doc to own it until there's enough content that the AGENTS.md
section is crowding the file.

## Step 3 — write the table

Two columns, "If you change…" and "Update". Keep rows short; name sections, not
just files, so the agent lands on the right paragraph. The table from the example
repo:

| If you change… | Update |
|---|---|
| Prisma schema, data model, money model | DESIGN.md (authoritative — snippets **and** the ER diagram); the "Data Model" summary here |
| A Server Action, a validation schema, a `lib/` read helper, or an auth/route change | API.md (the action tables, Reads, HTTP routes) |
| The cash formula or recurring generation | "Decisions to preserve" here; UI_DESIGN_GUIDE.md §7; DESIGN.md "Per-month math"; the header comment in `lib/cash-math.ts`; a case in `lib/__tests__/` |
| A screen's behaviour, the app shell (nav, header, theme), or a user-facing workflow | DESIGN.md "Screens" / "Navigation & theme"; USER_GUIDE.md |
| Visual tokens, typography, number formatting | UI_DESIGN_GUIDE.md; the "UI / visual spec" summary here |
| npm scripts, file layout, routes, auth wiring | "Commands" and "Key implementation facts" here |
| Env vars or deploy steps | DEPLOYMENT.md; the `env:` block of the `e2e` job in `.github/workflows/ci.yml` |
| Test setup or which suites exist | "Testing" and "CI" here; KNOWN_ISSUES.md if coverage is parked |
| Feature scope (what's in v1, what's deferred) | PRD.md |
| A fix you're parking | KNOWN_ISSUES.md — its rules are in the file |

Note what it took to get that table right: the "app shell" phrase was added *after*
an audit found that nav and theme changes had slipped past a row that only said "a
screen". When drift gets through, the fix is usually a row, not a lecture.

## Step 4 — name the docs nothing owns

Some files exist and own nothing (a boilerplate README, a superseded plan). Say so
in a line under the table, so an agent neither updates them nor trusts them:

> README.md is the public front door: what the app is, the stack, a fresh-clone
> quick-start, the doc map. Update it when those change; keep detail in the owning
> doc and link to it.

> IMPLEMENTATION_PLAN.md §2 and §9 are superseded by DESIGN.md — use DESIGN.md.

## Keeping the table true

The table is itself a doc. When a doc is added, split, or deleted, the row changes
in the same commit. When an audit finds drift that got past the table, add or
reword the row that should have caught it.
