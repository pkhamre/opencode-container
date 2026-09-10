#!/usr/bin/env bash
set -euo pipefail

ROOTFS="$(mktemp -d)"
trap 'rm -rf "$ROOTFS"' EXIT

scripts/collect-runtime-deps.sh "$ROOTFS" /bin/true

TRUE_PATH="$(command -v /bin/true)"
[ -e "$ROOTFS$TRUE_PATH" ]
[ -e "$ROOTFS/usr/local/share/ca-certificates" ]

if scripts/collect-runtime-deps.sh "$ROOTFS/missing" does-not-exist; then
  echo "expected missing executable to fail" >&2
  exit 1
fi

echo "runtime collector checks passed"
