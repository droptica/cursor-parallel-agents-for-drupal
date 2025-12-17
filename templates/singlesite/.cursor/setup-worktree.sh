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

#------------------------------------------------------------------------------
# Create fresh database snapshot from main project
#------------------------------------------------------------------------------
log_step "Creating fresh database snapshot"

SNAPSHOT_PATH="${ROOT_WORKTREE_PATH}/${MAIN_SNAPSHOT}"
SNAPSHOT_START=$(date +%s)

log_info "Exporting database from main project..."

# Ensure snapshots directory exists
mkdir -p "${ROOT_WORKTREE_PATH}/${SNAPSHOTS_DIR}"

# Export database from main project (run ddev in main project context)
pushd "${ROOT_WORKTREE_PATH}" > /dev/null
if ! ddev export-db --gzip --file="${MAIN_SNAPSHOT}" 2>&1; then
  log_error "Failed to create database snapshot"
  popd > /dev/null
  exit 1
fi
popd > /dev/null

SNAPSHOT_END=$(date +%s)
SNAPSHOT_DURATION=$((SNAPSHOT_END - SNAPSHOT_START))
SNAPSHOT_SIZE=$(du -h "${SNAPSHOT_PATH}" | cut -f1)

log_success "Snapshot created: ${SNAPSHOT_SIZE} in ${SNAPSHOT_DURATION}s"
log_info "Snapshot path: ${SNAPSHOT_PATH}"

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
# Install composer dependencies
#------------------------------------------------------------------------------
log_step "Checking composer dependencies"

if [[ ! -d "vendor" ]]; then
  log_info "vendor/ not found - running composer install..."
  COMPOSER_START=$(date +%s)
  if ddev composer install --no-interaction 2>&1; then
    COMPOSER_END=$(date +%s)
    log_success "Composer install completed in $((COMPOSER_END - COMPOSER_START))s"
  else
    log_warn "Composer install failed - site may not work correctly"
  fi
else
  log_info "vendor/ exists - skipping composer install"
fi

#------------------------------------------------------------------------------
# Build theme assets (if needed)
#------------------------------------------------------------------------------
log_step "Checking theme build"

THEME_BUILT=false

# Method 1: ddev theme command (custom DDEV command)
if command -v ddev &>/dev/null && ddev describe 2>/dev/null | grep -q "theme"; then
  log_info "Found 'ddev theme' command - running..."
  THEME_START=$(date +%s)
  if ddev theme 2>&1; then
    THEME_END=$(date +%s)
    log_success "Theme built with 'ddev theme' in $((THEME_END - THEME_START))s"
    THEME_BUILT=true
  else
    log_warn "'ddev theme' failed"
  fi
fi

# Method 2: npm/yarn in theme directory
if [[ "$THEME_BUILT" == "false" ]]; then
  # Find theme directory with package.json
  THEME_DIR=""
  for dir in web/themes/custom/*/package.json themes/custom/*/package.json; do
    if [[ -f "$dir" ]]; then
      THEME_DIR=$(dirname "$dir")
      break
    fi
  done

  if [[ -n "$THEME_DIR" ]]; then
    log_info "Found theme with package.json: ${THEME_DIR}"
    pushd "$THEME_DIR" > /dev/null
    
    THEME_START=$(date +%s)
    
    # Check for yarn.lock or package-lock.json
    if [[ -f "yarn.lock" ]]; then
      log_info "Using yarn..."
      if ddev exec "cd $THEME_DIR && yarn install && yarn build" 2>&1; then
        THEME_BUILT=true
      fi
    elif [[ -f "package-lock.json" ]] || [[ -f "package.json" ]]; then
      log_info "Using npm..."
      if ddev exec "cd $THEME_DIR && npm ci && npm run build" 2>&1; then
        THEME_BUILT=true
      elif ddev exec "cd $THEME_DIR && npm install && npm run build" 2>&1; then
        THEME_BUILT=true
      fi
    fi
    
    popd > /dev/null
    
    if [[ "$THEME_BUILT" == "true" ]]; then
      THEME_END=$(date +%s)
      log_success "Theme built in $((THEME_END - THEME_START))s"
    else
      log_warn "Theme build failed - CSS/JS may be missing"
    fi
  else
    log_info "No theme with package.json found - skipping build"
  fi
fi

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
