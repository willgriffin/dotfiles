---
description: "Run a review, fix, and retest loop."
---

# /review-cycle

Run a bounded review, fix, and retest loop using the standards of the current
repository and organization.

1. Discover local standards before reviewing:
   - read the nearest `AGENTS.md`, `CLAUDE.md`, `README.md`, and relevant docs
   - inspect repo scripts, package tasks, CI config, and documented validation
   - apply any generated org or profile instructions already installed for this agent
2. Identify the target branch, base branch, changed files, open PR, CI state,
   and project validation commands.
3. Review the diff from multiple angles: correctness, maintainability,
   security, product behavior, test coverage, docs, and consistency with local
   standards.
4. Convert actionable findings into a short fix list. Ignore preference-only
   churn unless it conflicts with repo/org standards or blocks maintainability.
5. Implement fixes while preserving unrelated user changes.
6. Re-run relevant validation and update docs if behavior or workflow changed.
7. Repeat the review once after fixes. Stop when no material findings remain or
   a blocker requires human input.
8. Report what changed, what was validated, which standards were applied, and
   any residual risk.

If local repo or org instructions conflict with this workflow, follow the more
specific repo/org instruction and call out the conflict in the final report.
