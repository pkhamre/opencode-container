#!/usr/bin/env bash
set -euo pipefail

ROOTFS="$(mktemp -d)"
trap 'rm -rf "$ROOTFS"' EXIT

scripts/collect-runtime-deps.sh "$ROOTFS" /bin/true git \
  /usr/lib/git-core/git-remote-http /usr/lib/git-core/git-remote-https sh

TRUE_PATH="$(command -v /bin/true)"
[ -e "$ROOTFS$TRUE_PATH" ]
[ -e "$ROOTFS/usr/lib/git-core/git-remote-http" ]
[ -e "$ROOTFS/usr/lib/git-core/git-remote-https" ]
[ -x "$ROOTFS/usr/lib/git-core/git-remote-curl" ]
[ -e "$ROOTFS/usr/local/share/ca-certificates" ]

# The shell is exposed at the standard paths; links are absolute, so resolve
# the link target inside the rootfs explicitly.
[ -L "$ROOTFS/bin/sh" ]
[ -L "$ROOTFS/usr/bin/sh" ]
SH_TARGET="$(readlink "$ROOTFS/bin/sh")"
[ -n "$SH_TARGET" ] && [ -x "$ROOTFS$SH_TARGET" ]

if scripts/collect-runtime-deps.sh "$ROOTFS/missing" does-not-exist; then
  echo "expected missing executable to fail" >&2
  exit 1
fi

echo "runtime collector checks passed"
