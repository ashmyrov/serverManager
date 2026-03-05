# Development Guide

This guide explains how to work on server-manager and test changes.

## Architecture

```
bin/server           # Thin entrypoint (~60 lines)
  ↓
  Finds lib/ directory relative to itself
  ↓
  Sources: lib/output.sh, lib/ssh.sh, lib/git.sh, lib/commands.sh
  ↓
  Dispatches to command handlers
```

## Quick Start

1. **Clone the repo**
   ```bash
   git clone <repo> ~/server-manager
   cd ~/server-manager
   ```

2. **Make it executable**
   ```bash
   chmod +x bin/server
   chmod +x lib/*.sh
   chmod +x install.sh
   ```

3. **Run directly (no installation needed)**
   ```bash
   ./bin/server --help
   ./bin/server config
   ./bin/server list
   ```

4. **Or run the installer to create `~/bin/server` wrapper**
   ```bash
   ./install.sh
   # Choose: store repo at ~/.local/server-manager (or keep at ~/server-manager)
   # Then: source ~/.bashrc && server list
   ```

## File Organization

| File | Purpose | Lines |
|------|---------|-------|
| `bin/server` | Entry point, config loading, command dispatch | ~70 |
| `lib/output.sh` | Logging, colours, prompts | ~100 |
| `lib/ssh.sh` | SSH key management (ensure_ssh_key) | ~20 |
| `lib/git.sh` | Git config helpers | ~75 |
| `lib/commands.sh` | All command implementations | ~420 |
| `install.sh` | Interactive installer | ~200 |

## Making Changes

### Adding a new command

1. Add function to `lib/commands.sh`:
   ```bash
   cmd_mycommand() {
     # Your implementation
     ok "Done"
   }
   ```

2. Add to dispatcher in `bin/server`:
   ```bash
   mycommand)  cmd_mycommand "${2:-}" ;;
   ```

3. Add help text to `show_help()` in `lib/commands.sh`

4. Test immediately:
   ```bash
   ./bin/server mycommand
   ```

### Modifying helpers

Edit the relevant file in `lib/`:
- **Output/logging**: `lib/output.sh`
- **SSH operations**: `lib/ssh.sh`
- **Git operations**: `lib/git.sh`

All changes take effect immediately when you run the command.

### Testing

```bash
# Test help
./bin/server --help

# Test existing commands
./bin/server config
./bin/server list
./bin/server check personal

# Test with verbose output
bash -x ./bin/server list
```

## Debugging

### Check which files are being sourced
```bash
bash -x ./bin/server config 2>&1 | head -20
```

### Verify lib directory is found
```bash
./bin/server config
# Should show paths correctly
```

### Test a specific lib file
```bash
source lib/output.sh
ok "This should be green"
```

## Commit Workflow

1. **Make changes**
   ```bash
   vim lib/commands.sh  # or any file
   ```

2. **Test**
   ```bash
   ./bin/server list
   ```

3. **Commit**
   ```bash
   git add lib/commands.sh README.md
   git commit -m "Add feature: xyz"
   ```

4. **Push**
   ```bash
   git push origin main
   ```

If you installed via `./install.sh`, the command wrapper (`~/bin/server`) will automatically pick up changes from your repo.

## Common Tasks

### Change default SERVER_ROOT
Edit the defaults at the top of `bin/server`:
```bash
SERVER_ROOT="$HOME/MyProjects"  # Change this
```

### Add colour to a command
Use helpers from `lib/output.sh`:
```bash
ok "Success message"      # Green with ✓
warn "Warning message"    # Yellow with !
info "Info message"       # Plain
die "Error message"       # Red with ✗ and exit 1
section "Title"           # Blue section header
```

### Prompt user for input
```bash
name="$(prompt_input 'Enter your name' 'John Doe')"
if prompt_yn "Do you want to continue?"; then
  ok "Continuing..."
fi
```

### Test argument validation
```bash
./bin/server new 2>&1
# Should show: ✗ Error: Usage: server new <FolderName>
```

## Notes

- All scripts use `set -euo pipefail` for safety
- No external dependencies beyond bash 4+, git, ssh-keygen
- All lib files are sourced once at startup (efficient)
- Use `/dev/tty` in prompts to work with piped input
- Colour output is automatic (no colour when piped, colours in TTY)

## Testing on a Fresh Machine

To test the full install process:

```bash
# In a new environment:
git clone <repo> /tmp/test-server-manager
cd /tmp/test-server-manager

# Run installer (choose different repo location)
./install.sh
# > ~/.local/server-manager

# Test
source ~/.bashrc
server --help
server init  # Interactive setup
```

## Performance Notes

- `bash -n` syntax check on all files is instant
- `source lib/*.sh` is fast (4 small files)
- No external process calls except for git/ssh when needed
- lib/commands.sh (420 lines) is only read when needed

## Future Ideas

- [ ] Tab completion for bash/zsh
- [ ] Config validation (check that SERVER_ROOT is writable)
- [ ] Migrate SSH keys between namespaces
- [ ] SSH key with passphrase support
- [ ] Integration with 1Password/LastPass for passphrases
- [ ] Status dashboard (overall health of all namespaces)
