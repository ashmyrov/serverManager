#!/usr/bin/env bash
# commands.sh — All CLI commands

# Helper to get gitconfig path (defined here for local use, also in git.sh)
get_namespace_gitconfig() {
  local ns="$1"
  local base_dir
  base_dir="$(dirname "$GITCONFIG_SERVER")"
  echo "$base_dir/gitconfig-$ns"
}

norm_ns() {
  local ns
  ns="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$ns" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "Invalid name '$1'"
  echo "$ns"
}

find_namespace_dir() {
  local want_lc="$1"
  for d in "$SERVER_ROOT"/*/; do
    [[ -d "$d" ]] || continue
    if [[ "$(basename "$d" | tr '[:upper:]' '[:lower:]')" == "$want_lc" ]]; then
      echo "${d%/}"
      return 0
    fi
  done
  return 1
}

# cmd_init — first-time setup wizard
cmd_init() {
  local conf="$HOME/.server-manager.conf"
  
  if [[ -f "$conf" ]]; then
    warn "Config already exists at $conf"
    info "Current settings:"
    cat "$conf"
    return
  fi
  
  info "Welcome to server-manager!"
  info
  
  local root ssh_dir gc_main gc_server
  root="$(prompt_input "Server root folder" "$HOME/Server")"
  ssh_dir="$(prompt_input "SSH directory" "$HOME/.ssh")"
  gc_main="$(prompt_input "Main gitconfig" "$HOME/.gitconfig")"
  gc_server="$(prompt_input "Server gitconfig" "$HOME/.gitconfig-server")"
  
  cat > "$conf" <<EOF
SERVER_ROOT="$root"
SSH_DIR="$ssh_dir"
GITCONFIG_MAIN="$gc_main"
GITCONFIG_SERVER="$gc_server"
EOF
  
  ok "Created $conf"
  
  # Source the new config
  source "$conf"
  
  # Ensure main git include
  ensure_main_git_include
  
  # Offer to create first namespace
  if prompt_yn "Create your first namespace now?"; then
    local first_name
    first_name="$(prompt_input "Namespace name")"
    cmd_new "$first_name"
  fi
}

# cmd_new — create a new namespace
cmd_new() {
  local folder="$1"
  local ns; ns="$(norm_ns "$folder")"

  mkdir -p "$SERVER_ROOT"
  ensure_main_git_include

  if dir="$(find_namespace_dir "$ns")"; then
    warn "Namespace exists: $dir"
    cmd_ensure "$folder"
    return
  fi

  section "Creating namespace '$ns'"

  local git_name git_email
  git_name="$(prompt_input "Git user.name" "")"
  git_email="$(prompt_input "Git user.email" "")"

  local dir="$SERVER_ROOT/$folder"
  mkdir -p "$dir"
  ok "Created $dir"

  ensure_ssh_key "$ns"
  ensure_gitconfig_file "$ns" "$git_name" "$git_email"
  ensure_include_if "$dir" "$ns"
  print_pub_key "$SSH_DIR/$ns.pub"
}

# cmd_ensure — ensure a namespace is fully set up
cmd_ensure() {
  local name="$1"
  local ns; ns="$(norm_ns "$name")"

  ensure_main_git_include
  ensure_ssh_key "$ns"
  ensure_gitconfig_file "$ns"
  ensure_git_identity "$ns"

  if dir="$(find_namespace_dir "$ns")"; then
    ensure_include_if "$dir" "$ns"
  fi

  print_pub_key "$SSH_DIR/$ns.pub"
}

# cmd_bootstrap — ensure all existing namespaces
cmd_bootstrap() {
  ensure_main_git_include
  mkdir -p "$SERVER_ROOT"

  local count=0
  for d in "$SERVER_ROOT"/*/; do
    [[ -d "$d" ]] || continue
    local folder ns
    folder="$(basename "${d%/}")"
    ns="$(norm_ns "$folder")"

    ensure_ssh_key "$ns"
    ensure_gitconfig_file "$ns"
    ensure_git_identity "$ns"
    ensure_include_if "${d%/}" "$ns"
    ((count++))
  done

  ok "Bootstrap complete ($count namespace$([ $count -eq 1 ] && echo || echo 's'))"
}

