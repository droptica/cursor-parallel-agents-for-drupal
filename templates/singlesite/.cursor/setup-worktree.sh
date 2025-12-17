#!/bin/bash
#
# Cursor Worktree Setup Script for Drupal/DDEV (Singlesite)
#
# This script is executed by Cursor when creating a new worktree.
# It sets up an isolated DDEV environment with its own database.
#

set -e

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"

# Worktree ID - extract from environment, argument, or current directory
# Use bash parameter expansion ${var##*/} instead of basename for reliability
RAW_ID=""
if [[ -n "$CURSOR_WORKTREE_ID" ]]; then
  RAW_ID="$CURSOR_WORKTREE_ID"
elif [[ -n "${1:-}" ]]; then
  RAW_ID="$1"
else
  RAW_ID="$(pwd)"
fi

# Extract basename using parameter expansion (more reliable than basename command)
WORKTREE_ID="${RAW_ID##*/}"

# Validate: WORKTREE_ID must not be empty or contain path separators
if [[ -z "$WORKTREE_ID" ]] || [[ "$WORKTREE_ID" == */* ]]; then
  log_error "Invalid WORKTREE_ID: '${WORKTREE_ID}' (from: '${RAW_ID}')"
  exit 1
fi

# Auto-detect ROOT_WORKTREE_PATH if not set
if [[ -z "$ROOT_WORKTREE_PATH" ]]; then
  # In a git worktree, .git is a file pointing to the main repo
  if [[ -f ".git" ]]; then
    # Get the main worktree path (first line from git worktree list)
    ROOT_WORKTREE_PATH=$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)
  fi
fi

if [[ -z "$ROOT_WORKTREE_PATH" ]]; then
  log_error "Could not detect ROOT_WORKTREE_PATH - are you in a git worktree?"
  exit 1
fi

# Project configuration
PROJECT_NAME="__PROJECT_NAME__-${WORKTREE_ID}"
SNAPSHOTS_DIR=".ddev/db-dumps"
MAIN_SNAPSHOT="${SNAPSHOTS_DIR}/__PROJECT_NAME__.sql.gz"

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------
log_step "Validating environment"

log_info "Worktree ID: ${WORKTREE_ID}"
log_info "Project name: ${PROJECT_NAME}"
log_info "Root worktree: ${ROOT_WORKTREE_PATH}"

# Check for required snapshot
if [[ ! -f "${ROOT_WORKTREE_PATH}/${MAIN_SNAPSHOT}" ]]; then
  log_error "Database snapshot not found: ${ROOT_WORKTREE_PATH}/${MAIN_SNAPSHOT}"
  log_error "Run 'ddev export-snapshot' in the main project first"
  exit 1
fi
log_success "Database snapshot found"

#------------------------------------------------------------------------------
# Copy DDEV configuration from main project
#------------------------------------------------------------------------------
log_step "Copying DDEV configuration"

if [[ ! -d ".ddev" ]]; then
  if [[ -d "${ROOT_WORKTREE_PATH}/.ddev" ]]; then
    # Copy .ddev directory from main project (excluding runtime files)
    mkdir -p .ddev
    cp -r "${ROOT_WORKTREE_PATH}/.ddev/config.yaml" .ddev/ 2>/dev/null || true
    cp -r "${ROOT_WORKTREE_PATH}/.ddev/providers" .ddev/ 2>/dev/null || true
    cp -r "${ROOT_WORKTREE_PATH}/.ddev/commands" .ddev/ 2>/dev/null || true
    cp -r "${ROOT_WORKTREE_PATH}/.ddev/docker-compose.*.yaml" .ddev/ 2>/dev/null || true
    cp -r "${ROOT_WORKTREE_PATH}/.ddev/.gitignore" .ddev/ 2>/dev/null || true
    log_success "Copied .ddev configuration from main project"
  else
    log_error "Main project .ddev directory not found: ${ROOT_WORKTREE_PATH}/.ddev"
    exit 1
  fi
else
  log_info ".ddev directory already exists"
fi

#------------------------------------------------------------------------------
# Generate DDEV local configuration
#------------------------------------------------------------------------------
log_step "Generating DDEV local configuration"

cat > .ddev/config.local.yaml << EOF
# Auto-generated for Cursor worktree: ${WORKTREE_ID}
# DO NOT COMMIT THIS FILE

name: ${PROJECT_NAME}

override_config: true

web_environment:
  - CURSOR_WORKTREE_ID=${WORKTREE_ID}
EOF

log_success "Generated .ddev/config.local.yaml"

#------------------------------------------------------------------------------
# Create Git branch
#------------------------------------------------------------------------------
log_step "Setting up Git branch"

BRANCH_NAME="worktree/${WORKTREE_ID}"

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  log_info "Branch ${BRANCH_NAME} already exists, checking out"
  git checkout "${BRANCH_NAME}"
else
  log_info "Creating new branch: ${BRANCH_NAME}"
  git checkout -b "${BRANCH_NAME}"
fi

log_success "Git branch ready: ${BRANCH_NAME}"

#------------------------------------------------------------------------------
# Setup files directory symlink
#------------------------------------------------------------------------------
log_step "Setting up files directory"

WEB_ROOT="web"
if [[ -d "docroot" ]]; then
  WEB_ROOT="docroot"
fi

FILES_DIR="${WEB_ROOT}/sites/default/files"
MAIN_FILES_DIR="${ROOT_WORKTREE_PATH}/${FILES_DIR}"

if [[ -d "$MAIN_FILES_DIR" ]]; then
  # Remove existing files directory if it exists
  rm -rf "$FILES_DIR"

  # Ensure parent directory exists
  mkdir -p "$(dirname "$FILES_DIR")"

  # Create symlink to main project's files
  ln -sf "$MAIN_FILES_DIR" "$FILES_DIR"
  log_success "Symlinked files directory: ${FILES_DIR} → ${MAIN_FILES_DIR}"
else
  log_warn "Main files directory not found: ${MAIN_FILES_DIR}"
  mkdir -p "$FILES_DIR"
  log_info "Created empty files directory"
fi

#------------------------------------------------------------------------------
# Start DDEV
#------------------------------------------------------------------------------
log_step "Starting DDEV"

ddev start

log_success "DDEV started"

#------------------------------------------------------------------------------
# Import database
#------------------------------------------------------------------------------
log_step "Importing database"

SNAPSHOT_PATH="${ROOT_WORKTREE_PATH}/${MAIN_SNAPSHOT}"

log_info "Importing from: ${SNAPSHOT_PATH}"
ddev import-db --file="$SNAPSHOT_PATH"

log_success "Database imported"

#------------------------------------------------------------------------------
# Clear cache
#------------------------------------------------------------------------------
log_step "Clearing Drupal cache"

ddev drush cr || log_warn "Cache clear failed (may be normal for fresh installs)"

log_success "Cache cleared"

#------------------------------------------------------------------------------
# Health check
#------------------------------------------------------------------------------
log_step "Running health check"

# Get site URL
SITE_URL=$(ddev describe -j | grep -o '"https://[^"]*\.ddev\.site"' | head -1 | tr -d '"')

if [[ -z "$SITE_URL" ]]; then
  SITE_URL="https://${PROJECT_NAME}.ddev.site"
fi

log_info "Site URL: ${SITE_URL}"

# Check if site responds
if curl -sI "$SITE_URL" | head -1 | grep -q "200\|301\|302\|303"; then
  log_success "Site is responding"
else
  log_warn "Site may not be fully ready yet"
fi

#------------------------------------------------------------------------------
# Generate login link
#------------------------------------------------------------------------------
log_step "Generating admin login"

LOGIN_URL=$(ddev drush uli --uri="$SITE_URL" 2>/dev/null || echo "")

if [[ -n "$LOGIN_URL" ]]; then
  log_success "Admin login URL: ${LOGIN_URL}"
else
  log_warn "Could not generate login URL"
fi

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
log_step "Setup complete"
log_info "Worktree ID: ${WORKTREE_ID}"
log_info "Project: ${PROJECT_NAME}"
log_info "Branch: ${BRANCH_NAME}"
log_info "URL: ${SITE_URL}"

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  ✅ Worktree Setup Complete!                                       ║"
echo "╠════════════════════════════════════════════════════════════════════╣"
echo "║  Worktree ID: ${WORKTREE_ID}"
echo "║  Project: ${PROJECT_NAME}"
echo "║  Branch: ${BRANCH_NAME}"
echo "║  URL: ${SITE_URL}"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
