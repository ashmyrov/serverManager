#!/usr/bin/env bash
# install.sh — creates ~/bin/server pointing to this repository

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="$HOME/bin/server"
SHELL_RC="$HOME/.zshrc"
[[ "$SHELL" == */bash ]] && SHELL_RC="$HOME/.bashrc"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

printf "\n${BOLD}server-manager${RESET} — install\n"
printf "${DIM}──────────────────────────────────────${RESET}\n\n"

mkdir -p "$HOME/bin"

cat > "$WRAPPER" << EOF
#!/usr/bin/env bash
exec "$REPO_DIR/bin/server" "\$@"
EOF

chmod +x "$WRAPPER"
printf "  ${GREEN}✓${RESET}  Command ready:   ${BOLD}$WRAPPER${RESET}\n"
printf "  ${GREEN}✓${RESET}  Points to:       ${DIM}$REPO_DIR/bin/server${RESET}\n"

if ! grep -q 'HOME/bin' "$SHELL_RC" 2>/dev/null; then
  printf '\nexport PATH="$HOME/bin:$PATH"\n' >> "$SHELL_RC"
  printf "  ${GREEN}✓${RESET}  Added ~/bin to PATH in ${DIM}$SHELL_RC${RESET}\n"
fi

printf "\n${DIM}──────────────────────────────────────${RESET}\n"
printf "${BOLD}Next steps${RESET}\n\n"
printf "  1.  Reload your shell\n"
printf "      ${CYAN}source $SHELL_RC${RESET}\n\n"
printf "  2.  Run the setup wizard\n"
printf "      ${CYAN}server init${RESET}\n\n"
