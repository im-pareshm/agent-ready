# Decisions

One file per decision; the file is authoritative. Status: *proposed* (an agent
made it; not yet confirmed) · *accepted* · *superseded by NNNN*. Format and
rules: [reference/decision-records.md](../../reference/decision-records.md).

| # | Decision | Status | Date | Decided by | Summary |
|---|---|---|---|---|---|
| [0001](0001-principles-are-the-product.md) | The principles are the product | accepted | 2026-09-16 | Paresh | Principle changes go through an issue, not a drive-by PR |
| [0002](0002-no-stack-specific-templates.md) | No templates for stack-specific output | accepted | 2026-09-16 | Paresh | A template is wrong for most stacks; principles + discovery fit |
| [0003](0003-posix-sh-scripts.md) | Scripts are POSIX sh, no runtime dependency | accepted | 2026-09-16 | Paresh | Git Bash on Windows; repos without Node or Python |
| [0004](0004-ship-scripts-and-describe-them.md) | Ship scripts *and* describe what they do | accepted | 2026-09-16 | Paresh | Deterministic when they run; doable by hand when they can't |
| [0005](0005-examples-are-real.md) | Examples are real | accepted | 2026-09-16 | Paresh | A synthetic example is the plausible doc the skill prevents |
| [0006](0006-out-of-scope.md) | Out of scope: CI templates, generated requirements, compliance claims | accepted | 2026-09-16 | Paresh | Set in the initial design discussion |
| [0007](0007-never-rewrite-history.md) | Never rewrite history unless explicitly asked | accepted | 2026-09-20 | Paresh | Users update installed copies with `git pull` |
| [0008](0008-commit-subjects-scope-what-changed.md) | Commit subjects are `Scope: what changed` | accepted | 2026-09-20 | Paresh | Nothing here consumes a Conventional Commits prefix |
