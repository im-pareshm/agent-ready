# Discovery checklist

Collect all of this before writing a word of AGENTS.md. For every fact, record
**how you know** — you will need it for the report, and it is what stops you writing
something plausible instead of something true.

Keep a scratch evidence list as you go, in this shape:

```
fact                                     | evidence
"npm run build" is the typecheck         | ran it; exit 0; output shows "Finished TypeScript"
6 spec files, 58 tests                   | `ls tests/*.spec.ts`; ran suite; 58 passed
Budget row holds income + additional     | prisma/schema.prisma:124-138
"covers every screen" is false           | 6 of 12 specs had 238 type errors
```

## 1. Stack and package manager

Look for manifests, in this order; the first match usually names the ecosystem, but
polyglot repos have several — record all:

| Manifest | Ecosystem | Commands live in |
|---|---|---|
| `package.json` (+ lockfile → npm / pnpm / yarn / bun) | JS/TS | `scripts` |
| `pyproject.toml`, `setup.py`, `requirements*.txt`, `Pipfile` | Python (poetry / uv / pip / pipenv per lockfile) | `[tool.*]` sections, `Makefile`, `tox.ini`, `noxfile.py` |
| `go.mod` | Go | `Makefile`, `magefile.go`, or bare `go` commands |
| `Cargo.toml` | Rust | `cargo` subcommands, `justfile`, `Makefile` |
| `*.csproj`, `*.sln` | .NET | `dotnet` commands |
| `pom.xml`, `build.gradle(.kts)` | JVM | `mvn` / `gradle` tasks |
| `Gemfile` | Ruby | `Rakefile`, `bin/` |
| `Makefile`, `justfile`, `Taskfile.yml` | any | targets |
| `Dockerfile`, `docker-compose*.yml` | any | how the thing actually runs |

Then, for each command you intend to document: **run it**. Use `--help`, `--dry-run`,
`--list` or a no-op target where the real run is slow or destructive. Record exit
code and the first meaningful line of output. A command you did not run does not go
in AGENTS.md.

Also record: the runtime version the repo expects (`.nvmrc`, `.node-version`,
`engines`, `.python-version`, `go.mod`'s `go` line, `rust-toolchain`), and the
version actually installed locally. Mismatches go in the report.

## 2. Layout

- Top-level directories and what each holds (one line each).
- Entry points: `main`, `index`, `app/`, `cmd/`, `src/bin`, the `Dockerfile`'s
  `CMD`.
- Where tests live and how they are distinguished from source (`tests/`,
  `__tests__/`, `*_test.go`, `*.spec.ts`).
- **Monorepo?** `workspaces` in `package.json`, `pnpm-workspace.yaml`, `go.work`,
  Cargo workspaces, `packages/`/`apps/` folders. If yes, plan a root AGENTS.md for
  the shared rules plus one per package for its own commands and facts — tools
  read nested AGENTS.md files.
- Generated or vendored directories to ignore (`node_modules`, `dist`, `.next`,
  `target`, `vendor`).

## 3. Tests — and what they reset

Before running anything:

1. List the frameworks (from manifests and config files: `vitest.config`,
   `jest.config`, `playwright.config`, `pytest.ini`, `conftest.py`, …).
2. Count suites and files per framework. Count *tests* only if a runner can list
   them cheaply (`--list`, `--collect-only`).
3. **Find the destructive parts.** Grep test setup, fixtures, global-setup and
   config for: `reset`, `migrate`, `seed`, `drop`, `truncate`, `deleteMany`,
   `TRUNCATE`, `rm -rf`, `docker compose down -v`. For each hit, find which env var
   or config value decides *what* gets reset. That is the store you must redirect
   before running (see `testing-safety.md`).
4. Only then run the suite, against a throwaway store, and record the real
   pass/fail count. This number — not the README's number — is the coverage claim.
5. Note what the tests **don't** cover. Absences are what AGENTS.md must state.

## 4. CI

- Workflow files: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`,
  `.circleci/`, `bitbucket-pipelines.yml`, `azure-pipelines.yml`.
- For each: triggers (branches, events), jobs, which are gated on which branch.
- **Default branch name** (`git symbolic-ref refs/remotes/origin/HEAD`, or
  `git branch --show-current` if there is no remote yet). Check every trigger and
  every doc that names a branch agrees with it.
- Runtime versions pinned in CI versus locally.
- Whether CI is currently green (host API, or the badge), and if red, why.

## 5. Git — how change enters the repo

Read the history before you write a commit of your own; yours should look like
the repo's. Record each item as *observed*; the human says which are deliberate in
Step 2.

- **Branch model.** `git log --oneline --graph -40` and `git log --merges --oneline
  | head`: linear commits on the default branch, merge commits, or squash-merged
  PRs (a linear history whose subjects end in `(#123)`). `git branch -r` for the
  naming live branches use.
- **Commit-message convention.** `git log --format=%s -50`. A `type(scope):`
  prefix (Conventional Commits), a `Scope: subject` prefix, plain sentences, issue
  references, sign-off trailers. Note how *consistent* it is: a convention most
  commits follow is the convention; one a hook or CI check enforces is a rule.
- **Hooks and local checks.** `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml`,
  `git config core.hooksPath`, non-`.sample` files in `.git/hooks/`. What each
  runs, and the command that runs the same check by hand.
- **Signing.** `git config commit.gpgsign`; `git log --format=%G? -20` — mostly
  `G`/`U` means the repo expects signed commits, and an unsigned one may be
  rejected.
- **Host rules.** Branch protection and required checks, a PR template
  (`.github/pull_request_template.md`), `CODEOWNERS`, `CONTRIBUTING.md`. Read them
  via the host CLI/API where you can; otherwise `Unknown — check <host> settings`.
- **Releases.** `git tag -l`, a version file, a changelog and what maintains it.
- **Author identities** the history carries (`git log --format='%an <%ae>' |
  sort -u`). Feeds pre-publish (emails become public) and tells you what your
  own commits will be attributed to.

## 6. Docs

Inventory every `*.md`, `docs/`, ADR folder, wiki or external link (Notion, Google
Doc). For each one:

- What it covers, in one line.
- Whether it is current, superseded, or historical (a "plan" written before the
  code is historical the moment the code diverges; say so).
- **One spot-check.** Pick a concrete claim — a button label, a field name, a
  command, a route — and check it against the code. This calibrates how much to
  trust the rest and decides whether `audit` mode should run before `bootstrap`
  finishes.

Also record which files are boilerplate (the framework's default README, an
untouched CONTRIBUTING template) — those are candidates to replace; real docs are
never rewritten wholesale.

## 7. Environment and secrets

- Env example files (`.env.example`, `.env.sample`, `.env.template`) and whether
  every value is a placeholder.
- Env vars the code actually reads (`process.env.X`, `os.environ`, `os.Getenv`,
  `std::env::var`, config loaders). Compare with the example — missing or extra?
- **Paths in env values**: if a value is a file path (`file:./dev.db`), find out
  what it is resolved relative to by *testing*, not by reading a comment. Two
  tools resolving the same relative path from different bases is a classic
  fresh-clone failure.
- Local secret-bearing files present: `.env*`, `*.pem`, `*.key`, `*.p12`, `*.db`,
  `*.sqlite*`, `id_rsa*`, `.npmrc` with tokens, `credentials.json`. For each: is
  it gitignored (`git check-ignore -q <path>`)? Was it ever committed
  (`git log --all --name-only --format="" | sort -u`)?
- Run `scripts/scan-secrets.sh` and keep its output for the report.

## 8. Interfaces and data model

These decide whether tier-2 docs have substance.

- **Interfaces**: HTTP route handlers, server actions, GraphQL schema, gRPC
  protos, CLI commands and subcommands, public package exports, webhooks. Count
  them and note where they live. Note the shared conventions (auth check, input
  validation, return shape, error mapping) — the conventions section is the most
  useful part of an interface doc.
- **Data model**: ORM schema (`schema.prisma`, `models.py`, `entities/`,
  `db/schema.rb`), migrations folder, raw SQL. Note enums-as-strings, soft
  deletes, tenancy columns, cascade rules, and any column nothing writes to
  (grep the codebase for each column name; a column with no writer is a finding).

## 9. What you now know — and don't

Before moving to the human questions, write two short lists:

- **Observed patterns that look deliberate** — "every amount is an integer",
  "no ORM, raw SQL only", "single tenant but tenant id on every row", "feature
  flags via env only", "every commit goes straight to main". These become the
  "is this a decision, and why?" question.
- **Things you could not determine** — the runtime version, whether a doc is
  current, what a column is for. These go in AGENTS.md as `Unknown — <how to find
  out>` unless the human answers them.
