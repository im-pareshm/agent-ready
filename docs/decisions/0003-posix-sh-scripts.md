# 0003. Scripts are POSIX sh with no runtime dependency

- **Status:** accepted
- **Date:** 2026-09-16
- **Decided by:** Paresh
- **Links:** b6934d2, 7986d7c, `scripts/`, `.github/workflows/ci.yml` (`shellcheck -s sh`)

## Context
The audience includes Windows developers on Git Bash and repos with no Node or
Python installed.

## Decision
Every script is POSIX sh plus standard tools (`git`, `grep`, `awk`): no arrays,
no `[[`, no `local`. Portability beats convenience.

## Alternatives considered
Bash, Node or Python scripts: rejected because they fail in repos and on
machines that don't have them.

## Cost to change
Rewriting three scripts (`scan-secrets.sh`, `doc-drift.sh`,
`coverage-summary.sh`), changing CI's `shellcheck -s sh`, and adding a runtime
requirement to the README's install section.
