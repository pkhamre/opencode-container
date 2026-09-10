# OpenCode Container

A security sandbox for running the OpenCode CLI under container isolation, so
the agent process never gets more access than the host explicitly grants. The
domain has two sides — host-side artifacts that grant access and container-side
artifacts that consume it — joined by a narrow bridge.

## Language

**OpenCode Container**:
The system that builds the sandbox image and ships the launcher.
_Avoid_: using the name for the image tag or the command

**Launcher**:
The host-side command that starts the sandbox around the current workspace.
_Avoid_: wrapper, runner, client, canonical launcher

**Image**:
The locked-down container filesystem that holds OpenCode and its runtime
dependencies.
_Avoid_: container, box, distro

**Shell**:
The POSIX command interpreter (`/bin/sh`) shipped in the runtime rootfs so
OpenCode's shell tool and npm lifecycle scripts can execute commands.
_Avoid_: bash, terminal, console

**Bootstrap**:
The in-container process that prepares the runtime and hands control to
OpenCode.
_Avoid_: entrypoint, init, startup script

**Debug shell**:
The builder-tools container opened for repository-level image troubleshooting.
It is not a normal OpenCode launch path.

**Secret**:
A credential provided as one file in the secret collection.
_Avoid_: key, token, credential

**Secret loading**:
Secret loading turns the launcher's secret collection into environment values
available to OpenCode. Secret filenames define their environment names.

**Bootstrap lifecycle**:
The bootstrap lifecycle loads secrets and replaces itself with OpenCode.

**Runtime dependency collection**:
Runtime dependency collection builds the runtime rootfs from the executable
manifest, plus the prerequisites (such as the shell) those executables require.

**Runtime rootfs**:
The runtime rootfs is the verified filesystem assembled for the locked-down
production container.
