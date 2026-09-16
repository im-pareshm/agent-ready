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

*Typical drift:* "covers every screen" when half the specs don't compile; a suite
described as passing that hasn't been run since a refactor.

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

## 9. Branch names, CI triggers, URLs

*How:* `git symbolic-ref refs/remotes/origin/HEAD`; grep workflows and docs for
`main`/`master`; check the CI badge URL; check external links resolve.

*Typical drift:* workflow triggers on `main` in a repo whose default branch is
`master` (the e2e job never runs); docs that say "every push" when the trigger is
PR-only.

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

## Triage

Every finding lands in exactly one bucket:

| Bucket | Action | Commit |
|---|---|---|
| Drift — code is the truth | Fix the doc now | One commit per doc, or one for the audit |
| Product question | Ask; don't decide | — until answered |
| Bug — the doc is right, the code is wrong | Fix if small and unambiguous, else KNOWN_ISSUES entry | Own commit, clearly labelled `fix:` |
| Parked | KNOWN_ISSUES entry naming the workaround | Same commit as the workaround |

## Report format

A table: **doc · line · claim · what the code does · bucket**. Group by doc. Lead
with the counts (how many claims checked, how many false) so the human can gauge
trust at a glance. Then the product questions as a numbered list — they need
answers, and burying them in a table loses them.

## What an audit tends to find that isn't drift

Reading docs closely against code surfaces bugs: a Save button with no submit, a
nav rendered four times, an action that deletes a row two other features rely
on. Expect one or two per audit. They go in the "bug" bucket and get their own
commits, so the history separates "the product changed" from "the description
changed".
