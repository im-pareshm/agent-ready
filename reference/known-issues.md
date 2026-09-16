# KNOWN_ISSUES.md — rules and entry format

A home for verified engineering problems that have a workaround in place, or fixes
that were deliberately deferred. Its purpose is that a parked problem survives the
chat session it was found in, and that the workaround carrying it is never "tidied
up" by someone who doesn't know why it's there.

It is **not a backlog**. Feature scope belongs in the requirements doc (or the
Intent section of AGENTS.md); design gaps belong with the design. If something is
cheaper to fix than to write up, fix it.

## The rules (put these at the top of the file)

- **Park a fix → add the entry in the same commit.** An exclusion, a `.skip`, an
  `it.todo`, a workaround: whatever carries the debt, the entry lands with it.
- **Fix it → delete the entry in the same commit.** Git history is the archive.
  There is no "Resolved" section.
- **Link both ways.** Every entry names the code carrying its workaround, and that
  code comments `See KNOWN_ISSUES.md "<entry title>"` rather than re-explaining
  inline, so `grep -r KNOWN_ISSUES` finds every hook.
- **A review that ends with unfixed findings ends with entries here**, not with
  findings left in a chat transcript.

## Entry format

Each entry should let someone pick the problem up cold without redoing the
investigation. Ten to twenty lines:

- **Symptom** — what you observe. The command, the error, the wrong number.
- **Cause** — verified, with `file:line` pointers. Not a hypothesis; if you only
  have a hypothesis, say so and say what would confirm it.
- **Workaround in place** — what carries the debt, and *why it must not be
  removed* until the fix lands. This is the field that protects the workaround.
- **Fix plan** — concrete steps, rough size, and the last step is always "delete
  this entry".
- **Since** — commit and date, when known.

## Example

```markdown
## `PersonLedgerEntry.linkedTxnId` is a dead column

**Symptom.** `prisma/schema.prisma` has `linkedTxnId String?` on
`PersonLedgerEntry` (comment: "this entry is also a cash movement"), but no
action or form ever sets it. Every row is null.

**Cause.** DESIGN.md originally let a ledger entry optionally double as a cash
transaction. The integrated cash math made that redundant, the UI was never
built, and the column shipped in the initial migration.

**Workaround in place.** None needed — the column is nullable and ignored.
Listed so the decision isn't lost: DESIGN.md marks it `UNUSED` and points here.

**Fix plan.** Decide one of: (1) drop it — a migration plus the matching edit to
the SQL schema file, and delete the line from DESIGN.md's snippet; (2) build it.
Then delete this entry.

**Since.** Initial schema (2026-07-12).
```

## What doesn't belong

- Feature requests, ideas, "nice to have" — backlog, not here.
- Anything without a verified cause — investigate first, or file it with the
  hypothesis clearly labelled.
- Things fixable in under the time it takes to write the entry.
- Resolved entries. Delete them; the commit that fixed it is the record.

## The pointer in AGENTS.md

One line in the source-of-truth docs list, plus the standing rule:

> Skim KNOWN_ISSUES.md before starting work. If your task touches a listed item,
> fix it or update the entry in the same commit; if you park a fix, add an entry in
> the same commit as the workaround.
