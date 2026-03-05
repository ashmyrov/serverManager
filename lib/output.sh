#!/usr/bin/env bash
# output.sh — Logging, colour, and formatting helpers

# Colour constants (only when stderr is a TTY)
if [[ -t 2 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  DIM='\033[2m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

die()     { printf "\n${RED}${BOLD}✗ Error:${RESET} %s\n\n" "$*" >&2; exit 1; }
info()    { printf "%s\n" "$*"; }
ok()      { printf "  ${GREEN}✓${RESET}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${RESET}  %s\n" "$*"; }
step()    { printf "\n${BOLD}%s${RESET}\n" "$*"; }
dim()     { printf "${DIM}%s${RESET}\n" "$*"; }

section() {
  local title="$1"
  local width=60
  local line
  printf -v line '%*s' "$width" ''
  printf "\n${BLUE}${BOLD}%s${RESET}\n" "$title"
  printf "${BLUE}%s${RESET}\n" "${line// /─}"
}

# print_pub_key <pubkey_file>
print_pub_key() {
  local pubkey_file="$1"
  [[ -f "$pubkey_file" ]] || return

  printf "\n${CYAN}${BOLD}  Public SSH key${RESET}  ${DIM}(add this to GitHub / GitLab)${RESET}\n"
  printf "  ${DIM}%s${RESET}\n" "──────────────────────────────────────────────────────────"
  printf "  %s\n" "$(cat "$pubkey_file")"
  printf "  ${DIM}%s${RESET}\n\n" "──────────────────────────────────────────────────────────"

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$pubkey_file"
    ok "Public key copied to clipboard"
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$pubkey_file"
    ok "Public key copied to clipboard"
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$pubkey_file"
    ok "Public key copied to clipboard"
  fi
}

check_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

prompt_yn() {
  local msg="$1"
  local answer
  printf "  ${BOLD}?${RESET}  %s ${DIM}[y/N]${RESET} " "$msg" >&2
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

prompt_input() {
  local msg="$1"
  local default="${2:-}"
  local answer

  if [[ -n "$default" ]]; then
    printf "  ${BOLD}›${RESET}  %s ${DIM}[%s]${RESET}: " "$msg" "$default" >&2
  else
    printf "  ${BOLD}›${RESET}  %s: " "$msg" >&2
  fi

  read -r answer
  [[ -z "$answer" ]] && answer="$default"
  printf '%s\n' "$answer"
}