# cmd_check — show status of a namespace
cmd_check() {
  local name="$1"
  local ns; ns="$(norm_ns "$name")"
  local cfg
  cfg="$(get_namespace_gitconfig "$ns")"
  local dir=""

  section "Namespace: $ns"

  if dir="$(find_namespace_dir "$ns")"; then
    ok "Folder: $dir"
  else
    warn "Folder: MISSING"
  fi

  if [[ -f "$SSH_DIR/$ns" ]]; then
    ok "SSH key: present"
  else
    warn "SSH key: missing"
  fi

  if [[ -f "$cfg" ]]; then
    ok "Git config: present"
    local cur_name cur_email
    cur_name="$(git config --file "$cfg" user.name  2>/dev/null || true)"
    cur_email="$(git config --file "$cfg" user.email 2>/dev/null || true)"
    if [[ -n "$cur_name" ]]; then
      info "  ✓ user.name:  $cur_name"
    else
      warn "  ✗ user.name:  missing"
    fi
    if [[ -n "$cur_email" ]]; then
      info "  ✓ user.email: $cur_email"
    else
      warn "  ✗ user.email: missing"
    fi
  else
    warn "Git config: missing"
  fi

  if [[ -n "$dir" ]] && grep -Fq "gitdir:$dir/" "$GITCONFIG_SERVER" 2>/dev/null; then
    ok "includeIf rule: present"
  else
    warn "includeIf rule: missing"
  fi
}

