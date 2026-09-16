---
name: agent-ready
description: Make a repository ready for AI-assisted development — verified, self-maintaining docs (AGENTS.md plus pointers for every tool, KNOWN_ISSUES.md, docs derived from the code), safe-to-run tests, a sound CI shape, and public-repo hygiene. Use when asked to set up or write AGENTS.md / CLAUDE.md, make a repo "agent-ready", audit the docs against the code, check a repo for leaked secrets before publishing, or when you start work in a repo that has no agent instructions.
---

# agent-ready

You are setting a repository up so that any coding agent — this one, a different
tool, or a person — can start cold and find out what is true, where to look, and what
to update when they change something. The output is documentation, but the job is
**verification**: every statement you write is something you ran, read, or were told
by the human. Plausible documentation is worse than none, because agents believe it.

## Principles

These are not style preferences. Each one exists because its absence caused real
damage in a real repo (see `examples/atlas/`).

1. **Verify, don't invent.** A command goes in AGENTS.md only after you ran it. A
   coverage claim goes in only after you counted. If you can't verify something,
   write `Unknown — <how to find out>`, never a guess.
2. **Intent comes from the human.** What the project is for, who it's for, what's
   deliberately out of scope, and *why* a decision was made are not in the code.
   Ask, record the answer, attribute it. Never generate a requirements doc.
3. **Docs are part of the change.** Every doc has an owner section in AGENTS.md
   saying which kinds of change affect it, and the rule is: fix the doc in the same
   commit. AGENTS.md is the fallback owner — if a doc doesn't exist, its content is a
   section in AGENTS.md until it's big enough to split out.
4. **A parked fix gets an entry.** Any exclusion, skip, workaround or deferred bug
   goes into KNOWN_ISSUES.md in the same commit that parks it, linked both ways to
   the code carrying it. Fixing it deletes the entry. No "resolved" graveyard.
5. **Tests must be safe to run.** Before you run a suite, know what it resets. Point
   it at a throwaway store. Never reimplement app logic in test helpers — import it.
6. **AGENTS.md stays small and tool-agnostic.** It loads into every session. Facts
   and rules live there; detail lives in the owning doc, linked. Tool-specific files
   are one-paragraph pointers, never copies.
7. **Respect what exists.** Existing docs, folder layout (`docs/`, ADRs, wiki),
   naming and conventions are inventoried and mapped, not replaced. Tool-read files
   must be at the repo root; everything else goes where the repo already keeps docs.

## Choose a mode

| Mode | Use when | Output |
|---|---|---|
| **bootstrap** | No AGENTS.md / CLAUDE.md, or one that is boilerplate | The full set of files (tiers below) + a report |
| **audit** | The repo has docs; check them against the code | Findings table → same-commit fixes, questions for the human, KNOWN_ISSUES entries |
| **pre-publish** | The repo is about to become public, or gets a remote for the first time | Secrets/credential/license/README/branch findings → fixes |

Modes chain: `bootstrap` ends with the `audit` verification pass; `pre-publish` is
a subset of `audit` you can run alone. If the human's request doesn't name a mode,
pick from the table and say which you picked.

## Mode: bootstrap

### Step 1 — Discover (read `reference/discovery.md`)

Collect, with evidence, before writing a word:

- **Stack and commands.** Manifest files (`package.json`, `pyproject.toml`, `go.mod`,
  `Cargo.toml`, `*.csproj`, `Makefile`, …) → package manager → the scripts/targets
  that exist. Run each one you intend to document (`--help` or a dry run where a
  real run is destructive). Record which pass.
- **Layout.** Top-level directories, entry points, where tests live, whether it's a
  monorepo/workspace (then plan a root AGENTS.md plus one per package).
- **Tests.** Frameworks, how many suites/files, what they actually cover, whether
  any test resets or seeds a database and from which env var. Do not run a suite
  until you know what it resets.
- **CI.** Existing workflows: triggers, jobs, the default branch name, whether the
  triggers match it.
- **Docs.** Every `*.md`, `docs/`, ADR folder, wiki link. For each: what it covers,
  and one spot-check of a claim against the code so you know how much to trust it.
- **Environment and secrets.** Env example files, what env vars the code reads,
  which local secret-bearing files exist (`.env*`, `*.db`, `*.pem`, …) and whether
  `.gitignore` covers them. Run `scripts/scan-secrets.sh`.
- **Interfaces and data model.** HTTP routes, server actions, CLI commands, public
  exports; schema files (ORM models, migrations, SQL). These decide whether tier-2
  docs have substance.

Keep a private evidence list: for each fact, how you know it. It feeds the report.

