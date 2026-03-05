# How to Change Username and Email

This guide shows how to change your Git identity (username/email) for any namespace in server-manager.

## Quick Answer

There are 3 ways to change your identity:

### Method 1: Using `git config` (Recommended for quick changes)

```bash
# Change name
git config --file ~/.gitconfig-personal user.name "Your New Name"

# Change email
git config --file ~/.gitconfig-personal user.email "you@newemail.com"

# Verify
server check personal
```

### Method 2: Using `server ensure` (Recommended for interactive)

```bash
server ensure personal
```

This will:
- Show current values
- Prompt you to enter new ones
- Update the config automatically
- Show what changed

### Method 3: Edit the file directly

```bash
vim ~/.gitconfig-personal
```

Then edit the `[user]` section:

```ini
[core]
    sshCommand = ssh -i /Users/andrii/.ssh/personal -o IdentitiesOnly=yes

[user]
    name = Your New Name
    email = your@new.email
```

## Your Current Identities

| Namespace | Name | Email |
|-----------|------|-------|
| personal | Test User | test@example.com |
| rsz | (not set) | (not set) |
| sab | (not set) | (not set) |

View all:
```bash
server list
server check personal
server check rsz
server check sab
```

## File Locations

Each namespace has its own config file:

- Personal: `~/.gitconfig-personal`
- Work: `~/.gitconfig-work`
- Any namespace: `~/.gitconfig-<namespace>`

## Examples

### Change one namespace

```bash
git config --file ~/.gitconfig-personal user.name "Alice Smith"
git config --file ~/.gitconfig-personal user.email "alice@gmail.com"
```

### Change multiple namespaces

```bash
# Work namespace
git config --file ~/.gitconfig-work user.name "Alice Developer"
git config --file ~/.gitconfig-work user.email "alice@company.com"

# Personal namespace
git config --file ~/.gitconfig-personal user.name "Alice Smith"
git config --file ~/.gitconfig-personal user.email "alice@gmail.com"

# Client namespace
git config --file ~/.gitconfig-client user.name "Alice (Consulting)"
git config --file ~/.gitconfig-client user.email "alice@consulting.com"
```

### Change email for all namespaces

```bash
for ns in personal work client; do
  git config --file ~/.gitconfig-$ns user.email "newemail@domain.com"
done
```

### Change only name, keep email

```bash
git config --file ~/.gitconfig-personal user.name "Your New Name"
# Email stays the same
```

### Change only email, keep name

```bash
git config --file ~/.gitconfig-personal user.email "you@new.email"
# Name stays the same
```

## Verify Changes

### Check one namespace

```bash
server check personal
```

Output:
```
=== Namespace: personal ===
✓ Folder: /Users/andrii/Server/personal
✓ SSH key: present
✓ Git config: present
  ✓ user.name:  Your New Name
  ✓ user.email: you@new.email
✓ includeIf rule: present
```

### Check all namespaces

```bash
server list
```

Output:
```
=== Namespaces ===
  [✓] personal    folder ssh git identity routing
  [✓] work        folder ssh git identity routing
  [!] client      folder ssh git          routing
```

(✓ = OK, ! = needs attention)

### View raw config

```bash
git config --file ~/.gitconfig-personal user.name
git config --file ~/.gitconfig-personal user.email
```

## Apply Changes to All Repos

Once you change the identity in `~/.gitconfig-<namespace>`, all repositories in that namespace will automatically use the new identity.

For example, if you have repos in `~/Server/personal/`:

```
~/Server/personal/repo1       → uses identity from ~/.gitconfig-personal
~/Server/personal/repo2       → uses identity from ~/.gitconfig-personal
~/Server/personal/sidproject  → uses identity from ~/.gitconfig-personal
```

All will use the same identity automatically!

## Test the Change

After changing identity, test with a git command:

```bash
cd ~/Server/personal/any-repo
git config user.name    # Should show your new name
git config user.email   # Should show your new email
```

## Reset to Default

If you want to reset, just delete the `[user]` section from the file:

```bash
vim ~/.gitconfig-personal
# Delete the [user] section
# Or use git config to clear:
git config --file ~/.gitconfig-personal --unset user.name
git config --file ~/.gitconfig-personal --unset user.email
```

Then run `server ensure` to set it again:

```bash
server ensure personal
```

## Common Issues

### "Changes aren't showing up"

Make sure you're using the correct namespace filename:

```bash
# Correct
git config --file ~/.gitconfig-personal user.name "New Name"

# Wrong (this won't work)
git config --file ~/.gitconfig-Work user.name "New Name"  # Case-sensitive!
```

### "Can't find the gitconfig file"

Check what namespaces you have:

```bash
ls ~/.gitconfig-*
```

This shows all namespace configs. Use the exact filename.

### "Changes take a long time to show up"

They should be instant! If not:
1. Check the file was actually updated: `cat ~/.gitconfig-personal`
2. Try `server check personal` to verify
3. Restart your shell if needed

## Summary

| Task | Command |
|------|---------|
| Change name | `git config --file ~/.gitconfig-<ns> user.name "Name"` |
| Change email | `git config --file ~/.gitconfig-<ns> user.email "email"` |
| View identity | `server check <namespace>` |
| Interactive change | `server ensure <namespace>` |
| View all | `server list` |
| Edit directly | `vim ~/.gitconfig-<namespace>` |
