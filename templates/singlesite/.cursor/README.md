# Cursor Parallel Agents Configuration

Configuration for Cursor Parallel Agents with DDEV single-site support.

## How it works

When you run a task in a **worktree** (parallel agent), Cursor:

1. Creates a Git worktree with isolated files
2. Runs `setup-worktree.sh` which:
   - Generates unique DDEV project name (e.g., `__PROJECT_NAME__-a8Xk2`)
   - Creates `config.local.yaml` with unique hostname
   - Starts isolated DDEV containers
   - Imports database snapshot

## Prerequisites

Before using parallel agents, ensure database snapshot exists:

```bash
ddev export-snapshot
```

This creates snapshot in `.ddev/db-dumps/__PROJECT_NAME__.sql.gz`

## Worktree URLs

Each worktree gets unique URL based on its ID (e.g., `a8Xk2`):

| Environment | URL |
|-------------|-----|
| Main Project | `https://__PROJECT_NAME__.ddev.site` |
| Worktree | `https://__PROJECT_NAME__-a8Xk2.ddev.site` |

## Resource Usage

- ~500MB RAM per worktree
- Setup time: ~30 seconds

## Files

| File | Purpose |
|------|---------|
| `worktrees.json` | Cursor worktree configuration |
| `setup-worktree.sh` | Runs when worktree is created |
| `cleanup-worktree.sh` | Cleans up orphaned worktrees |
| `lib/logging.sh` | Shared logging functions |

## Limitations

- **No LSP in worktrees** - Cursor doesn't support Language Server Protocol in worktrees
- **Windows not supported** - Unix-only due to DDEV/Docker requirements
- **Shared files** - Files directory is symlinked from main project

## Troubleshooting

### Worktree setup fails

1. Ensure database snapshot exists: `ls -la .ddev/db-dumps/`
2. Check DDEV is running: `ddev status`
3. View setup logs in terminal

### Port conflicts

```bash
ddev stop --all
ddev start
```

### Cleanup orphaned worktrees

```bash
.cursor/cleanup-worktree.sh --all
```
