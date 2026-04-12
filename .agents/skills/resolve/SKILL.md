---
name: resolve
description: Resolve review comments for a pull request.
---

Resolve all actionable review feedback for the target pull request.

1. Identify PR, fetch comments, diff, CI state
2. Implement requested changes
3. Validate locally
4. Push changes
5. Reply to each comment with what was done
6. Resolve threads
7. Watch CI and fix failures until green
