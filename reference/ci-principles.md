# CI principles

No template. The stack decides the commands; these decide the shape. Write the
workflow for the CI system the repo already uses (or GitHub Actions if it has none
and the remote is GitHub), and check every rule below against it.

## Shape

1. **Two paths.** A *fast path* on every pull request and every push to the default
   branch: install → lint → typecheck/build → unit tests. Minutes, not tens of
   minutes; no browsers, no databases beyond an in-memory or file store. A *slow
   path* on pushes to the default branch only: end-to-end, integration, anything
   that needs a real server, browsers or a seeded store.

   State the reasoning in the workflow header so the next person doesn't "fix" it
   by running everything on every PR:

   ```
   # Fast path (every PR, every push to main): install, lint, typecheck-via-build,
   # unit tests. This is the required check.
   # Slow path (pushes to main only): the full e2e suite against a real server +
   # seeded local DB. Off the PR path because browsers + a full run is minutes,
   # not seconds.
   ```

2. **The fast path is the required check.** Name the job so it reads well in a
   branch-protection rule. If the repo has a default branch protection, require it.

3. **The default branch name in the triggers must match the repo.** Check
   `git symbolic-ref refs/remotes/origin/HEAD`. A workflow gated on `main` in a
   `master` repo runs nothing on the branch that matters — and nobody notices,
   because absence of a run looks like success.

## Environment

4. **A fresh store every run.** The migration step creates it; the seed step
   populates it. A file database (`file:./prisma/dev.db`) or a service container;
   never a shared or persistent one.

5. **No real secrets.** Every value in the workflow's `env:` block is visibly a
   dummy: `AUTH_SECRET: "ci-only-not-a-real-secret-000…"`, an obviously fake test
   password. Where a value must match something the tests use (a login), **mirror
   it with a comment naming the source file** — don't retype it, and don't make the
   tests read it from the env in a way that hides where it lives:

   ```
   # Must match TEST_USER in tests/helpers/test-data.ts — the specs log in with these.
   ADMIN_EMAIL: "test@atlas.local"
   ADMIN_PASSWORD: "e2e-only-not-a-real-password"
   ```

   Real credentials — deploy tokens, production database URLs — go in the host's
   secret store and are referenced, never written.

6. **Runtime versions match local development.** Pin the same major the developers
   run (`node-version`, `python-version`, `go-version`). A mismatch is a class of
   "works on my machine" that CI is supposed to catch, not create.

## Hygiene

7. **Pin action majors and watch deprecations.** `actions/checkout@v7`, not
   `@main`. Read the first green run's log for deprecation warnings (a runtime
   being retired, an action targeting an old Node) and act on them then, while
   they're warnings.

8. **Cache dependencies** with the setup action's built-in cache. Build caches
   (`.next/cache`, `target/`) only if the build is slow enough to matter.

9. **Upload the slow path's artefacts on failure** — test reports, screenshots,
   traces — with a short retention. A red e2e job with no artefacts is a red job
   nobody can debug.

10. **A job that is expected to be red is documented.** If the slow path is known
    to fail (a suite under repair), the reason and the KNOWN_ISSUES entry are named
    in AGENTS.md "CI". Silent red trains people to ignore red.

## Test gate (only when the human asked for one)

11. **A PR that changes code without touching a test fails — unless a commit says
    why.** The check is the diff, not a coverage number. On PRs only (it needs a
    base to diff against): list the changed files; if any is under the repo's code
    paths and none is under its test paths, fail, unless a commit in the PR carries
    a `Test-exempt: <reason>` trailer. The core is a few lines of sh whatever the
    stack — the paths are the repo's own, from AGENTS.md "Testing":

    ```sh
    # Test gate: code changed with no test fails unless a commit says why.
    # Code and test paths must match the "where tests go" table in AGENTS.md.
    base="origin/${GITHUB_BASE_REF:-main}"
    files="$(git diff --name-only "$base"...HEAD)"
    code="$(printf '%s\n' "$files" | grep -E '^src/' | grep -vE '\.(test|spec)\.')"
    tests="$(printf '%s\n' "$files" | grep -E '^tests/|\.(test|spec)\.')"
    if [ -n "$code" ] && [ -z "$tests" ] &&
       ! git log --format=%B "$base"..HEAD | grep -q '^Test-exempt: .'; then
      echo "Code changed with no test. Add one, or a 'Test-exempt: <reason>' trailer:" >&2
      printf '%s\n' "$code" >&2
      exit 1
    fi
    ```

    - **Full history in the checkout** (`fetch-depth: 0` on `actions/checkout`), or
      the base isn't there to diff against.
    - **The exemption is a commit trailer, not a PR label.** It works on every
      host, survives in history, and puts the reason where a reviewer reads it.
      Refactors and dependency bumps use it: `Test-exempt: refactor, no behaviour
      change`.
    - **It catches the forgotten test, not the useless one.** A test file that
      changed proves nothing about whether it exercises the change; review and the
      AGENTS.md rule do that. Say so in the workflow header so nobody mistakes the
      gate for proof.
    - **Coverage thresholds are a weaker gate.** A global percentage can't tell
      which code a change touched, and it rewards tests written for the number. If
      the repo already has one, keep it; don't add one in place of the diff check.
    - A pre-push hook can run the same lines for earlier feedback, if the repo uses
      hooks. CI is the copy that can't be skipped.