# cmd_list — show all namespaces with status
cmd_list() {
  mkdir -p "$SERVER_ROOT"
  
  local count=0
  local missing_count=0
  
  section "Namespaces"
  
  for d in "$SERVER_ROOT"/*/; do
    [[ -d "$d" ]] || continue
    
    local folder ns dir
    folder="$(basename "${d%/}")"
    ns="$(norm_ns "$folder")"
    dir="${d%/}"
    
     # Check each component
     local folder_ok=0 ssh_ok=0 git_ok=0 include_ok=0 identity_ok=0
     local cfg
     cfg="$(get_namespace_gitconfig "$ns")"
     
     [[ -d "$dir" ]] && folder_ok=1
     [[ -f "$SSH_DIR/$ns" ]] && ssh_ok=1
     [[ -f "$cfg" ]] && git_ok=1
     
     if [[ -f "$cfg" ]]; then
       local cur_name cur_email
       cur_name="$(git config --file "$cfg" user.name  2>/dev/null || true)"
       cur_email="$(git config --file "$cfg" user.email 2>/dev/null || true)"
       [[ -n "$cur_name" && -n "$cur_email" ]] && identity_ok=1
     fi
    
    grep -Fq "gitdir:$dir/" "$GITCONFIG_SERVER" 2>/dev/null && include_ok=1
    
    # Determine status
    local status_mark="✓"
    if [[ $folder_ok -eq 0 || $ssh_ok -eq 0 || $git_ok -eq 0 || $include_ok -eq 0 || $identity_ok -eq 0 ]]; then
      status_mark="!"
      ((missing_count++))
    fi
    
    printf "  [%s] %-20s " "$status_mark" "$ns"
    [[ $folder_ok -eq 1 ]] && printf "folder " || printf "       "
    [[ $ssh_ok -eq 1 ]] && printf "ssh " || printf "    "
    [[ $git_ok -eq 1 ]] && printf "git " || printf "    "
    [[ $identity_ok -eq 1 ]] && printf "identity " || printf "         "
    [[ $include_ok -eq 1 ]] && printf "routing" || printf "       "
    printf "\n"
    
    ((count++))
  done
  
  if [[ $count -eq 0 ]]; then
    warn "No namespaces found"
  else
    info
    [[ $missing_count -eq 0 ]] && ok "All $count namespace$([ $count -eq 1 ] && echo || echo 's') healthy" || warn "$missing_count namespace$([ $missing_count -eq 1 ] && echo || echo 's') need attention"
  fi
}

# cmd_rename — rename a namespace
cmd_rename() {
  local old_name="$1"
  local new_name="$2"
  
  local old_ns new_ns
  old_ns="$(norm_ns "$old_name")"
  new_ns="$(norm_ns "$new_name")"
  
  # Check old exists
  local old_dir
  if ! old_dir="$(find_namespace_dir "$old_ns")"; then
    die "Namespace '$old_ns' not found"
  fi
  
  # Check new doesn't exist
  if find_namespace_dir "$new_ns" >/dev/null 2>&1; then
    die "Namespace '$new_ns' already exists"
  fi
  
  section "Renaming: $old_ns → $new_ns"
  
  # Rename folder
  local new_dir="$SERVER_ROOT/$new_name"
  mv "$old_dir" "$new_dir"
  ok "Moved folder: $old_dir → $new_dir"
  
  # Get old identity for carry-over
  local old_cfg
  old_cfg="$(get_namespace_gitconfig "$old_ns")"
  local old_name_val="" old_email_val=""
  if [[ -f "$old_cfg" ]]; then
    old_name_val="$(git config --file "$old_cfg" user.name  2>/dev/null || true)"
    old_email_val="$(git config --file "$old_cfg" user.email 2>/dev/null || true)"
  fi
  
  # Remove old configs
  rm -f "$SSH_DIR/$old_ns" "$SSH_DIR/$old_ns.pub" "$old_cfg"
  ok "Removed old SSH and git configs"
  
  # Remove old includeIf
  remove_include_if "$old_dir"
  
  # Create new configs
  ensure_ssh_key "$new_ns"
  ensure_gitconfig_file "$new_ns" "$old_name_val" "$old_email_val"
  
  # Ask to confirm or change identity
  if [[ -z "$old_name_val" || -z "$old_email_val" ]]; then
    ensure_git_identity "$new_ns"
  else
    info "Carrying over git identity from old namespace"
    ok "Git identity: $old_name_val <$old_email_val>"
  fi
  
  ensure_include_if "$new_dir" "$new_ns"
  
  ok "Namespace renamed: $old_ns → $new_ns"
  print_pub_key "$SSH_DIR/$new_ns.pub"
}

# cmd_rm — remove a namespace
cmd_rm() {
  local name="$1"
  local ns; ns="$(norm_ns "$name")"
  local cfg
  cfg="$(get_namespace_gitconfig "$ns")"

  if dir="$(find_namespace_dir "$ns")"; then
    rm -rf "$dir"
    ok "Removed folder: $dir"
  fi

  remove_include_if "$dir" 2>/dev/null || true
  rm -f "$SSH_DIR/$ns" "$SSH_DIR/$ns.pub" "$cfg"
  ok "Removed SSH keys and git config for '$ns'"
}

# cmd_config — show configuration
cmd_config() {
  section "Configuration"
  info "Config file:      $HOME/.server-manager.conf"
  info "SERVER_ROOT:      $SERVER_ROOT"
  info "SSH_DIR:          $SSH_DIR"
  info "GITCONFIG_MAIN:   $GITCONFIG_MAIN"
  info "GITCONFIG_SERVER: $GITCONFIG_SERVER"
}

# show_help — display help
show_help() {
  cat <<'EOF'
server-manager — workspace-based SSH identity manager for Git

USAGE:
  server <command> [arguments]

COMMANDS:
  init
      First-time setup wizard. Creates ~/.server-manager.conf and 
      optionally creates your first namespace.

  new <FolderName>
      Create a new namespace.
      - Prompts for git user.name and user.email
      - Creates folder: SERVER_ROOT/<FolderName>
      - Generates Ed25519 SSH keypair: ~/.ssh/<namespace_lowercase>
      - Creates git config: ~/.gitconfig-<namespace_lowercase>
      - Adds includeIf rule so Git auto-selects the key
      - Displays public key (with clipboard copy if available)

  ensure <Name>
      Ensure a namespace is fully configured.
      - Creates missing SSH key if absent
      - Creates missing ~/.gitconfig-<namespace>
      - Prompts for git identity if missing
      - Adds missing includeIf rule
      Idempotent — safe to run multiple times.

  bootstrap
      Scan all folders under SERVER_ROOT and ensure each is fully set up.
      Useful after reinstalling your machine or restoring from backup.

  list
      Show all namespaces with their status (folder, SSH key, git config,
      git identity, includeIf routing).

  check <Name>
      Show detailed status of a single namespace.

  rename <OldName> <NewName>
      Rename a namespace, including all keys and configs.
      Preserves git identity if it was set.

  rm <Name>
      Remove a namespace completely.
      - Deletes folder under SERVER_ROOT
      - Deletes SSH key and public key
      - Deletes ~/.gitconfig-<namespace>
      - Removes includeIf rule from ~/.gitconfig-server

  config
      Show current configuration paths.

  -h, --help
      Show this help message.

CONCEPTS:
  - One folder = one Git identity
  - Folder names are case-preserved; SSH keys use lowercase
  - Git automatically selects the right key based on where a repo is cloned
  - Remote URLs stay standard: git@github.com:org/repo.git

FILES MODIFIED:
  ~/.server-manager.conf
      Your configuration (created by 'server init')

  ~/.gitconfig
      Main git config — one include line is added once

  ~/.gitconfig-server
      Managed by server-manager, contains includeIf routing rules

  ~/.gitconfig-<namespace>
      Per-namespace config with SSH command and user identity

  ~/.ssh/<namespace> and ~/.ssh/<namespace>.pub
      Ed25519 keypair for each namespace

EXAMPLES:
  server init                    # First-time setup
  server new Work                # Create a new namespace
  server list                    # See all namespaces
  server check work              # Inspect namespace status
  server ensure work             # Repair missing configs
  server bootstrap               # Set up after machine restore
  server rename work professional
  server rm work
  server config

For more info, see: https://github.com/your-org/server-manager
EOF
}
