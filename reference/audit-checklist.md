# Audit checklist — claim types that drift, and how to check each

An audit compares docs to code claim by claim. This list is ordered by how often
each type turned out to be wrong in practice. Check the cheap, high-yield ones
first; they're also the ones agents act on.

For every claim, the outcome is one of: **true** · **false** (and what the code
does) · **unverifiable** (say what would verify it).

## 1. Commands and setup steps

*How:* run each one, in a fresh clone or the closest equivalent (a temp directory,
a throwaway env). Follow the README's quick-start literally, as a stranger would.

*Typical drift:* a script renamed; a step that assumes a file the repo doesn't ship;
an env example whose relative path resolves from a different base than the runtime
expects (found by *running* the sequence, never by reading the comment).

## 2. Coverage claims

*How:* count. Spec files, test names, the runner's list output. Compare with the
sentence in the doc. If the suite is safe to run (see `testing-safety.md`), run it
and use the real pass count.

If the repo writes lcov, run `scripts/coverage-summary.sh` on it and check every
coverage sentence against it. A percentage written into a doc is a finding on its
own: replace it with the command that produces it.

*Typical drift:* "covers every screen" when half the specs don't compile; a suite
described as passing that hasn't been run since a refactor; "85% coverage" in a
README, true once.

## 3. UI labels, buttons, and controls

*How:* grep the UI source for the literal text the doc quotes (`"Add monthly"`,
`"Sign out"`, `aria-label`). A label that appears in the doc but not in the code
is drift; a control the doc says is clickable (a badge, a pill) — check it's a
button.

*Typical drift:* renamed buttons after a redesign; "click the pill to pause" when
the pill is a static badge and the action is a separate button; an icon described
as 🗑 that is actually ×.

## 4. Form fields and their validation

*How:* read the form component and the validation schema side by side. Which
fields exist, which are required (`required` attribute, schema `.min(1)`), what
the error messages say.

*Typical drift:* a doc listing fields from the design that the form never got; a
test or doc expecting a server error the browser's own validation prevents.

## 5. Navigation and app shell

*How:* read the layout and nav component. Which links, in what order, grouped how,
on which breakpoints. Sidebar vs top bar vs bottom tabs. Theme switching.

*Typical drift:* the design doc's sidebar became a top bar; the phone layout is
never described; a "More" menu exists that no doc mentions. This category slipped
past the ownership table once — it needs its own row.

## 6. Formulas and derived numbers

*How:* find the function that computes the number; compare term by term with the
doc's formula. Check what the UI's *hero* figure actually is — it is often a
derived variant of the documented formula.

*Typical drift:* "Remaining cash is the hero figure" after the hero became
"remaining minus still-to-pay"; a doc formula that omits a term the code includes.

## 7. Schema: fields, enums, constraints

*How:* diff the doc's schema snippets against the real schema file, column by
column. Check enum claims against the database's capabilities (SQLite has none —
they're strings). Grep for each column's *writers*: a column nothing writes is a
finding.

*Typical drift:* snippets from the design phase that never got the columns added
later (`pending`, `income`); a whole model missing from the doc; a dead column
that documents a feature never built.

## 8. Features described as built

*How:* for each screen, route, command or option the doc describes, find the file
that implements it. No file → not built.

*Typical drift:* a "Budget Planning screen", a "quick-add FAB", a "date input on
entries" — designed, documented, never implemented. These are **product
questions**, not doc fixes: ask whether the feature is still wanted before
deleting it from the doc.

## 9. Branch names, CI triggers, git conventions, URLs

*How:* `git symbolic-ref refs/remotes/origin/HEAD`; grep workflows and docs for
`main`/`master`; check the CI badge URL; check external links resolve. For every
claim about how change enters the repo (CONTRIBUTING.md, an AGENTS.md "Git"
section, a PR template): `git log --format=%s -50` for the message convention,
`git log --merges` for the branch model, the hooks directory for what actually
runs, the host's settings for protection.

*Typical drift:* workflow triggers on `main` in a repo whose default branch is
`master` (the e2e job never runs); docs that say "every push" when the trigger is
PR-only; "we use Conventional Commits" over a log that doesn't; "all changes via
PR" in a repo with direct pushes to the default branch; a documented pre-commit
hook that no clone has installed.

## 10. Versions and environments

