# Global Codex defaults

## General working rules
- Be terse.
- Prefer small, reviewable diffs.
- Do not leave the working tree dirty unless explicitly asked.
- Before opening or updating a PR, run the project’s documented local validation steps.
- When project instructions exist, follow them over these defaults.

## PR and review handling
- When resolving review comments, reply to every substantive comment with the action taken, or explain why no code change was made.
- Only mark a review thread resolved after posting the reply and verifying the thread is actually addressed in code or docs.
- Prefer linking each response to a concrete file, test, or commit when possible.

## Documentation
- When behavior, interfaces, config, ops, or developer workflow changes, check whether docs or READMEs should be updated.

## Validation
- Run the narrowest meaningful local checks first, then broader checks before shipping.

## Git / PR workflow
- Keep branch history understandable.
- Review diffs for accidental changes, secrets, or noise before shipping.
