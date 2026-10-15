# 0004. Ship scripts *and* describe what they do

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh
- **Links:** b6934d2, the header comment of each file in `scripts/`, the reference docs that describe each check

## Context
An agent may be unable to run a script — no shell, a sandbox, a platform the
script doesn't support.

## Decision
Each script is deterministic when it can run, and the procedure also describes
what it does, so an agent can do the job by hand when it can't.

## Alternatives considered
Not recorded when the decision was made.

## Cost to change
Dropping the descriptions would make the skill unusable wherever the scripts
can't run; dropping the scripts would make every check manual and
non-deterministic.
