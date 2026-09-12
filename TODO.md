# Security Backlog

Review scope: entire repository, static review, all security areas.

## High

- [x] **F1** — Secret loading is restricted to the configured provider names. Unsupported files in `/run/secrets` are ignored (`bootstrap.py:10-18,35-37`). Supported secrets remain intentionally available to OpenCode commands and plugins.
- [ ] **F2** — Partially addressed. NodeSource key fingerprint verification, locked npm dependencies, and pinned CI `pytest` are now present, but Debian and NodeSource package versions still come from mutable repositories (`Dockerfile:60-83`, `.opencode/package-lock.json`, `.github/workflows/release.yml:27`).
- [x] **F3** — GitHub Actions are pinned to immutable commit SHAs with version comments (`.github/workflows/release.yml:18,21,52,57,60,67,92`).
- [x] **F4** — Read access is defaulted globally and write access is limited to the publishing job (`.github/workflows/release.yml:8-9,14-15,47-49`).

## Medium

- [x] **F5** — Proxy URLs with embedded credentials are rejected; build proxy arguments are not persisted as image `ENV` values (`Makefile:13-23`, `Dockerfile:10-17,20-24`, `bin/opencode-container:101-108,127-131`).
- [x] **F6** — The host Git configuration is no longer mounted into the container (`bin/opencode-container:150-165`).
- [x] **F8** — Host access remains opt-in, emits a warning, and documentation states engine/firewall-dependent reachability and authentication requirements (`bin/opencode-container:145-147`, `README.md:155-175`).

## Low / Medium

- [x] **F9** — Common environment, certificate, key, and credential filenames are excluded from the Docker build context (`.dockerignore:15-22`).

## Review Limitations

- `npm audit --package-lock-only --audit-level=low` reported zero known vulnerabilities.
- `python3 test_bootstrap.py`, Python compilation, JSON parsing, npm lockfile dry-run, and npm audit passed. Pytest, Bash, Make, and Docker/Podman are unavailable in this environment.
- No secret values were inspected or printed.
- No container image build or runtime integration test was possible because Docker/Podman are unavailable.
