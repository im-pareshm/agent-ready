# Testing safety

Three things go wrong when an agent runs a test suite it doesn't understand: it
destroys the developer's local data, it reports a pass/fail count that reflects
leftover state rather than the code, or it "fixes" the tests by copying app logic
into helpers that then drift. This file is how to avoid all three.

## Before the first run: find out what the suite resets

Grep test config, global setup, fixtures and helpers for the destructive verbs:

```
reset | migrate | seed | drop | truncate | deleteMany | TRUNCATE | rm -rf |
docker compose down -v | flush | purge
```

For each hit, trace *which* store it acts on — almost always an env var
(`DATABASE_URL`, `REDIS_URL`, a path) or a config value. That is what you must
redirect. In the example repo, the Playwright fixture ran `prisma migrate reset
--force` against whatever `DATABASE_URL` named — the developer's own `dev.db` with
two months of real data.

If a suite has no destructive step, say so in AGENTS.md — it is useful to know.

## Point it at a throwaway store

1. **Back up first** anyway: `cp dev.db dev.db.bak-$(date +%Y%m%d)`. Cheap
   insurance; verify it's byte-identical afterwards (`cmp`) and say so in the
   report.
2. **Override by environment**, not by editing config files:
   `DATABASE_URL=file:./prisma/e2e.db`, a `_test` database name, a temp directory.
3. **Prove the override wins.** Env loaders differ: Node's `process.loadEnvFile()`
   and `--env-file` do *not* override existing variables; some `dotenv` wrappers
   do (`override: true`); frameworks have their own rules. Test it with a one-liner
   before trusting it:
   ```
   DATABASE_URL=probe node -e "process.loadEnvFile('.env'); console.log(process.env.DATABASE_URL)"
   ```
   If it prints `probe`, the override holds.
4. **Check every process in the chain**: the migration tool, the seed script, the
   app server the tests drive, and any test that opens its own DB client. Each
   reads the env independently; one reading a different file than the others is
   the classic "no such table" failure.
5. **Watch for reuse of a running server.** Playwright's `reuseExistingServer`,
   a dev server already on the port, a Docker container from earlier — a test run
   that attaches to an existing server tests *that server's* database. Set the
   `CI` flag or the equivalent so the runner starts its own, and check the port is
   free first.
6. **Clean up orphans** if you interrupt a run: the server the runner spawned may
   outlive it and hold the port.

Write the working incantation into AGENTS.md "Testing", every variable and flag:

```
CI=1 DATABASE_URL=file:./prisma/e2e.db TURSO_DATABASE_URL=file:./prisma/e2e.db \
ADMIN_EMAIL=test@atlas.local ADMIN_PASSWORD=e2e-only-not-a-real-password \
npm run db:deploy && npm run db:seed && npx playwright test --project=chromium
```

## Per-test isolation

Tests that count rows ("expect 1 template") must start from a known state. If the
suite has no isolation, the first symptom is a delete test finding 9 rows where it
expected 1, and the second is order-dependent flakiness.

The fix that has worked: a small helper with direct DB access (`resetTestUserData()`)
that wipes what the test account created — and only that — keeping the account and
any seeded reference data, called from `beforeEach` in every spec that asserts on
counts. Direct DB is faster and more reliable than resetting through the UI.

## Import app helpers; never copy them

A test helper that reimplements a formatter, a money conversion or a date rule will
drift. In the example repo a copied `formatINR` produced `₹500.00` where the app
rendered `₹500`, and the whole recurring suite failed on it. The fix was one line:

```ts
export { rupeesToPaise, paiseToRupees, formatINR } from "../../lib/money";
```

Rule: test helpers may *wrap* app code; they may not *re-derive* it.

## Fixed test credentials

A committed test account is fine — a public repo full of `atlas-dev-1234` was fine
*as long as* that value was never used anywhere real. Make it obviously fake
(`e2e-only-not-a-real-password`), keep it in one file the specs import, mirror it
in CI with a comment saying where it comes from, and ask the human explicitly
whether the value has ever been used for a live system. If it has, rotate the live
system and, before the first public push, scrub history.

## In CI

Fresh store every run (a file DB created by the migration step, or a service
container), env values that are visibly not secrets, and the slow suite gated to
the default branch so a PR gets fast feedback (see `ci-principles.md`).

## The negative claims

State in AGENTS.md what the tests **don't** cover, by screen or module. An agent
that reads "58 tests, all green" assumes the thing it's about to change is tested.
"No e2e coverage for expenses, known, people, funds, history, categories" is the
sentence that changes its behaviour.
