#!/usr/bin/env bash
# git.sh — Git configuration management

# Get the gitconfig path for a namespace based on GITCONFIG_SERVER location
get_namespace_gitconfig() {
  local ns="$1"
  local base_dir
  base_dir="$(dirname "$GITCONFIG_SERVER")"
  echo "$base_dir/gitconfig-$ns"
}

ensure_main_git_include() {
  touch "$GITCONFIG_MAIN"
  if ! grep -Fq "path = $GITCONFIG_SERVER" "$GITCONFIG_MAIN"; then
    printf '\n[include]\n    path = %s\n' "$GITCONFIG_SERVER" >> "$GITCONFIG_MAIN"
    ok "Added include to $GITCONFIG_MAIN → $GITCONFIG_SERVER"
  fi
}

ensure_gitconfig_file() {
  local ns="$1"
  local git_name="${2:-}"
  local git_email="${3:-}"
  local cfg
  cfg="$(get_namespace_gitconfig "$ns")"
  local key="$SSH_DIR/$ns"

  if [[ ! -f "$cfg" ]]; then
    {
      printf '[core]\n    sshCommand = ssh -i %s -o IdentitiesOnly=yes\n' "$key"
      if [[ -n "$git_name" || -n "$git_email" ]]; then
        printf '\n[user]\n'
        [[ -n "$git_name" ]]  && printf '    name = %s\n'  "$git_name"
        [[ -n "$git_email" ]] && printf '    email = %s\n' "$git_email"
      fi
    } > "$cfg"
    ok "Created $cfg"
  fi
}

ensure_git_identity() {
  local ns="$1"
  local cfg
  cfg="$(get_namespace_gitconfig "$ns")"

  [[ -f "$cfg" ]] || return

  local cur_name cur_email
  cur_name="$(git config --file "$cfg" user.name  2>/dev/null || true)"
  cur_email="$(git config --file "$cfg" user.email 2>/dev/null || true)"

  # Always prompt - shows current value as default
  section "Git identity for namespace '$ns'"
  
  local git_name git_email
  git_name="$(prompt_input "Git user.name" "$cur_name")"
  git_email="$(prompt_input "Git user.email" "$cur_email")"

  git config --file "$cfg" user.name  "$git_name"
  git config --file "$cfg" user.email "$git_email"
  ok "Updated git identity in $cfg"
}

ensure_include_if() {
  local dir="$1"
  local ns="$2"
  local cfg
  cfg="$(get_namespace_gitconfig "$ns")"
  local block="[includeIf \"gitdir:$dir/\"]"

  touch "$GITCONFIG_SERVER"

  if grep -Fq "$block" "$GITCONFIG_SERVER"; then
    return
  fi

  cat >> "$GITCONFIG_SERVER" <<EOF

$block
    path = $cfg
EOF
  ok "Added includeIf for $dir/"
}

remove_include_if() {
  local dir="$1"
  local gitdir="gitdir:$dir/"

  [[ -f "$GITCONFIG_SERVER" ]] || return

  cp -a "$GITCONFIG_SERVER" "$GITCONFIG_SERVER.bak"

  awk -v gitdir="$gitdir" '
    BEGIN {skip=0}
    $0 ~ "\\[includeIf \"" gitdir "\"\\]" {skip=1; next}
    skip && /^\[/ {skip=0}
    skip {next}
    {print}
  ' "$GITCONFIG_SERVER.bak" > "$GITCONFIG_SERVER"
  
  ok "Removed includeIf for $dir/"
}
