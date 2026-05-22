# oc-sandbox

A containerized sandbox for running [opencode](https://opencode.ai) agents with filesystem isolation and protection against permission escalation. Built on rootless Podman with a read-only root filesystem, dropped capabilities, and `no-new-privileges` — agents can only write to `/workspace`, `/tmp`, and `/home/sandbox`.

## How to use it

1. **Install** oc-sandbox:

   Remote install (no git required):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/MarekBleschke/oc-sandbox/main/install.sh | bash
   ```

   Install from a cloned repo:
   ```bash
   git clone git@github.com:MarekBleschke/oc-sandbox.git && cd oc-sandbox
   ./install.sh
   ```

2. **Build** the container image (required before first run or after config changes):

   ```bash
   oc-sandbox build
   ```

   Useful options:

   | Flag | Default | Description |
   |------|---------|-------------|
   | `-I, --image <NAME>` | `base` | Image name to build |
   | `-F, --force` | — | Force rebuild even if image exists |

3. **Run** opencode inside the sandbox:

   ```bash
   oc-sandbox run
   ```

   Useful options:

   | Flag | Default | Description |
   |------|---------|-------------|
   | `-I, --image <NAME>` | `base` | Image to use |
   | `-p, --profile <NAME[:VARIANT]>` | `(from config)` | Opencode profile to activate |
   | `--debug` | — | Drop into `/bin/bash` instead of opencode |
   | `--no-ssh` | — | Skip mounting SSH keys from host |
   | `--no-auth` | — | Skip mounting auth.json from host |
   | `--no-gh-token` | — | Skip GH_TOKEN detection from host |
   | `--gh-token <TOKEN>` | — | Use the provided GitHub token |

## Configuration

The config file at `~/.config/oc-sandbox/config` controls defaults:

```ini
[general]
default_profile = superpowers
default_image = base

[git]
user_name =
user_email =

[mounts]
ssh_key = ~/.ssh/id_rsa|/home/sandbox/.ssh/id_rsa
auth_json = ~/.local/share/opencode/auth.json|/home/sandbox/.local/share/opencode/auth.json
```

The `[mounts]` section uses `src_path|container_dst_path` pairs with `~/` expansion. If a mount key is missing or malformed, the CLI falls back to the default paths. Use `--no-ssh` or `--no-auth` to skip mounts regardless of config.

### Per-Project Configuration

Place a `.oc-sandbox` file in your project's root directory to override global defaults:

```ini
[general]
# Override the image used by `oc-sandbox run` for this project
default_image = python
# Override the profile used by `oc-sandbox run` for this project
default_profile = superpowers:eco
```

Precedence (lowest to highest):
1. **Compiled defaults:** `image=base`, `profile=<empty>`
2. **Global config:** `~/.config/oc-sandbox/config`
3. **Project config:** `.oc-sandbox` in the workspace directory
4. **CLI flags:** `--image` and `--profile` always win

The `.oc-sandbox` file can be checked into version control so all
contributors share the same sandbox configuration.

## Project structure

```
.
├── install.sh                  # Curl-able installation script
├── sandbox/
│   ├── oc-sandbox              # CLI script (build, run, uninstall, completion)
│   ├── oc-sandbox.conf          # Config template
│   ├── completion_zsh           # Zsh completion definitions
│   ├── init.sh                  # Container ENTRYPOINT — resolves profiles at runtime
│   ├── opencode-install.sha256  # SHA256 checksum for opencode install script
│   ├── containerfiles/
│   │   ├── base.Containerfile   # Ubuntu + system deps + opencode + init.sh
│   │   ├── python.Containerfile # FROM base + Python
│   │   └── java.Containerfile   # FROM base + Java
│   └── test-sandbox.sh          # Integration tests (require podman)
├── default-profiles/            # Self-contained profile repository
│   ├── base/                    # Profile directory (flat, no nesting)
│   │   ├── profile.conf         # Required — marks this as a profile
│   │   └── opencode.json
│   └── superpowers/             # Profile directory
│       ├── profile.conf         # Default variant
│       ├── profile.eco.conf     # Alternative variant (eco model)
│       ├── profile.free.conf    # Alternative variant (free model)
│       ├── opencode.json
│       ├── agents/              # Template .md files with {{MODEL_*}}
│       ├── skills/ → submodules/superpowers/skills/    # Internal symlink
│       ├── plugins/ → submodules/superpowers/plugins/  # Internal symlink
│       └── submodules/
│           └── superpowers/     # Git submodule (lives INSIDE profile dir)
└── docs/specs/                  # Design documents
```

## Adding a new profile

1. Create a directory under `default-profiles/<name>/` with at minimum an `opencode.json` config file.
2. Reference any submodules or shared resources via symlinks (see `default-profiles/superpowers/` for the pattern).
3. Rebuild the image: `oc-sandbox build -F`
4. Run with the new profile: `oc-sandbox run -p <name>`