## Coverage summary (a report, never a gate)

12. **The fast path publishes a coverage summary; nothing fails on it.** Run the
    unit suite with the runner's own coverage writing lcov (column in the table
    below), then turn it into Markdown with the skill's
    `scripts/coverage-summary.sh`, copied into the repo (e.g. `scripts/` or
    `.github/scripts/`) with its header intact:

    ```yaml
    # Coverage summary: report only — nothing here fails the build. The test gate
    # (if any) is the enforcement; these numbers are for reading.
    - name: Coverage summary
      if: always()
      run: >
        sh scripts/coverage-summary.sh --base "origin/${GITHUB_BASE_REF:-main}"
        coverage/lcov.info >> "$GITHUB_STEP_SUMMARY"
    ```

    - **Two sections, both useful.** Totals per suite — one row per lcov, never
      merged into one number that hides an untested package — and the files the
      PR changed. The second is the one a reviewer acts on: a changed file at 0%
      or missing from the report means the PR's tests don't reach it, which the
      test gate (§11) can't see.
    - **Job summary, not a PR comment.** It needs no write permission and works
      on PRs from forks. Other hosts: their native coverage report if they have
      one, otherwise the job log.
    - **Upload the full HTML report** as an artifact with a short retention, as
      in §9, for anyone who wants line-level detail.
    - **Full history in the checkout** (`fetch-depth: 0`) for the changed-files
      section, as for §11.
    - **No percentages in docs.** The job summary is where the current numbers
      live; AGENTS.md says how to get them. A number written into a doc is stale
      by the next merge.
    - **The coverage provider may be a new dependency** (`@vitest/coverage-v8`,
      `pytest-cov`, a Go or Rust converter). That is the human's call in Step 2,
      not something to add in passing.

## Verify

After writing or changing a workflow: push it on a branch and open a PR so the fast
path runs; merge and watch the slow path. Read the log, not just the badge. A CI
workflow that has never run is a claim, not a check — exactly the kind of thing
AGENTS.md must not assert. For a test gate, that means two runs: a PR with a
code-only change, which must fail, and the same PR with the trailer or a test
added, which must pass. For a coverage summary: open the run's summary page and
check the changed-files section lists the PR's files.

## Stack hints (commands, not templates)

| Stack | Fast path | Slow path |
|---|---|---|
| Node | `npm ci` · `npm run lint` · `npm run build` (typecheck) · unit runner | `npx playwright install --with-deps chromium` · migrate · seed · `npx playwright test` |
| Python | `pip install -e .[dev]` / `uv sync` · `ruff check` · `mypy` · `pytest -m "not e2e"` | `pytest -m e2e` against a service container |
| Go | `go vet ./...` · `golangci-lint` · `go test ./...` | `go test -tags=integration ./...` |
| Rust | `cargo fmt --check` · `cargo clippy -- -D warnings` · `cargo test` | `cargo test --features integration` |

Coverage as lcov, for §12:

| Runner | Flags | Extra dependency |
|---|---|---|
| Vitest | `--coverage --coverage.reporter=lcov` | `@vitest/coverage-v8` |
| Jest | `--coverage --coverageReporters=lcov` | none |
| `node --test` | `--experimental-test-coverage --test-reporter=lcov --test-reporter-destination=lcov.info` — pass a glob (`"test/*.test.js"`); a bare directory argument produced an empty lcov on Node 24 / Windows | none |
| pytest | `--cov --cov-report=lcov` | `pytest-cov` |
| Go | `-coverprofile=cover.out`, then a converter to lcov | a converter (e.g. `gcov2lcov`) |
| Rust | `cargo llvm-cov --lcov --output-path lcov.info` | `cargo-llvm-cov` |

Use what the repo's own scripts define; don't introduce a tool the repo doesn't
already use just to fill a step.
