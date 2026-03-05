#!/usr/bin/env bash
# install.sh — interactive installer for server-manager
# Lets user choose where to store the repo and config

set -euo pipefail

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

die() {
  printf "${RED}✗ Error:${RESET} %s\n" "$*" >&2
  exit 1
}

ok() {
  printf "${GREEN}✓${RESET} %s\n" "$*"
}

info() {
  printf "%s\n" "$*"
}

warn() {
  printf "${YELLOW}!${RESET} %s\n" "$*"
}

section() {
  printf "\n${BLUE}=== %s ===${RESET}\n" "$*"
}

prompt_input() {
  local msg="$1"
  local default="${2:-}"
  local answer
  
  if [[ -n "$default" ]]; then
    read -r -p "$msg [$default]: " answer
    [[ -z "$answer" ]] && answer="$default"
  else
    read -r -p "$msg: " answer
  fi
  
  echo "$answer"
}

prompt_yn() {
  local msg="$1"
  local answer
  read -r -p "$msg [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# Find script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section "server-manager installer"

# Check bash version (bash 3.2+ should work)
# Note: macOS ships with bash 3.2; we only check for very old versions
if [[ ${BASH_VERSINFO[0]} -lt 3 ]]; then
  die "Bash 3.2+ required (you have $BASH_VERSION)"
fi

# Check dependencies
for cmd in git ssh-keygen; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "$cmd not found. Please install it first."
  fi
done

ok "Dependencies found"
info

# Detect shell and rc file
SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
  bash)
    RC_FILE="$HOME/.bashrc"
    ;;
  zsh)
    RC_FILE="$HOME/.zshrc"
    ;;
  *)
    warn "Unsupported shell: $SHELL_NAME"
    RC_FILE="$HOME/.bashrc"
    info "Using ~/.bashrc as fallback"
    ;;
esac

info "Current shell rc file: $RC_FILE"
info

# Ask where to store the repository
section "Repository location"
info "Where should we store the server-manager repository?"
info "This is where the code lives and gets updated."
info

DEFAULT_REPO="$HOME/.local/server-manager"
REPO_PATH="$(prompt_input "Repository path" "$DEFAULT_REPO")"

# Expand tilde
REPO_PATH="${REPO_PATH/#\~/$HOME}"

# If repo path is different from current location, offer to move it
if [[ "$REPO_PATH" != "$SCRIPT_DIR" ]]; then
  if [[ -d "$REPO_PATH" ]]; then
    warn "Directory $REPO_PATH already exists"
    if ! prompt_yn "Overwrite?"; then
      die "Installation cancelled"
    fi
    rm -rf "$REPO_PATH"
  fi
  
  info
  info "Moving repository to $REPO_PATH..."
  mkdir -p "$(dirname "$REPO_PATH")"
  cp -r "$SCRIPT_DIR" "$REPO_PATH"
  ok "Repository copied"
fi

# Create ~/bin if needed
mkdir -p "$HOME/bin"
ok "Ensured $HOME/bin exists"

# Create wrapper script in ~/bin
WRAPPER="$HOME/bin/server"
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
# server — wrapper for server-manager
# Points to: $REPO_PATH/bin/server

exec "$REPO_PATH/bin/server" "\$@"
EOF

chmod +x "$WRAPPER"
ok "Created command wrapper: $WRAPPER"

# Add to PATH if needed
if grep -q "export PATH=.*\\\$HOME/bin" "$RC_FILE" 2>/dev/null; then
  ok "PATH already configured in $RC_FILE"
else
  printf '\nexport PATH="$HOME/bin:$PATH"\n' >> "$RC_FILE"
  ok "Added \$HOME/bin to PATH in $RC_FILE"
fi

info

# Ask about config location
section "Configuration"
info "Where should we store your ~/.server-manager.conf?"
info "This file holds your SERVER_ROOT, SSH_DIR, etc."
info

CONFIG_FILE="$HOME/.server-manager.conf"
if [[ -f "$CONFIG_FILE" ]]; then
  warn "Config already exists at $CONFIG_FILE"
  if prompt_yn "Keep existing config?"; then
    ok "Using existing config"
  else
    rm "$CONFIG_FILE"
    info "Config deleted, will be created by 'server init'"
  fi
else
  info "Config will be created when you run 'server init'"
fi

info

section "Installation complete!"

info "Next steps:"
info
info "1. Reload your shell config:"
info "   source $RC_FILE"
info
info "2. Initialize server-manager:"
info "   server init"
info
info "3. Create your first namespace:"
info "   server new Work"
info
info "4. View help:"
info "   server --help"
info
ok "Happy coding!"
