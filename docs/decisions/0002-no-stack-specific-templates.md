# 0002. No templates for stack-specific output

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh
- **Links:** b6934d2, `reference/ci-principles.md` ("No template"), [0006](0006-out-of-scope.md)

## Context
CI workflows, and anything else whose commands depend on the stack, differ in
every repo.

## Decision
Ship principles, not templates. The agent's own discovery plus the principles
produce a workflow that fits the repo.

## Alternatives considered
A CI template: rejected because it would be wrong for most stacks and would be
copied without thought.

## Cost to change
Adding templates means maintaining one per stack and keeping each current;
`reference/ci-principles.md` and its "No template" framing would need
rewriting. Stack-agnostic snippets (the test gate, the coverage step) are not
templates and are allowed.
