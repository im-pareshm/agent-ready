# Example: ATLAS

A real repo, before and after. [ATLAS](https://github.com/im-pareshm/ATLAS) is a
single-user personal-finance app (Next.js 16, Prisma 7 on libSQL/Turso, Auth.js,
Playwright, Vitest). The procedure in this skill was extracted from the work of
making it agent-ready, so this folder is both the origin of the principles and the
reference output.

| File | What it is |
|---|---|
| [before-CLAUDE.md](before-CLAUDE.md) | The agent instructions as they stood (62 lines, Claude-only) |
| [after-AGENTS.md](after-AGENTS.md) | The tool-agnostic briefing after bootstrap + audit (~230 lines) |
| [after-KNOWN_ISSUES.md](after-KNOWN_ISSUES.md) | The parked-fix ledger (one entry remaining; the big one was fixed and deleted) |

## What the "before" doc claimed, and what was true

The before doc wasn't careless. It was *plausible*. That is the whole problem.

| Claimed | Actually |
|---|---|
| "there is no test suite yet" | 12 Playwright spec files had existed for a month. 6 didn't compile (238 type errors: specs calling page-object methods that never existed, against screens with no test IDs). The tests also reset whatever database the env pointed at — the developer's own |
| "Local dev password is `atlas-dev-1234`" | True — and the same string was the CI password and the e2e password, in three commits, in a repo about to go public |
| Money formatting uses "minus sign U+2212" | The formatter emitted an ASCII hyphen. A later revision *changed the doc* to describe the bug as "pre-existing discrepancy" rather than fixing one character |
| The design doc (linked as authoritative) described a Budget Planning screen, a quick-add FAB, a left sidebar, a date column with filters on Expenses | None existed. The nav was a top bar; the dashboard had been redesigned around a different hero number; recurring templates had gained intervals. None of it was in any doc |
| Design doc's data model: Prisma enums, `Budget { cap }`, `PersonLedgerEntry` without `pending` | SQLite has no enums (strings validated in the app); `Budget` also held income/additional; `pending` existed and drove the cash math; the whole `RecurringTransaction` model was undocumented |
| `.env.example`: `DATABASE_URL="file:./dev.db"` "relative to `prisma/`" | Prisma 7 resolves it from the project root. A fresh clone put migrations in one file and read another: "no such table" on first load |

## What the process found that wasn't drift

Reading docs closely against code surfaces bugs. Four here, all pre-existing:

1. The recurring inline-edit **Save button never submitted** (`type="button"`, no
   handler). Found when an e2e test timed out waiting for the form to close.
2. The **nav rendered four times** in the DOM (two mounts × two internal variants).
   Found by a strict-mode locator failure.
3. **Clearing the spending cap deleted the month's income** — the action removed a
   database row that a later feature had started storing other fields on. Found
   while writing the interface inventory (`API.md`) and reading what each action
   did.
4. The `.env.example` path bug above. Found by *running* the README quick-start
   instead of reading it.

## What the "after" docs do differently

- **Coverage is stated with the negative:** six suites named, and "no e2e coverage
  for expenses, known, people, funds, history, categories".
- **The test incantation is written out** — every env var — so nobody runs the suite
  against their real data.
- **An ownership table** maps kinds of change to docs, and the row for "app shell"
  was added after an audit found nav changes slipping past a row that only said
  "a screen". Tables get fixed by rows, not lectures.
- **Credentials are described by where they live**, not by value.
- **A KNOWN_ISSUES entry** carried the Playwright repair for the day it was parked,
  with the workaround (`tests/` excluded from the build typecheck) named and
  guarded — and was deleted in the commit that fixed it.
- **AGENTS.md is the file; CLAUDE.md is a pointer.** Any tool gets the same briefing.

## Time cost, for calibration

Bootstrap plus the first audit: roughly two working sessions, most of it running
things rather than writing. The audit pass on two docs took under an hour and
found three screens' worth of drift. The Playwright repair — deleting six
irreparable specs, fixing six in place, adding isolation — was the largest single
piece, about half a day, and it is where three of the four bugs surfaced.
