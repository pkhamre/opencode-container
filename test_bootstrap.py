#!/usr/bin/env python3

import tempfile
from pathlib import Path

import bootstrap
from bootstrap import load_secrets


def test_secret_loading() -> None:
    with tempfile.TemporaryDirectory() as directory:
        secrets = Path(directory)
        (secrets / "anthropic-api.key").write_text("key\n", encoding="utf-8")
        (secrets / "nested").mkdir()
        environment: dict[str, str] = {"ANTHROPIC_API_KEY": "old"}

        load_secrets(secrets, environment)

        assert environment["ANTHROPIC_API_KEY"] == "key"


def test_unsupported_secret_names_are_ignored() -> None:
    with tempfile.TemporaryDirectory() as directory:
        secrets = Path(directory)
        (secrets / "PATH").write_text("not-a-path", encoding="utf-8")
        (secrets / "unrelated-file").write_text("must-not-be-read", encoding="utf-8")
        environment: dict[str, str] = {"PATH": "old"}

        load_secrets(secrets, environment)

        assert environment == {"PATH": "old"}


def test_collisions_fail() -> None:
    with tempfile.TemporaryDirectory() as directory:
        secrets = Path(directory)
        (secrets / "anthropic-api-key").write_text("one", encoding="utf-8")
        (secrets / "anthropic.api.key").write_text("two", encoding="utf-8")

        try:
            load_secrets(secrets, {})
        except RuntimeError as error:
            assert "ANTHROPIC_API_KEY" in str(error)
        else:
            raise AssertionError("expected normalized secret name collision")


class UnreadableEntry:
    name = "anthropic_api_key"

    def is_file(self) -> bool:
        return True

    def read_text(self, **_: object) -> str:
        raise PermissionError("permission denied")


class UnreadableDirectory:
    def is_dir(self) -> bool:
        return True

    def iterdir(self) -> list[UnreadableEntry]:
        return [UnreadableEntry()]


def test_unreadable_files_fail() -> None:
    try:
        load_secrets(UnreadableDirectory(), {})  # type: ignore[arg-type]
    except PermissionError:
        pass
    else:
        raise AssertionError("expected unreadable secret to fail")


def test_invalid_utf8_fails() -> None:
    with tempfile.TemporaryDirectory() as directory:
        secret = Path(directory) / "anthropic_api_key"
        secret.write_bytes(b"\xff")

        try:
            load_secrets(secret.parent, {})
        except UnicodeDecodeError:
            pass
        else:
            raise AssertionError("expected invalid UTF-8 secret to fail")


def test_lifecycle_order_and_arguments() -> None:
    events: list[str] = []
    original_loader = bootstrap.load_secrets
    bootstrap.load_secrets = lambda: events.append("secrets")
    try:
        bootstrap.bootstrap(
            ["--model", "test"],
            execvp=lambda program, command: events.append(f"exec:{program}:{command}"),
        )
    finally:
        bootstrap.load_secrets = original_loader

    assert events == [
        "secrets",
        "exec:opencode:['opencode', '--model', 'test']",
    ]


if __name__ == "__main__":
    test_secret_loading()
    test_unsupported_secret_names_are_ignored()
    test_collisions_fail()
    test_unreadable_files_fail()
    test_invalid_utf8_fails()
    test_lifecycle_order_and_arguments()
    print("bootstrap checks passed")
