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

## Verify

After writing or changing a workflow: push it on a branch and open a PR so the fast
path runs; merge and watch the slow path. Read the log, not just the badge. A CI
workflow that has never run is a claim, not a check — exactly the kind of thing
AGENTS.md must not assert.

## Stack hints (commands, not templates)

| Stack | Fast path | Slow path |
|---|---|---|
| Node | `npm ci` · `npm run lint` · `npm run build` (typecheck) · unit runner | `npx playwright install --with-deps chromium` · migrate · seed · `npx playwright test` |
| Python | `pip install -e .[dev]` / `uv sync` · `ruff check` · `mypy` · `pytest -m "not e2e"` | `pytest -m e2e` against a service container |
| Go | `go vet ./...` · `golangci-lint` · `go test ./...` | `go test -tags=integration ./...` |
| Rust | `cargo fmt --check` · `cargo clippy -- -D warnings` · `cargo test` | `cargo test --features integration` |

Use what the repo's own scripts define; don't introduce a tool the repo doesn't
already use just to fill a step.
