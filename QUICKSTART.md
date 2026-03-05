# Quick Start Guide

Get up and running with server-manager in 5 minutes.

## Install (one-time)

```bash
git clone <repo> ~/server-manager
cd ~/server-manager
./install.sh

# Follow the prompts, then:
source ~/.bashrc  # or ~/.zshrc on macOS
```

## First Setup

```bash
# Run the setup wizard
server init

# It will ask:
# - Where to store projects (default: ~/Server)
# - Create your first namespace? (recommend: yes)
```

## Daily Usage

### Create a new namespace
```bash
server new Work
# Prompts for name and email, generates SSH key
```

### Clone a repo
```bash
cd ~/Server/Work
git clone git@github.com:myorg/myrepo.git
# The right SSH key is used automatically!
```

### See all your namespaces
```bash
server list

# Output:
# [✓] work             folder ssh git identity routing
# [!] personal         folder ssh git          routing
#
# ! 1 namespace needs attention (missing git identity)
```

### Check a namespace
```bash
server check work

# Shows:
# - Folder location
# - SSH key status
# - Git identity (name/email)
# - Git routing rule
```

### Fix a broken namespace
```bash
server ensure work
# Repairs missing SSH keys, configs, identity, routing
```

### Rename a namespace
```bash
server rename work professional
# Keeps SSH key and git identity
```

### Delete a namespace
```bash
server rm work
# Removes folder, keys, configs (ask for confirmation recommended)
```

## After Machine Reinstall

1. Restore your `~/Server` folder from backup
2. Run:
   ```bash
   server bootstrap
   # Regenerates all SSH keys and configs from existing folders
   ```

## Development Workflow

You cloned the repo and want to make changes?

1. **Edit any file in `lib/` or `bin/`**
   ```bash
   vim lib/commands.sh
   ```

2. **Test immediately**
   ```bash
   server list
   # Changes take effect right away
   ```

3. **No reinstall needed!**

4. **Commit when ready**
   ```bash
   git add .
   git commit -m "your changes"
   git push
   ```

## Troubleshooting

### Command not found
```bash
# Reload shell config
source ~/.bashrc  # or ~/.zshrc

# Or run directly from repo
~/server-manager/bin/server list
```

### Git still using global identity
```bash
# Check what's configured
server check work

# Fix it
server ensure work
```

### SSH key not working
```bash
# Verify the key is correct
server check work

# Try connecting to test
ssh -i ~/.ssh/work git@github.com
```

### Want to move the repo?
```bash
# Just update ~/bin/server to point to new location
vim ~/bin/server
# Change the $REPO_PATH line

# Or reinstall
cd /new/location/server-manager
./install.sh
```

## Key Concepts

**Namespace** = One identity (folder + SSH key + git config)
- Store at: `~/Server/Work/`, `~/Server/Personal/`, etc.
- SSH key: `~/.ssh/work`, `~/.ssh/personal`
- Git config: `~/.gitconfig-work`, `~/.gitconfig-personal`

**Git auto-selection** = `includeIf gitdir:` in `~/.gitconfig-server`
- When you run `git` in `~/Server/Work/`, Git loads `~/.gitconfig-work`
- Which sets `core.sshCommand = ssh -i ~/.ssh/work`
- Result: correct SSH key used automatically

**No per-repo setup needed** = Just clone into the right folder

## Common Workflows

### Work identity for projects in ~/Server/Work
```bash
server new Work
# Creates ~/Server/Work with SSH key and git identity

cd ~/Server/Work
git clone git@github.com:company/project.git
cd project
git config user.name   # Shows: Your Work Name
git config user.email  # Shows: your@work.email
```

### Personal projects
```bash
server new Personal
# Creates ~/Server/Personal with different identity

cd ~/Server/Personal
git clone git@github.com:yourname/side-project.git
```

### Multiple clients
```bash
server new ClientA
server new ClientB
# Each gets their own SSH key and git identity
```

## Getting Help

```bash
server --help          # Full help
server list --help     # (planned) Help for specific command
```

## Need More?

See README.md for full documentation.
See DEVELOPMENT.md if you want to modify the tool.
