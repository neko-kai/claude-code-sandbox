# Claude Code Sandbox

A macOS sandbox configuration for Claude Code that restricts filesystem READ access for enhanced security.

Just about all sandbox-exec attempts for `claude` you'll find on GitHub allow full filesystem read access and full network access – all they protect against is file overwrites. But that's not very secure - prompt injection could leak data from all over your filesystem if `claude` can read it.

This project provides a macOS `sandbox-exec` profile that limits `claude`'s access to your filesystem. It prevents Claude Code from reading your home directory (except for the current working directory) and restricts writes to only the target directory and temporary locations.

## Features

- **Restricted Read Access**: Blocks reading from file system except for:
  - Current working directory (`TARGET_DIR`)
  - Git configuration files (`.gitconfig`, `.config/git`)
  - System directories (`/usr`, `/bin`, `/opt`, `/var`, `/nix`, `/etc`, `/System`, `/Library/Java`)
  - It allows _listing_ directories leading up to `TARGET_DIR`, because otherwise claude will glitch and set PATH to "" for agent.
    However, even though files in `~` can be listed with `ls` by claude, they (and their metadata) cannot be read

- **Restricted Write Access**: Only allows writing to:
  - Current working directory (`TARGET_DIR`)
  - Temporary directories (`/tmp`, `/var/folders`)
  - Cache directory (`~/.cache`)
  - Claude, Gemini & Codex configuration (`~/.claude`, `~/.gemini`, `~/.codex`)

- **Network Access**: Full network access enabled (required for Claude API)
- **Keychain Access**: Allows reading from macOS Keychain for API key storage

## Installation

### Manual Installation (Without Nix)

Run the installation script:

```bash
./install
```

This will:
1. Concatenate the default sandbox profile `noread.sb` and `claude-sandbox` script together to make the script self-contained.
2. Install the `claude-sandbox` script to `~/.local/bin/claude-sandbox`
3. Make the script executable

Ensure that `~/.local/bin` is in your PATH.

### Using Nix (Recommended)

If you have Nix installed, you can run `claude-sandbox` directly without installing:

```bash
nix run github:neko-kai/claude-code-sandbox -- claude
```

Or install it to your profile:

```bash
nix profile install github:neko-kai/claude-code-sandbox
```

You can also add it to a flake-based NixOS or home-manager configuration:

```nix
{
  inputs.claude-code-sandbox.url = "github:neko-kai/claude-code-sandbox";
  inputs.claude-code-sandbox.inputs.nixpkgs.follows = "nixpkgs";
  inputs.claude-code-sandbox.inputs.flake-utils.follows = "flake-utils";

  # Then use inputs.claude-code-sandbox.packages.${system}.default
}
```

## Usage

Instead of running `claude` directly, use the `claude-sandbox` wrapper:

```bash
# run bash to browse the sandbox-accessible filesystem
claude-sandbox bash

# run claude
claude-sandbox claude

# write generated sandbox-exec profile to a file and exit
claude-sandbox --write-profile curprofile.sb

# dump the built-in noread.sb to a file for customization
claude-sandbox --write-base-profile custom.sb

# use a custom profile template instead of the built-in noread.sb
claude-sandbox --use-profile custom.sb -- claude
```

## How to add access to more directories

Modify `noread.sb` and run `./install` again, or use `--use-profile` with a custom profile template.

Find out which rules to add by running `Console.app` and filtering errors by 'sandbox'

## How It Works

The `claude-sandbox` wrapper uses macOS's `sandbox-exec` command to apply a security profile defined in `noread.sb`. This sandbox profile is based on the [Para sandboxing profile](https://github.com/2mawi2/para/blob/218259b6e260be43334f308a74108f31920f7ca4/src/core/sandbox/profiles/standard.sb) and [anthropic's sandbox-runtime's dynamic profile](https://github.com/anthropic-experimental/sandbox-runtime/blob/1bafa66a2c3ebc52569fc0c1a868e85e778f66a0/src/sandbox/macos-sandbox-utils.ts#L200), with additional configuration for Claude Code compatibility.
Specifically, for some reason claude-code needs list access to all parent directories of current working directory - it doesn't need read access to the content of directories, only access to list the content of directories. Without this access it will set PATH in the agent to "" and disable colored output. To avoid this the script adds these listing rules dynamically.
