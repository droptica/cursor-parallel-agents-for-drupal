# Cursor Worktree for Drupal/DDEV

**Enable Cursor Parallel Agents in your Drupal project with one command.**

[Cursor Parallel Agents](https://cursor.com/docs/configuration/worktrees) run in isolated Git worktrees with separate DDEV environments. This installer configures everything automatically.

## Quick Start

```bash
cd your-drupal-project
curl -sL https://raw.githubusercontent.com/droptica/cursor-parallel-agents-for-drupal/main/install.sh | bash
```

That's it! The installer will:
1. Detect if your project is singlesite or multisite
2. Install appropriate configuration files
3. Auto-configure multisite (sites, databases, sites.php)
4. Create database snapshots
5. Update AGENTS.md with worktree instructions

## Requirements

- **DDEV** installed and configured
- **Git** repository initialized
- **Drupal** project with `web/` or `docroot/` structure

## Options

```bash
# Force project type
curl -sL .../install.sh | bash -s -- --type=multisite

# Dry-run (see what would be installed)
curl -sL .../install.sh | bash -s -- --dry-run

# Show help
curl -sL .../install.sh | bash -s -- --help
```

## What Gets Installed

### Singlesite Projects

```
.cursor/
├── worktrees.json      # Cursor worktree config
├── setup-worktree.sh   # Setup script for new worktrees
├── cleanup-worktree.sh # Cleanup script
├── README.md           # Documentation
├── lib/
│   └── logging.sh      # Shared logging functions
└── logs/               # Created automatically
    └── worktree-{ID}.log  # Logs per worktree

.ddev/commands/host/
├── export-snapshot     # Export database for worktrees
└── worktree-status     # Show active worktrees

AGENTS.md               # AI agent instructions (created/updated)
```

### Multisite Projects

Same as singlesite, plus:
- `lib/prerequisites.sh` - Validates snapshots before setup
- `export-multisite-snapshots` - Exports all site databases
- `sites.php` - Automatically patched with worktree patterns

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. Cursor creates worktree                                         │
│     └─ Isolated Git branch + files in separate directory            │
├─────────────────────────────────────────────────────────────────────┤
│  2. setup-worktree.sh runs automatically                            │
│     ├─ Creates unique DDEV project (e.g., myproject-a8Xk2)         │
│     ├─ Generates config.local.yaml with unique hostname             │
│     ├─ Symlinks files directory from main project                   │
│     └─ Imports database snapshot                                    │
├─────────────────────────────────────────────────────────────────────┤
│  3. Agent works in isolated environment                             │
│     ├─ Separate DDEV containers                                     │
│     ├─ Separate database                                            │
│     └─ Shared files (via symlink)                                   │
├─────────────────────────────────────────────────────────────────────┤
│  4. Apply changes                                                   │
│     └─ Merge worktree branch back to main                           │
└─────────────────────────────────────────────────────────────────────┘
```

## Resource Usage

| Resource | Per Worktree |
|----------|--------------|
| RAM | ~500MB |
| Disk | ~50MB (symlinked files) |
| Setup time | 30-60s |

**Recommended:** Max 3 concurrent worktrees.

Configure in `.cursor/settings.json`:
```json
{
  "cursor.worktreeMaxCount": 3,
  "cursor.worktreeCleanupIntervalHours": 2
}
```

## Commands

```bash
# Check worktree status
ddev worktree-status

# Export database snapshot (singlesite)
ddev export-snapshot

# Export all snapshots (multisite)
ddev export-multisite-snapshots

# Cleanup orphaned worktrees
.cursor/cleanup-worktree.sh --all
```

## Worktree URLs

Each worktree gets a unique URL:

| Environment | URL Pattern |
|-------------|-------------|
| Main Project | `https://myproject.ddev.site` |
| Worktree (a8Xk2) | `https://myproject-a8Xk2.ddev.site` |

For multisite, each site also gets a unique URL:

| Site | Main | Worktree |
|------|------|----------|
| Default | `https://myproject.ddev.site` | `https://myproject-a8Xk2.ddev.site` |
| PL | `https://pl.myproject.ddev.site` | `https://pl.myproject-a8Xk2.ddev.site` |

## Parallel Agents Workflow

When working as a Parallel Agent in a worktree:

1. **Complete your work**
2. **Commit and push:**
   ```bash
   git add -A
   git commit -m "[type]: description"
   git push origin HEAD
   ```
3. **Create PR** for code review

⚠️ **Important:** Config/DB changes should ALWAYS go through PR, not direct apply.

---

## Multisite Auto-Configuration

The installer automatically detects and configures multisite projects:

1. **Detects site directories** from `web/sites/` (e.g., `pl.example.com`)
2. **Detects additional hostnames** from `.ddev/config.yaml`
3. **Detects database names** from `.ddev/config.yaml` hooks
4. **Generates** `setup-worktree.sh` with detected configuration
5. **Generates** `export-multisite-snapshots` with all database exports
6. **Patches** `sites.php` with worktree pattern matching
7. **Exports all database snapshots** automatically

**No manual configuration required in most cases!**

### How Detection Works

**Site Directories:** Scans `web/sites/` for directories with dots (e.g., `pl.example.com`), excluding `default`, `all`, `simpletest`.

**Hostnames:** Extracted from `.ddev/config.yaml`:
```yaml
additional_hostnames:
  - pl.myproject
  - de.myproject
```

**Databases:** Extracted from hooks:
```yaml
hooks:
  post-start:
    - exec: mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS pl;"
```

### Manual Adjustments (Edge Cases)

If auto-detection doesn't match your setup, edit `.cursor/setup-worktree.sh`:

```bash
SITES=(
  "default"
  "pl.example.com"
  "de.example.com"
)

DB_NAMES=(
  "db"
  "pl"
  "de"
)

FILES_DIRS=(
  "${WEB_ROOT}/sites/default/files"
  "${WEB_ROOT}/sites/pl.example.com/files"
)
```

---

## Troubleshooting

### Installation Issues

#### "DDEV not found"
Install DDEV: https://ddev.readthedocs.io/en/stable/users/install/
```bash
# macOS
brew install ddev/ddev/ddev

# Linux
curl -fsSL https://ddev.com/install.sh | bash
```

#### "Not a DDEV project"
Initialize DDEV:
```bash
ddev config --project-type=drupal10 --docroot=web
ddev start
```

#### "Not a Git repository"
```bash
git init
git add -A
git commit -m "Initial commit"
```

### Worktree Setup Issues

#### "No snapshots found"
Snapshots are created automatically during installation. This error occurs only if:
- Snapshots were manually deleted
- You need to refresh after database changes

Recreate snapshots:
```bash
ddev export-snapshot              # singlesite
ddev export-multisite-snapshots   # multisite
```

#### "WORKTREE_ID is required" / "ROOT_WORKTREE_PATH is not set"
These scripts should only be run by Cursor, not manually.

### DDEV Issues

#### Port conflicts
```bash
ddev stop --all
ddev start
```

#### Container won't start
```bash
# Restart Docker, then:
ddev delete -O
ddev start
```

#### "Database import failed"
```bash
# Check snapshot exists and isn't corrupted
ls -la .ddev/db-dumps/
gunzip -t .ddev/db-dumps/*.sql.gz

# Try manual import
ddev import-db --file=.ddev/db-dumps/yourproject.sql.gz
```

### Multisite Issues

#### "Site not found" in worktree
1. Check `sites.php` has worktree patterns: `grep "worktree_pattern" web/sites/sites.php`
2. Verify site directory exists in `web/sites/`
3. Clear cache: `ddev drush cr`

#### Wrong site loads
1. Check `sites.php` patterns don't overlap
2. Verify pattern order (more specific first)

#### Additional database not found
1. Check DDEV creates databases in `post-start` hook
2. Ensure snapshot exists: `ls .ddev/db-dumps/`
3. Re-export: `ddev export-multisite-snapshots`

### Cleanup Issues

#### Orphaned DDEV projects
```bash
ddev list
.cursor/cleanup-worktree.sh --all
# Or manually: ddev stop myproject-a8Xk2 && ddev delete -O myproject-a8Xk2
```

#### Orphaned Git worktrees
```bash
git worktree list
git worktree remove /path/to/worktree --force
git worktree prune
```

#### Disk space running low
```bash
.cursor/cleanup-worktree.sh --all
docker system prune -a
```

### Performance Issues

#### Worktree setup is slow
- Use SSD storage
- Reduce database size
- Limit concurrent worktrees (max 2-3)

#### High memory usage
- Reduce `cursor.worktreeMaxCount` to 2
- Stop unused worktrees
- Increase system RAM

### Getting Help

1. Check DDEV logs: `ddev logs`
2. Check Docker logs: `docker logs ddev-myproject-web`
3. Open an issue: https://github.com/droptica/cursor-parallel-agents-for-drupal/issues

---

## Project Structure

```
cursor-parallel-agents-for-drupal/
├── install.sh              # Main installer script
├── README.md               # This file
├── LICENSE                 # MIT License
└── templates/
    ├── common/             # Shared templates (logging, cleanup, worktrees.json)
    ├── singlesite/         # Singlesite-specific (setup-worktree, export-snapshot)
    └── multisite/          # Multisite-specific (README, worktree-status)
```

Note: Multisite `setup-worktree.sh`, `prerequisites.sh`, and `export-multisite-snapshots` are generated dynamically by the installer based on detected configuration.

## Contributing

Issues and PRs welcome!

## License

MIT License - see [LICENSE](LICENSE)

---

## About Droptica

**Built with ❤️  by [Droptica](https://www.droptica.com) 🇵🇱**

Solid Open Source solutions for ambitious companies.

**What we do:**

- **Create:** Open Intranet, Droopler CMS, Druscan
- **AI Development:** AI chatbots (RAG), autonomous agents, OpenAI/Claude integrations, custom AI models, CMS content automation & translation, workflow automation
- **Customize:** Drupal, Mautic, Sylius, Symfony
- **Support & maintain:** Security, updates, training, monitoring 24/7

**Trusted by:** Corporations • SMEs • Startups • Universities • Government
