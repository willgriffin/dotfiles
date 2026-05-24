---
description: "Prepare work and open or update a reviewable PR."
---

# /ship

Prepare the current branch for review using the standards of the current
repository and organization.

1. Discover local standards before changing behavior:
   - read the nearest `AGENTS.md`, `CLAUDE.md`, `README.md`, and relevant docs
   - inspect repo scripts, package tasks, CI config, and documented validation
   - apply any generated org or profile instructions already installed for this agent
2. Inspect the working tree, branch, upstream state, base branch, open PR, and
   current CI state.
3. Remove accidental noise, generated clutter, debug instrumentation, and
   unrelated changes from the proposed diff.
4. Confirm docs are updated when behavior, interfaces, config, ops, or
   developer workflow changed.
5. Run the narrowest meaningful validation first, then broader validation before
   opening or updating the PR.
6. Review the final diff for secrets, unrelated files, and avoidable churn.
7. Create or update a ready-for-review PR with a concise description,
   validation results, and known risks.
8. Watch CI and fix straightforward failures until the branch is reviewable.

If local repo or org instructions conflict with this workflow, follow the more
specific repo/org instruction and call out the conflict in the final report.
