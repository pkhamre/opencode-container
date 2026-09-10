#!/usr/bin/env python3

import os
import sys
from pathlib import Path


SECRETS_DIR = Path("/run/secrets")


def env_var_name(secret_name: str) -> str:
    return secret_name.upper().replace("-", "_").replace(".", "_")


def load_secrets(secrets_dir: Path = SECRETS_DIR, environ: dict[str, str] | None = None) -> None:
    if not secrets_dir.is_dir():
        return

    environ = os.environ if environ is None else environ
    seen: dict[str, str] = {}  # normalized env var -> original filename
    for entry in secrets_dir.iterdir():
        if not entry.is_file():
            continue

        name = env_var_name(entry.name)
        if name in seen:
            raise RuntimeError(f"secret name collision: {seen[name]} and {entry.name} -> {name}")

        seen[name] = entry.name
        value = entry.read_text(encoding="utf-8").rstrip("\r\n")
        environ[name] = value


def bootstrap(args: list[str], execvp=os.execvp) -> None:
    load_secrets()
    execvp("opencode", ["opencode", *args])


def main() -> None:
    bootstrap(sys.argv[1:])


if __name__ == "__main__":
    main()