*How:* runtime versions in CI vs local vs docs; framework major versions in the
README vs the lockfile; deprecation warnings in the last CI log.

## 11. Internal contradictions

*How:* a doc can disagree with itself — the intro says a feature is v2, a later
section says it shipped in v1. Read each doc once end to end for this alone.

## 12. Cross-references

*How:* every "see X §N" — does X exist, does it have a §N, is the section still
about that? Pointers to a doc that was replaced (a `CLAUDE.md` section moved to
`AGENTS.md`) are common after a reorganisation.

## 13. Behaviour no doc mentions

Every check above runs docs → code, so none of them can fire on something the
docs simply omit: there is no sentence to test. This is the one pass that runs
the other way, code → docs.

*How:* take the inventory from discovery — commands and scripts, env vars,
routes and actions, screens, config files, the git and release conventions — and
for each one ask which doc is supposed to describe it, using the ownership table.
Anything significant that no doc names is a finding. "Significant" is the test
from the rule: would someone using or changing this need to know? A flag that
changes behaviour counts; a private helper doesn't.

*Typical gaps:* a script added without a line in the commands section; an env var
the code reads that the env example doesn't have; a second entry point nobody
documented; a convention that lives only in the maintainer's head.

Run this last — it needs the whole inventory — and expect it to be the pass that
produces the most work, especially in a repo whose docs were written once at the
start.

## 14. Changes that landed without tests

Only when AGENTS.md has the tests-are-part-of-the-change rule. The rule is a
claim about history like any other, and this checks it.

*How:* from the date the rule was adopted, `git log --name-only` — for each commit
that touched code paths in the "where tests go" table and no test path, read the
subject and diff: a refactor, a docs or config change, or a `Test-exempt:` trailer
with a reason is fine. Anything else is a finding: behaviour that shipped
untested. Then check the table itself — every path exists, the runner picks up a
file there, and no layer the code now has is missing a row.

*Typical drift:* bug fixes with no regression test; a new route tested only by the
build; a skipped test with no KNOWN_ISSUES entry; a table naming a directory the
runner's `include` glob no longer covers.

Triage each as *Parked* (a KNOWN_ISSUES entry naming the untested behaviour) unless
the test is cheap enough to write now.

## 15. Decision records

Two directions, like the rest of the audit.

*Records → code:* for each *accepted* record, does the code still do what it
says? Grep for what the decision forbids (the ORM import, a float column, a cron
config). A record the code contradicts is a **product question**: was it reversed
without a superseding record, or is the code wrong? Ask; don't decide.

*Code → records:* list dependencies from the manifest and the patterns from
discovery's "looks deliberate" list. Any that someone could reasonably undo and
that no record explains is *Undocumented* — but its why comes from the human, so
it goes in the report's "needs you" list, not straight into a file.

*Also check:* every file has an index row, and status, date and "decided by"
agree between them; superseded records link their successor; *proposed* records
older than a few weeks — the human never confirmed them.

*Typical drift:* a dependency swapped with no record; an accepted "no ORM" over
code that now imports one; a *proposed* record that nobody accepted and every
agent since has treated as settled.

## Triage

Every finding lands in exactly one bucket:

| Bucket | Action | Commit |
|---|---|---|
| Drift — code is the truth | Fix the doc now | One commit per doc, or one for the audit |
| Undocumented — the code does something no doc mentions | Write it into the owning doc, or the AGENTS.md section if nothing owns it | With the doc fixes |
| Product question | Ask; don't decide | — until answered |
| Bug — the doc is right, the code is wrong | Fix if small and unambiguous, with a test that fails without the fix; else KNOWN_ISSUES entry | Own commit, clearly labelled `fix:` |
| Parked | KNOWN_ISSUES entry naming the workaround | Same commit as the workaround |

## Report format

A table: **doc · line · claim · what the code does · bucket**. Group by doc. Lead
with the counts (how many claims checked, how many false) so the human can gauge
trust at a glance. Undocumented findings have no doc or line — list them
separately, naming the code and the doc that should have covered it. Then the product questions as a numbered list — they need
answers, and burying them in a table loses them.

## What an audit tends to find that isn't drift

Reading docs closely against code surfaces bugs: a Save button with no submit, a
nav rendered four times, an action that deletes a row two other features rely
on. Expect one or two per audit. They go in the "bug" bucket and get their own
commits, so the history separates "the product changed" from "the description
changed".
