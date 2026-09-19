#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/bin" "$TEST_DIR/home" "$TEST_DIR/workspace" "$TEST_DIR/repo/config"
cat > "$TEST_DIR/bin/podman" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$ARGS_FILE"
EOF
chmod +x "$TEST_DIR/bin/podman"

ARGS_FILE="$TEST_DIR/args" \
HOME="$TEST_DIR/home" \
PATH="$TEST_DIR/bin:$PATH" \
OPENCODE_CONTAINER_REPO="$TEST_DIR/repo" \
OPENCODE_WORKSPACE="$TEST_DIR/workspace" \
  "$ROOT_DIR/bin/opencode-container"

grep -F "$TEST_DIR/home/.opencode-container:/app:rw,Z" "$TEST_DIR/args"
grep -F "$TEST_DIR/home/.opencode-container/config:/app/.config/opencode:rw,Z" "$TEST_DIR/args"
grep -F "$TEST_DIR/home/.opencode-container/secrets:/run/secrets:ro,Z" "$TEST_DIR/args"
grep -F "$TEST_DIR/workspace:/workspace:rw,Z" "$TEST_DIR/args"

echo "launcher SELinux mount checks passed"
