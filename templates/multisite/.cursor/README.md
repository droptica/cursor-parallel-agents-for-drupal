# Cursor Parallel Agents Configuration (Multisite)

Configuration for Cursor Parallel Agents with DDEV multisite support.

## How it works

When you run a task in a **worktree** (parallel agent), Cursor:

1. Creates a Git worktree with isolated files
2. Runs `setup-worktree.sh` which:
   - Generates unique DDEV project name (e.g., `__PROJECT_NAME__-a8Xk2`)
   - Creates `config.local.yaml` with unique hostnames for all sites
   - Starts isolated DDEV containers with all databases
   - Imports database snapshots for all sites

## Prerequisites

Before using parallel agents, ensure database snapshots exist:

```bash
ddev export-multisite-snapshots
```

This creates snapshots in `.ddev/db-dumps/` for all configured sites.

## Worktree URLs

Each worktree gets unique URLs for all sites based on its ID (e.g., `a8Xk2`):

| Site | Main Project | Worktree |
|------|--------------|----------|
| Main | `https://__PROJECT_NAME__.ddev.site` | `https://__PROJECT_NAME__-a8Xk2.ddev.site` |
| PL | `https://pl.__PROJECT_NAME__.ddev.site` | `https://pl.__PROJECT_NAME__-a8Xk2.ddev.site` |

## Resource Usage

- ~500MB+ RAM per worktree (more for multisite)
- ~50-100MB disk (symlinked files)
- Setup time: ~60-90 seconds

## Files

| File | Purpose |
|------|---------|
| `worktrees.json` | Cursor worktree configuration |
| `setup-worktree.sh` | Runs when worktree is created |
| `cleanup-worktree.sh` | Cleans up orphaned worktrees |
| `lib/logging.sh` | Shared logging functions |
| `lib/prerequisites.sh` | Validates snapshots before setup |

## Configuration

### Adding new sites

Edit `setup-worktree.sh` and update:

1. `SITES` array - add site directory names
2. `DB_NAMES` array - add database names
3. `FILES_DIRS` array - add files directory paths
4. `ADDITIONAL_HOSTNAMES` - add hostname mappings

### sites.php configuration

Your `sites.php` needs worktree pattern matching. Example:

```php
<?php
$host = $_SERVER['HTTP_HOST'] ?? '';

// Worktree pattern: __PROJECT_NAME__-{worktreeId}.ddev.site
if (preg_match('/^__PROJECT_NAME__-([a-zA-Z0-9]+)\.ddev\.site$/', $host)) {
  $sites[$host] = 'default';
}

// For additional sites with pattern: {prefix}.__PROJECT_NAME__-{worktreeId}.ddev.site
if (preg_match('/^pl\.__PROJECT_NAME__-([a-zA-Z0-9]+)\.ddev\.site$/', $host)) {
  $sites[$host] = 'pl.example.com';
}
```

## Limitations

- **No LSP in worktrees** - Cursor doesn't support Language Server Protocol in worktrees
- **Windows not supported** - Unix-only due to DDEV/Docker requirements
- **Shared files** - Files directories are symlinked from main project
- **Higher resource usage** - Multisite requires more RAM per worktree

## Troubleshooting

### Worktree setup fails

1. Ensure all database snapshots exist: `ls -la .ddev/db-dumps/`
2. Check DDEV is running: `ddev status`
3. Verify sites.php has worktree patterns

### Site not found in worktree

Check sites.php has the correct worktree pattern matching for the site.

### Cleanup orphaned worktrees

```bash
.cursor/cleanup-worktree.sh --all
```
