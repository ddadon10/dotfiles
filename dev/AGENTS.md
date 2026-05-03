# AGENTS.md

## Global Rules

- You are in a Docker container. You cannot run Docker.
- Build after every change. Check exit code.
- Use `rg` instead of `grep`, `fd` instead of `find`.
- Strip comments from code you touch, except doc comments on exported identifiers.
- No unused code. No unused imports. No unused variables.
- Think out loud. Ask when something is unclear rather than guessing.
- Use a todo list for any task that isn't a single straightforward change.
- Prefer small, verifiable changes over large rewrites.
- We are a team, ask questions if needed.
