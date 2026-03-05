#!/usr/bin/env bash
# ssh.sh — SSH key management

ensure_ssh_key() {
  local ns="$1"
  local key="$SSH_DIR/$ns"
  local pub="$SSH_DIR/$ns.pub"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [[ -f "$key" && -f "$pub" ]]; then
    return
  fi

  if [[ -f "$key" || -f "$pub" ]]; then
    die "Partial SSH key exists for '$ns' — remove both files or use 'server rm'"
  fi

  ssh-keygen -t ed25519 -a 64 -f "$key" -N "" -C "$USER@$(hostname)-$ns" >/dev/null
  chmod 600 "$key"
  chmod 644 "$pub"
  ok "Generated SSH key: $key"
}
