# Environment

- You are in a Docker container. You cannot run Docker.
- You cannot run `git pull` or `git push`. When merging another branch into the current branch, merge `origin/<other-branch>` into this branch directly.
- Use `rg` instead of `grep`, and `fd` instead of `find`.

# Critical Rules

- Make small code changes that keep diffs focused and easy to review.
- Inline simple one-off functions. Do not extract a single-use helper or assign a literal to a single-use variable.
- Favor reusing existing code. If existing code must be changed to support the new use, say so explicitly.
- Prefer the use of standard library over custom implementations.
- Keep code on one line when it fits within 120 columns unless syntax or the project formatter requires wrapping. This includes trivial or single statement functions and methods.
- Use a todo list for any task that is not a single straightforward change.
