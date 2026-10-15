# 0007. Never rewrite history unless explicitly asked

- **Status:** accepted
- **Date:** 2026-09-20
- **Decided by:** Paresh
- **Links:** 10f9b92, AGENTS.md "Git"

## Context
Users install the skill by cloning `main` and update it with `git pull`.

## Decision
No amend, rebase, reset or force-push on any branch without an instruction that
names it. New commits only.

## Alternatives considered
Not recorded when the decision was made.

## Cost to change
Rewriting published `main` breaks `git pull` for every installed copy.
