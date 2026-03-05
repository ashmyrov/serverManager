# server-manager

A lightweight CLI to manage multiple Git SSH identities by workspace folders.

Stop juggling SSH keys and `user.name` configs. Keep projects organized in folders, and **server-manager** automatically selects the right SSH identity for each folder using Git's native `includeIf gitdir:` feature.

## How it works

Instead of managing a global Git identity, you:

1. Organize projects under a root folder (default: `~/Server`)
2. Create a "namespace" for each identity (e.g., `~/Server/Work/`, `~/Server/Personal/`)
3. Each namespace gets its own SSH key and Git config
4. When you clone a repo into a namespace folder, Git automatically uses the right SSH identity

**Result**: You can use standard Git remotes like `git@github.com:org/repo.git`, and the correct key is selected automatically—no SSH config hacks, no per-repo setup.

## Key features

- **Simple setup**: One-command installer (`./install.sh`)
- **Interactive**: Setup wizard guides you through first-time configuration
- **Idempotent**: Commands are safe to run multiple times
- **Transparent**: Uses only standard Git include/includeIf mechanism
- **Portable**: Pure Bash, no external dependencies
- **Coloured output**: Clear visual feedback (green/yellow/red)
- **Clipboard support**: Auto-copy public keys (macOS & Linux)

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/your-org/server-manager ~/server-manager
cd ~/server-manager
```

### 2. Run the interactive installer

```bash
./install.sh
```

The installer will:
- Check dependencies (git, ssh-keygen)
- Detect your shell (bash/zsh)
- Ask where to store the repository (default: `~/.local/server-manager`)
- Create a command wrapper in `~/bin/server`
- Add `~/bin` to your PATH
- Preserve any existing config

This approach means:
- The command always points to your repo directory
- You can make changes and they take effect immediately (no reinstall needed)
- Easy to switch between development and stable versions

### 3. Reload your shell

```bash
source ~/.bashrc  # or ~/.zshrc on macOS
```

### 4. Run the setup wizard

```bash
server init
```

This will:
- Ask where you want to store projects (default: `~/Server`)
- Create `~/.server-manager.conf`
- Optionally create your first namespace

**Done!** You're ready to use `server-manager`.

## Development / Making Changes

Since the command wrapper points directly to the repository:

1. **Navigate to your repo**
   ```bash
   cd ~/.local/server-manager  # or wherever you installed it
   ```

2. **Make changes** to `lib/*.sh` or `bin/server`

3. **Test immediately**
   ```bash
   server list  # Changes take effect right away
   ```

4. **No reinstall needed!**

5. **Commit changes**
   ```bash
   git add .
   git commit -m "your message"
   git push
   ```

If you want to move the repository to a different location later, just update the path in `~/bin/server`.

## Quick start

```bash
# Create a new namespace with a name and SSH key
server new Work

# Git will prompt for your name and email for this namespace
# A new SSH key is generated and displayed
# Copy the public key to GitHub/GitLab

# Clone a repo into this namespace
cd ~/Server/Work
git clone git@github.com:myorg/myrepo.git

# The right SSH key is automatically selected!
# No per-repo setup needed.
```

## Commands

| Command | Purpose |
|---------|---------|
| `server init` | First-time setup wizard |
| `server new <Name>` | Create a new namespace |
| `server ensure <Name>` | Repair missing SSH keys or configs |
| `server bootstrap` | Set up all existing namespaces (after machine restore) |
| `server list` | Show all namespaces with their status |
| `server check <Name>` | Inspect a single namespace |
| `server rename <Old> <New>` | Rename a namespace |
| `server rm <Name>` | Delete a namespace |
| `server config` | Show current configuration |

## Examples

### Create a new namespace
```bash
$ server new Work
Git user.name for 'work': Alice Developer
Git user.email for 'work': alice@company.com
✓ Created /Users/you/Server/Work
✓ Generated SSH key: /Users/you/.ssh/work
✓ Created /Users/you/.gitconfig-work
✓ Added includeIf for /Users/you/Server/Work/

Public SSH key:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEx... alice@company.com-work
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Public key copied to clipboard
```

### List all namespaces
```bash
$ server list

=== Namespaces ===
  [✓] work                 folder ssh git identity routing
  [!] personal             folder ssh git          routing
  [✓] client-a             folder ssh git identity routing

All 3 namespaces healthy
```

### Check a namespace
```bash
$ server check work

=== Namespace: work ===
✓ Folder: /Users/you/Server/Work
✓ SSH key: present
✓ Git config: present
  ✓ user.name:  Alice Developer
  ✓ user.email: alice@company.com
✓ includeIf rule: present
```

### Restore after machine reinstall
```bash
# Restore your ~/Server folder from backup, then:
$ server bootstrap

✓ Bootstrap complete (3 namespaces)
# All SSH keys and configs are regenerated
```

## Configuration

After running `server init`, edit `~/.server-manager.conf` to customize paths:

```bash
SERVER_ROOT="$HOME/Server"       # Root folder for all namespaces
SSH_DIR="$HOME/.ssh"             # Where SSH keys are stored
GITCONFIG_MAIN="$HOME/.gitconfig" # Main git config
GITCONFIG_SERVER="$HOME/.gitconfig-server" # Managed routing file
```

## How it works internally

When you run `server new Work`, this is created:

**`~/.gitconfig`** (modified once):
```ini
[include]
    path = ~/.gitconfig-server
```

**`~/.gitconfig-server`** (appended to):
```ini
[includeIf "gitdir:/Users/you/Server/Work/"]
    path = ~/.gitconfig-work
```

**`~/.gitconfig-work`** (generated):
```ini
[core]
    sshCommand = ssh -i /Users/you/.ssh/work -o IdentitiesOnly=yes

[user]
    name = Alice Developer
    email = alice@company.com
```

**`~/.ssh/work` and `~/.ssh/work.pub`**:
Ed25519 keypair (no passphrase, for frictionless Git)

When you clone a repo into `~/Server/Work/`, Git sees the path matches the `includeIf gitdir:` rule, loads `~/.gitconfig-work`, and uses the Ed25519 key stored at `~/.ssh/work`.

## Files modified on your system

- `~/.server-manager.conf` — your config (created)
- `~/.gitconfig` — one include line added (safe)
- `~/.gitconfig-server` — managed by server-manager
- `~/.gitconfig-<namespace>` — one per namespace
- `~/.ssh/<namespace>` and `~/.ssh/<namespace>.pub` — SSH keypairs

## Migrating from Old Installation

If you have an old symlinked installation at `~/bin/server` pointing to `/Users/andrii/server-manager`:

```bash
# 1. Run the new installer
cd ~/server-manager
./install.sh

# It will ask where to store the repo. You can keep it at ~/server-manager
# or move it to ~/.local/server-manager (recommended)

# 2. The new wrapper in ~/bin/server will replace the old symlink automatically

# 3. Test it works
server list
```

The new approach is better because:
- Changes take effect immediately (no symlink indirection)
- Easier to manage multiple versions
- Wrapper script is more flexible

## Troubleshooting

### Public key not copied to clipboard
The clipboard feature requires `pbcopy` (macOS), `xclip`, or `xsel` (Linux). If unavailable, you can still copy manually from the displayed output.

### Git still using global identity
Make sure `~/.gitconfig` includes the line:
```bash
$ grep "path = ~/.gitconfig-server" ~/.gitconfig
[include]
    path = ~/.gitconfig-server
```

If it's missing, run:
```bash
server ensure <namespace>
```

### SSH key not being used
Verify the key matches your Git remote:
```bash
$ server check <namespace>
```

Also check that your repo is in the right folder:
```bash
$ pwd
/Users/you/Server/work/myrepo
# ✓ Correct — key 'work' will be used

$ pwd
/Users/you/Projects/myrepo
# ✗ Wrong folder — global identity would be used instead
```

## Contributing

This is a personal project, but pull requests are welcome.

## License

MIT
