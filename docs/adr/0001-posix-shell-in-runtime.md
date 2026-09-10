# Ship a POSIX shell in the distroless runtime

The runtime is built on `gcr.io/distroless/base-debian13`, which contains no
shell. OpenCode's shell tool resolves a shell as `bash` if one is present and
otherwise falls back to `/bin/sh`, and npm's `node-gyp` wrapper is a `#!/bin/sh`
script — so both need a POSIX shell to function. We ship Debian `dash` as
`/bin/sh` rather than remain shell-less. This retires the "no shell" security
claim, but the container exists to run an agent that already executes arbitrary
commands, so the marginal attack surface is small.

## Considered Options

- **Stay shell-less** — rejected: the shell tool and npm scripts cannot run.
- **Use the `:debug` tag's busybox** — rejected: that tag also overrides the
  entrypoint, and the plain base image ships no busybox to reuse.
- **Ship `bash`** — rejected: larger than `dash`, and OpenCode explicitly falls
  back to `/bin/sh`.

## Consequences

- The README no longer claims the image has no shell; the security story becomes
  "no package manager, no compiler, read-only rootfs, all capabilities dropped".
- `/bin/sh` is a first-class entry in the runtime dependency manifest.
