# Decision records — one file per decision, one index

The code shows *what* was chosen, never *why*, and never what was rejected. An
agent that doesn't know a pattern was deliberate "simplifies" it; one that
doesn't know an alternative was tried tries it again. Decision records keep the
why next to the code, in files that outlive the chat or PR where the choice was
made.

## The rule (it goes in AGENTS.md, "Decisions to preserve")

> **Decisions are part of the change.** A change that makes a choice someone
> could reasonably undo records it **in the same commit**: a new file in
> `docs/decisions/` and a row in its index. If you made the choice yourself, its
> status is *proposed* until the human accepts it. Reversing a decision is a new
> record that supersedes the old one; accepted records are never deleted.
> Before changing a dependency, a pattern or the scope, check the index.

## What counts

A choice someone could reasonably undo, where the code alone doesn't say why:

- adding, removing or swapping a dependency;
- a pattern chosen over an obvious alternative (raw SQL over an ORM, a
  hand-written parser over a library, polling over webhooks);
- a scope cut or deferral ("no multi-currency", "CSV import is v2");
- a trade-off (simplicity over performance, a denormalised column, no cache);
- a convention adopted for the codebase (integer money, UTC everywhere, one
  `actions.ts` per route);
- reversing any of the above.

Not a decision: a bug fix, a rename, something the framework or language forces,
a choice with no plausible alternative. If nobody would ever ask "why is it like
this?", there is nothing to record.

## Where and how files are named

`docs/decisions/` by default, or wherever the repo already keeps docs
(principle 7). One file per decision, `NNNN-short-slug.md`: four digits, the next
unused number, never reused or renumbered, so `0007-integer-money.md` is a link
that never breaks. Code comments, KNOWN_ISSUES entries and other docs link to the
file, not the index.

**If the repo already has decision records** — an `adr/` folder, MADR or Nygard
format, a single DECISIONS.md — use its location, format and numbering. Map its
fields onto the ones below where they differ; don't migrate it unless asked.

## The index (`docs/decisions/README.md`)

One row per decision. The row is a summary; **the file is authoritative**, and the
two must agree on status, date and who decided. Keep the summary to one line — a
second line in the index is a second copy of the description, and two copies
drift.

```markdown
# Decisions

One file per decision; the file is authoritative. Status: *proposed* (an agent
made it; not yet confirmed) · *accepted* · *superseded by NNNN*.

| # | Decision | Status | Date | Decided by | Summary |
|---|---|---|---|---|---|
| [0001](0001-integer-money.md) | Money is integer paise | accepted | <date> | <name> | Floats round; SQLite has no Decimal |
| [0002](0002-lazy-recurring.md) | Recurring entries generated on page load, no cron | accepted | <date> | <name> | Personal-scale app; needs no infrastructure |
```

## The file

```markdown
# 0001. Money is integer paise

- **Status:** accepted            <!-- proposed · accepted · superseded by [NNNN](NNNN-slug.md) -->
- **Date:** <YYYY-MM-DD the decision was made>
- **Decided by:** <name>          <!-- agent-made: "proposed by <agent> in <commit or PR>; awaiting <name>" -->
- **Links:** <commit or PR>, `lib/money.ts`

## Context
What forced a choice: the constraint, the problem, what was true at the time.

## Decision
What was chosen, in a paragraph.

## Alternatives considered
Each one, and why not.

## Cost to change
What reversing it would touch — files, data, migrations, users. This is the
field that tells the next person whether "just change it" is a five-minute job.
```

Short is fine. A decision that fits in five lines gets five lines; the headings
stay so every record reads the same way.

## Who decided — and agent-made decisions

"Decided by" names a person. Intent comes from the human (principle 2), so:

- **A decision the agent made during a change** — it picked the library, it chose
  the pattern — is recorded with status *proposed* and "proposed by <agent> in
  <commit>; awaiting <name>". The agent says so in its report or PR description.
  The human accepts it (status *accepted*, their name, the date), or rejects it:
  before merge, the change is redone and the file deleted with it; after merge, a
  new record supersedes it.
- **A decision inferred from code during bootstrap** — a pattern that *looks*
  deliberate — is not a record yet. It goes in the Step 2 question ("is this a
  decision, and why?"). Only the ones the human confirms become records,
  *accepted*, with their why and their name. The rest stay in the report's "Needs
  you" list.

The difference: the agent's own choice is a fact (it did choose), so it can be
recorded and flagged. Someone else's reason is not something the agent knows.

## Reversing a decision

Never edit an accepted record into a different decision, and never delete one.
Write a new record whose Context says what changed and links the old one; set the
old record's status to *superseded by [NNNN](NNNN-slug.md)*; update both index
rows — all in the commit that makes the change. The old file is where the next
person learns why the first choice was made and why it stopped holding.

## The AGENTS.md section

AGENTS.md is loaded into every session; the index isn't. So the "Decisions to
preserve" section holds the rule above, a link to the index, and — if there are many
records — the few most likely to be undone by accident, one line each, linking
their files:

```markdown
## Decisions to preserve

[the rule]

Index: docs/decisions/README.md. The ones most often undone by accident:
- Money is integer paise — [0001](docs/decisions/0001-integer-money.md)
- No cron; recurring entries are generated on page load — [0002](docs/decisions/0002-lazy-recurring.md)
```

Those lines are pointers, not copies: no why, no detail — that lives in the file.
