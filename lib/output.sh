#!/usr/bin/env bash
# output.sh — Logging, colour, and formatting helpers

# Colour constants (only when stdout is a TTY)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  RESET='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  RESET=''
fi

# die <message> — print error and exit
die() {
  printf "${RED}✗ Error:${RESET} %s\n" "$*" >&2
  exit 1
}

# info <message> — plain info
info() {
  printf "%s\n" "$*"
}

# ok <message> — success with green checkmark
ok() {
  printf "${GREEN}✓${RESET} %s\n" "$*"
}

# warn <message> — warning with yellow exclamation
warn() {
  printf "${YELLOW}!${RESET} %s\n" "$*"
}

# section <title> — a section header
section() {
  printf "\n${BLUE}=== %s ===${RESET}\n" "$*"
}

# print_pub_key <pubkey_file> — pretty-print SSH public key in a box
print_pub_key() {
  local pubkey_file="$1"
  
  if [[ ! -f "$pubkey_file" ]]; then
    return
  fi
  
  echo
  echo "Public SSH key:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cat "$pubkey_file"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  
  # Try to copy to clipboard
  if command -v pbcopy >/dev/null 2>&1; then
    cat "$pubkey_file" | pbcopy
    ok "Public key copied to clipboard"
  elif command -v xclip >/dev/null 2>&1; then
    cat "$pubkey_file" | xclip -selection clipboard
    ok "Public key copied to clipboard"
  elif command -v xsel >/dev/null 2>&1; then
    cat "$pubkey_file" | xsel --clipboard --input
    ok "Public key copied to clipboard"
  fi
}

# check_command <cmd> — die if command not found
check_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# prompt_yn <message> — ask yes/no, return 0 for yes
prompt_yn() {
  local msg="$1"
  local answer
  read -r -p "$msg [y/N] " answer </dev/tty
  [[ "$answer" =~ ^[Yy]$ ]]
}

# prompt_input <message> — ask for input, read from /dev/tty
prompt_input() {
  local msg="$1"
  local default="${2:-}"
  local answer
  
  if [[ -n "$default" ]]; then
    read -r -p "$msg [$default]: " answer </dev/tty
    [[ -z "$answer" ]] && answer="$default"
  else
    read -r -p "$msg: " answer </dev/tty
  fi
  
  echo "$answer"
}