### Step 2 — Ask the human

Ask only what discovery cannot answer. One message, grouped, with your best guess
pre-filled where you have one so they can just confirm:

1. **Intent.** In one sentence, what is this for and who is it for?
2. **Non-goals and deferrals.** What is deliberately out of scope? What's planned but
   not built? (These stop an agent "helpfully" building them.)
3. **Decisions to preserve.** For each pattern you observed that looks deliberate
   (list them: "every amount is an integer", "no ORM", "single-user but `userId`
   on every table"), ask: is this a decision, and why?
4. **Authoritative docs.** Where two existing docs disagree, which wins? Any doc
   that is historical and should be marked superseded?
5. **Tools.** Which AI tools do they and collaborators use? (Decides which pointer
   files to write — see Step 3.)
6. **Visibility.** Is or will the repo be public? (Triggers pre-publish.)
7. **Where new docs go.** Root, or the repo's existing `docs/` folder?

Do not block on this: draft everything you can from discovery first, then ask, then
fill the intent-dependent parts.

### Step 3 — Write

Follow `reference/agents-md-structure.md` for AGENTS.md, `reference/known-issues.md`
for the ledger, `reference/ci-principles.md` for CI. Create files in tiers:

**Tier 1 — always**

| File | Content |
|---|---|
| `AGENTS.md` | What this is (intent, from the human) · Status · Commands (verified) · Key implementation facts · Source-of-truth docs · **Docs are part of the change** with the ownership table · Decisions to preserve (with the human's *why*) · Data-model summary if any · Testing (real coverage, how to run safely) · CI · Credentials rule · Known issues pointer |
| `CLAUDE.md` | Pointer to AGENTS.md; "if you edit guidance, edit AGENTS.md so they never drift" |
| `KNOWN_ISSUES.md` | Rules and entry format; entries only for things verification actually found |

**Tool pointers** (from the human's answer in Step 2; write only the ones needed).
Codex, Cursor, Jules, Amp, Zed and Copilot's coding agent read `AGENTS.md`
natively — no pointer. Write pointers for: GitHub Copilot in editors
(`.github/copilot-instructions.md`), Gemini CLI (`GEMINI.md`), and any other tool
the human names that reads its own file. Each pointer is the same paragraph as
CLAUDE.md. When unsure whether a tool reads AGENTS.md, write the pointer — it costs
nothing and prevents drift.

**Tier 2 — derived from code, only where there is substance**

| File | Generate when | Source |
|---|---|---|
| Data-model doc with an ER diagram (Mermaid) | A schema exists (ORM models, migrations, SQL) | The schema file, annotated with the constraints and conventions you verified |
| Interface inventory (`API.md` or equivalent) | The repo exposes routes, server actions, CLI commands or a public API | Every entry point, its inputs, validation, effect; the conventions they share |
| README quick-start | The README is boilerplate or absent | The verified commands from Step 1 — and you ran the sequence on a fresh clone or equivalent |

Never create a tier-2 doc as a stub. If there's nothing to derive, the section in
AGENTS.md is enough.

**Tier 3 — needs the human; offer, don't impose**

| File | What you contribute | What the human contributes |
|---|---|---|
| `DECISIONS.md` (ADR-lite) | The candidate decisions you observed, each with what the code does | Why, and what it would cost to change |
| `USER_GUIDE.md` (apps with a UI) | A screen-by-screen draft from the code — labels, buttons, fields, exactly as rendered | The workflow narrative: how the thing is meant to be used |

**Also, when discovery found the gap:** a CI workflow shaped per
`reference/ci-principles.md` (never a template — the stack decides); an env example
with placeholders and paths that actually work; `.gitignore` additions for uncovered
secret or database files.

### Step 4 — Verify (this is the step that makes it worth doing)

1. Run every command AGENTS.md lists. Any that fails is fixed or removed — never
   documented as working.
2. Run `scripts/scan-secrets.sh`. Anything it flags is resolved before the report.
3. Run `scripts/doc-drift.sh` against everything you changed. Every doc it names is
   re-read.
4. Re-read AGENTS.md as a stranger: can every sentence be traced to an evidence
   item or a human answer? Delete or mark `Unknown` anything that can't.
5. If the repo has a test suite you now understand, run it against a throwaway
   store per `reference/testing-safety.md`, and write down the incantation in the
   Testing section so the next person doesn't have to work it out.

### Step 5 — Report

In chat, not committed. Three lists:

- **Created / changed** — each file, one line on what it holds.
- **Verified** — each documented command with its result; scan result; drift check
  result; test run result and against what store.
- **Needs you** — every `Unknown`, every tier-3 offer, every product question that
  came up, and anything you deliberately did not touch (a real README, a doc you
  couldn't spot-check).

Commit hygiene: code fixes you made along the way (a broken command, a wrong
env-example path) go in their own commits, separate from the docs, so the history
shows what changed in the product versus the description of it.

## Mode: audit

For a repo that already has docs. The question is not "are the docs good" but "is
every claim true".

1. **Inventory** the docs and the ownership map (or build one if AGENTS.md lacks it).
2. **Check commands and coverage first** — they're cheap and they're the claims agents
   act on: run every documented command; count what tests actually cover versus what
   the docs say.
3. **Walk each doc against the code** using `reference/audit-checklist.md`. The claim
   types that drift most, in order: UI labels and button names · form fields and
   their validation · navigation structure · formulas and derived numbers · schema
   fields, enums and constraints · features described as built that aren't · commands
   and setup steps · branch names and CI triggers. For each claim: true, false (and
   what the code does), or unverifiable.
4. **Run** `scripts/scan-secrets.sh` and the test-safety check from
   `reference/testing-safety.md`.
5. **Triage** every finding into exactly one of:
   - *Drift, code is the truth* → fix the doc now, same commit per doc.
   - *Product question* (doc describes something unbuilt; is it wanted?) → ask,
     don't decide.
   - *Bug found by reading* (the doc is right and the code is wrong) → fix in its own
     commit if small and unambiguous; otherwise a KNOWN_ISSUES entry.
   - *Parked* → KNOWN_ISSUES entry with the workaround named.
6. **Report** as a table: doc · line · claim · what the code does · triage.

Reading the docs closely finds bugs. Expect it. A doc that describes what a button
*should* do is a test case.

## Mode: pre-publish

Before a repo becomes public or gets its first remote:

1. `scripts/scan-secrets.sh` — full history, every branch, plus the working tree.
   Any real credential in history means rewriting history *before* the first push;
   afterwards it's public forever.
2. **Test and dev credentials.** Any password or token committed for tests or local
   dev must be obviously fake (`e2e-only-not-a-real-password`), must live in one
   place the tests import from, must be mirrored (not re-typed) in CI, and must not
   be the value used anywhere real. Ask the human that last question explicitly.
3. **Env and ignore coverage.** Env example has placeholders only and paths that
   work; `.gitignore` covers env files, local databases, keys, and the same at the
   repo root, not just in subfolders.
4. **Branch and CI consistency.** The default branch name matches the CI triggers
   and every doc that names it.
5. **Author identity.** Tell the human that commit emails become public; offer the
   noreply rewrite *now*, since it's trivial before the first push and messy after.
6. **License and README.** Offer a license (MIT default) if none; confirm the README
   is not boilerplate.
7. **After the push**, remind them to enable secret scanning and push protection in
   the host's settings — the ongoing guard a one-time scan can't be.

## Writing rules (every mode)

- Prefer a short true sentence to a long plausible one.
- Name files and line numbers when pointing at code; name the section when pointing
  at a doc.
- State the negative when it matters: "no e2e coverage for X", "no change-password
  screen", "the only HTTP route is…". Absences are what agents guess wrong.
- Don't put private local values (a dev password, a personal path) in a public doc;
  say where they live instead.
- Keep AGENTS.md under roughly 250 lines. When a section outgrows that, it has
  become its own doc — split it and leave a link.
- Never delete or rewrite a real README, PRD or design doc wholesale. Fix claims in
  place; propose structure changes to the human.

## Files in this skill

| Path | Purpose |
|---|---|
| `reference/discovery.md` | The stack-agnostic discovery checklist with the evidence to record |
| `reference/agents-md-structure.md` | Section-by-section guidance for AGENTS.md: what belongs, what doesn't |
| `reference/docs-ownership.md` | How to build the ownership table for a given repo |
| `reference/known-issues.md` | KNOWN_ISSUES.md rules and entry format |
| `reference/testing-safety.md` | Throwaway stores, per-test isolation, importing app helpers, the run incantation |
| `reference/audit-checklist.md` | Claim types that drift, and how to check each |
| `reference/ci-principles.md` | The shape a CI workflow must have, whatever the stack |
| `scripts/scan-secrets.sh` | History + working-tree secrets scan (POSIX sh, git, grep) |
| `scripts/doc-drift.sh` | Identifiers in a diff → every doc line that mentions them |
| `examples/atlas/` | A real repo's AGENTS.md and KNOWN_ISSUES.md produced this way, with the before/after |
