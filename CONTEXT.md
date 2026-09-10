# Domain Context

## Launcher

The canonical launcher runs OpenCode in the locked-down production container
with persistent user data and the current directory as workspace.

## Debug shell

The debug shell opens the builder-tools container for repository-level image
troubleshooting. It is not a normal OpenCode launch path.

## Secret

A secret is a credential provided as one file in the launcher's secret
collection.

## Secret loading

Secret loading turns the launcher's secret collection into environment values
available to OpenCode. Secret filenames define their environment names.

## Bootstrap lifecycle

The bootstrap lifecycle loads secrets and replaces itself with OpenCode.

## Runtime dependency collection

Runtime dependency collection builds the runtime rootfs from the executable
manifest required by the canonical launcher.

## Runtime rootfs

The runtime rootfs is the verified filesystem assembled for the locked-down
production container.
