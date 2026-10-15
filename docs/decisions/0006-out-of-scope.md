# 0006. Out of scope: CI templates, generated requirements, claims that agents comply

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh (in the initial design discussion)
- **Links:** b6934d2, AGENTS.md "What this is", `README.md` "What it deliberately doesn't do"

## Context
Scope set during the initial design.

## Decision
The skill does not ship:
- CI templates — the stack decides; the skill ships principles
  ([0002](0002-no-stack-specific-templates.md));
- generated requirements or design docs — intent comes from the human;
- any claim that agents will *follow* the docs — the skill can only make them true.

## Alternatives considered
Not recorded when the decision was made.

## Cost to change
Each item would reverse a principle: generated requirements contradict
principle 2 (intent comes from the human), and a compliance claim is a statement
the skill cannot verify (principle 1).
