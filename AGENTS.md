# AGENTS.md

OpenCode Container — containerized environment for running OpenCode CLI (Docker or Podman).

- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

## Canonical launcher

**`bin/opencode-container`** (recommended for users) — picks podman or docker (`$CONTAINER_ENGINE` overrides), uses `~/.opencode-container/` for persistence, current dir as workspace.

## Distroless runtime constraints

Final image is `gcr.io/distroless/base-debian13`:
- **No `/bin/bash`; `/bin/sh` (dash) is shipped** because OpenCode's shell tool and npm lifecycle scripts require it — cannot exec into production container
- To debug: `make shell` (uses builder-tools stage with bash)
- Available commands: `sh mkdir find grep rg jq cat head tail sed awk echo ls cp mv rm chmod wc sort cut env pwd date dirname basename`
- Python 3, Node 24, git also available

## Commit messages

Use conventional commits for persistent, searchable history:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `chore:` maintenance, refactoring, build changes
- `refactor:` code change that neither fixes nor adds

Format: `type: short description` (under 72 chars). Example: `feat: add -w/--websearch flag to enable Exa web search`
