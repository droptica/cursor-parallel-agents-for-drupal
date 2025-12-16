#!/bin/bash
#
# Cursor Worktree Installer for Drupal/DDEV
# https://github.com/droptica/cursor-worktree-drupal
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/droptica/cursor-worktree-drupal/main/install.sh | bash
#   curl -sL .../install.sh | bash -s -- --type=multisite
#   curl -sL .../install.sh | bash -s -- --dry-run
#

set -e

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
REPO_URL="https://github.com/droptica/cursor-parallel-agents-for-drupal.git"
REPO_SSH_URL="git@github.com:droptica/cursor-parallel-agents-for-drupal.git"
VERSION="1.0.0"
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# Logging functions
#------------------------------------------------------------------------------
log() { echo -e "[$(date '+%H:%M:%S')] [$1] ${@:2}"; }
log_info() { log "${BLUE}INFO${NC}" "$@"; }
log_success() { log "${GREEN}OK${NC}" "$@"; }
log_warn() { log "${YELLOW}WARN${NC}" "$@"; }
log_error() { log "${RED}ERROR${NC}" "$@"; }

#------------------------------------------------------------------------------
# Header
#------------------------------------------------------------------------------
show_header() {
  clear 2>/dev/null || true
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ "
  echo "  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗"
  echo "  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝"
  echo "  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗"
  echo "  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║"
  echo "   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
  echo ""
  echo "  ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗████████╗██████╗ ███████╗███████╗"
  echo "  ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝"
  echo "  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝    ██║   ██████╔╝█████╗  █████╗  "
  echo "  ██║███╗██║██║   ██║██╔══██╗██╔═██╗    ██║   ██╔══██╗██╔══╝  ██╔══╝  "
  echo "  ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗   ██║   ██║  ██║███████╗███████╗"
  echo "   ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
  echo -e "${NC}"
  echo -e "${BLUE}              PARALLEL AGENTS FOR DRUPAL/DDEV${NC}"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}    Run multiple AI agents in isolated environments${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  Enable Cursor Parallel Agents for your Drupal project."
  echo -e "  Each agent runs in an isolated Git worktree with its own"
  echo -e "  DDEV environment and database."
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${MAGENTA}${BOLD}Built with ❤️  by Droptica${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${YELLOW}Solid Open Source solutions for ambitious companies${NC}"
  echo ""
  echo -e "${BOLD}What we do:${NC}"
  echo ""
  echo -e "  ${BOLD}Create:${NC}     Open Intranet, Droopler CMS, Druscan"
  echo -e "  ${BOLD}AI Dev:${NC}     AI chatbots (RAG), autonomous agents, OpenAI/Claude"
  echo -e "              integrations, custom AI models, workflow automation"
  echo -e "  ${BOLD}Customize:${NC}  Drupal, Mautic, Sylius, Symfony"
  echo -e "  ${BOLD}Support:${NC}    Security, updates, training, monitoring 24/7"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}Website: ${BLUE}https://www.droptica.com${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}Cursor Worktree Installer for Drupal/DDEV v${VERSION}${NC}"
  echo -e "${MAGENTA}Built by Droptica${NC} - ${BLUE}https://www.droptica.com${NC}"
  echo ""
  echo -e "${BOLD}Usage:${NC}"
  echo "  curl -sL ${REPO_RAW_URL}/install.sh | bash"
  echo "  curl -sL .../install.sh | bash -s -- [OPTIONS]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  --type=singlesite    Force singlesite installation"
  echo "  --type=multisite     Force multisite installation"
  echo "  --dry-run            Show what would be installed without making changes"
  echo "  --help, -h           Show this help message"
  echo ""
  echo -e "${BOLD}Requirements:${NC}"
  echo "  - DDEV installed and configured"
  echo "  - Git repository initialized"
  echo "  - Drupal project with web/ or docroot/ structure"
  echo ""
  echo -e "${BOLD}Documentation:${NC} ${BLUE}https://github.com/droptica/cursor-worktree-drupal${NC}"
  echo ""
}

#------------------------------------------------------------------------------
# Parse arguments
#------------------------------------------------------------------------------
DRY_RUN=false
FORCE_TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --type=*) FORCE_TYPE="${1#*=}"; shift ;;
    --help|-h) show_help; exit 0 ;;
    *) log_error "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

#------------------------------------------------------------------------------
# Requirement checks
#------------------------------------------------------------------------------
check_requirements() {
  log_info "Checking requirements..."

  # Must have curl
  if ! command -v curl &>/dev/null; then
    log_error "curl is not installed"
    exit 1
  fi

  # Must have DDEV
  if ! command -v ddev &>/dev/null; then
    log_error "DDEV is not installed. Install from: https://ddev.readthedocs.io/"
    exit 1
  fi
  log_success "DDEV found: $(ddev --version 2>/dev/null | head -1 || echo 'unknown version')"

  # Must be in DDEV project
  if [[ ! -f ".ddev/config.yaml" ]]; then
    log_error "Not in a DDEV project directory (no .ddev/config.yaml found)"
    log_error "Run this command from your Drupal project root"
    exit 1
  fi
  log_success "DDEV project found"

  # Must have Git
  if ! command -v git &>/dev/null; then
    log_error "Git is not installed"
    exit 1
  fi
  log_success "Git found"

  # Must be Git repository
  if [[ ! -d ".git" ]]; then
    log_error "Not a Git repository. Initialize with: git init"
    exit 1
  fi
  log_success "Git repository found"

  # Check if .cursor already exists
  if [[ -d ".cursor" ]]; then
    log_warn ".cursor directory already exists"
    if [[ "$DRY_RUN" == "false" ]]; then
      read -p "Overwrite existing configuration? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted by user"
        exit 0
      fi
    fi
  fi
}

#------------------------------------------------------------------------------
# Project detection
#------------------------------------------------------------------------------
detect_web_root() {
  if [[ -d "web/sites" ]]; then
    echo "web"
  elif [[ -d "docroot/sites" ]]; then
    echo "docroot"
  else
    log_error "Cannot detect web root (web/ or docroot/)"
    exit 1
  fi
}

get_project_name() {
  grep "^name:" .ddev/config.yaml | awk '{print $2}' | tr -d '"' | tr -d "'"
}

detect_project_type() {
  local web_root
  web_root=$(detect_web_root)
  local sites_dir="${web_root}/sites"

  # Count site directories (exclude default, all, simpletest)
  local site_count=0
  if [[ -d "$sites_dir" ]]; then
    site_count=$(find "$sites_dir" -maxdepth 1 -type d \
      ! -name "sites" ! -name "default" ! -name "all" ! -name "simpletest" \
      -name "*.*" 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Check for additional_hostnames in config.yaml
  local has_hostnames=0
  if grep -q "additional_hostnames:" .ddev/config.yaml 2>/dev/null; then
    has_hostnames=1
  fi

  # Check for multiple databases in hooks
  local has_multi_db=0
  if grep -q "CREATE DATABASE" .ddev/config.yaml 2>/dev/null; then
    has_multi_db=1
  fi

  if [[ $site_count -gt 0 ]] || [[ $has_hostnames -eq 1 && $has_multi_db -eq 1 ]]; then
    echo "multisite"
  else
    echo "singlesite"
  fi
}

#------------------------------------------------------------------------------
# Multisite configuration extraction
#------------------------------------------------------------------------------
# Global arrays to store extracted multisite config
MULTISITE_SITES=()
MULTISITE_DBS=()
MULTISITE_HOSTNAMES=()
MULTISITE_SITE_TO_HOSTNAME=()
MULTISITE_SITE_TO_DB=()

extract_multisite_config() {
  local web_root="$1"
  local project_name="$2"

  log_info "Extracting multisite configuration..."

  # 1. Find site directories (e.g., pl.droptica.com, de.example.com)
  MULTISITE_SITES=("default")
  if [[ -d "${web_root}/sites" ]]; then
    while IFS= read -r site_dir; do
      if [[ -n "$site_dir" ]]; then
        local site_name=$(basename "$site_dir")
        MULTISITE_SITES+=("$site_name")
      fi
    done < <(find "${web_root}/sites" -maxdepth 1 -type d \
      ! -name "sites" ! -name "default" ! -name "all" ! -name "simpletest" \
      -name "*.*" 2>/dev/null | sort)
  fi

  # 2. Extract additional_hostnames from .ddev/config.yaml
  MULTISITE_HOSTNAMES=()
  if grep -q "additional_hostnames:" .ddev/config.yaml 2>/dev/null; then
    while IFS= read -r hostname; do
      hostname=$(echo "$hostname" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr -d '"' | tr -d "'")
      if [[ -n "$hostname" && "$hostname" != "additional_hostnames:" ]]; then
        MULTISITE_HOSTNAMES+=("$hostname")
      fi
    done < <(grep -A 50 "additional_hostnames:" .ddev/config.yaml | grep "^\s*-" | head -20)
  fi

  # 3. Extract database names from hooks (CREATE DATABASE IF NOT EXISTS xxx)
  MULTISITE_DBS=("db")
  if grep -q "CREATE DATABASE" .ddev/config.yaml 2>/dev/null; then
    while IFS= read -r db_name; do
      if [[ -n "$db_name" && "$db_name" != "db" ]]; then
        MULTISITE_DBS+=("$db_name")
      fi
    done < <(grep -oP "CREATE DATABASE IF NOT EXISTS \K[a-zA-Z0-9_]+" .ddev/config.yaml 2>/dev/null | sort -u)
  fi

  # 4. Try to map sites to hostnames and databases
  # This uses heuristics based on common naming patterns
  MULTISITE_SITE_TO_HOSTNAME=()
  MULTISITE_SITE_TO_DB=()

  for site in "${MULTISITE_SITES[@]}"; do
    if [[ "$site" == "default" ]]; then
      MULTISITE_SITE_TO_HOSTNAME+=("default:${project_name}")
      MULTISITE_SITE_TO_DB+=("default:db")
    else
      # Extract prefix from site directory (e.g., "pl" from "pl.droptica.com")
      local prefix=$(echo "$site" | cut -d'.' -f1)

      # Find matching hostname
      local matched_hostname=""
      for hostname in "${MULTISITE_HOSTNAMES[@]}"; do
        if [[ "$hostname" == "${prefix}."* || "$hostname" == "${prefix}" ]]; then
          matched_hostname="$hostname"
          break
        fi
      done
      if [[ -z "$matched_hostname" ]]; then
        matched_hostname="${prefix}.${project_name}"
      fi
      MULTISITE_SITE_TO_HOSTNAME+=("${site}:${matched_hostname}")

      # Find matching database
      local matched_db=""
      for db in "${MULTISITE_DBS[@]}"; do
        if [[ "$db" == "$prefix" || "$db" == "${prefix}_db" ]]; then
          matched_db="$db"
          break
        fi
      done
      if [[ -z "$matched_db" ]]; then
        matched_db="$prefix"
        # Add to DBS if not exists
        local db_exists=false
        for existing_db in "${MULTISITE_DBS[@]}"; do
          if [[ "$existing_db" == "$matched_db" ]]; then
            db_exists=true
            break
          fi
        done
        if [[ "$db_exists" == "false" ]]; then
          MULTISITE_DBS+=("$matched_db")
        fi
      fi
      MULTISITE_SITE_TO_DB+=("${site}:${matched_db}")
    fi
  done

  # Log detected configuration
  log_info "Detected sites: ${MULTISITE_SITES[*]}"
  log_info "Detected databases: ${MULTISITE_DBS[*]}"
  log_info "Detected hostnames: ${MULTISITE_HOSTNAMES[*]}"
}

#------------------------------------------------------------------------------
# Repository cloning
#------------------------------------------------------------------------------
clone_repo() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    return 0  # Already cloned
  fi

  TEMP_DIR=$(mktemp -d)
  log_info "Cloning repository to temporary directory..."

  # Try SSH first (for private repo access), then HTTPS
  if git clone --depth 1 --quiet "$REPO_SSH_URL" "$TEMP_DIR" 2>/dev/null; then
    log_success "Repository cloned via SSH"
  elif git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    log_success "Repository cloned via HTTPS"
  else
    log_error "Failed to clone repository"
    log_error "Make sure you have access to: $REPO_URL"
    log_error "For private repos, ensure SSH keys are configured"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
}

cleanup_temp() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
    log_info "Cleaned up temporary files"
  fi
}

# Ensure cleanup on exit
trap cleanup_temp EXIT

copy_template() {
  local src="$1"
  local dest="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would copy: $src → $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ ! -f "${TEMP_DIR}/${src}" ]]; then
    log_error "Template file not found: $src"
    exit 1
  fi

  cp "${TEMP_DIR}/${src}" "$dest"
}

install_singlesite() {
  local project_name
  project_name=$(get_project_name)

  log_info "Installing singlesite configuration..."

  # Clone repository to temp directory
  clone_repo

  # Create directories
  mkdir -p .cursor/lib
  mkdir -p .ddev/commands/host

  # Copy common templates
  copy_template "templates/common/.cursor/worktrees.json" ".cursor/worktrees.json"
  copy_template "templates/common/.cursor/cleanup-worktree.sh" ".cursor/cleanup-worktree.sh"
  copy_template "templates/common/.cursor/lib/logging.sh" ".cursor/lib/logging.sh"

  # Copy singlesite-specific templates
  copy_template "templates/singlesite/.cursor/setup-worktree.sh" ".cursor/setup-worktree.sh"
  copy_template "templates/singlesite/.cursor/README.md" ".cursor/README.md"
  copy_template "templates/singlesite/.ddev/commands/host/export-snapshot" ".ddev/commands/host/export-snapshot"
  copy_template "templates/singlesite/.ddev/commands/host/worktree-status" ".ddev/commands/host/worktree-status"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would replace __PROJECT_NAME__ with ${project_name}"
    return
  fi

  # Replace placeholders
  log_info "Configuring templates for project: ${project_name}"

  # macOS compatible sed
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .cursor/setup-worktree.sh
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .cursor/cleanup-worktree.sh
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .cursor/README.md
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .ddev/commands/host/worktree-status
  else
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .cursor/setup-worktree.sh
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .cursor/cleanup-worktree.sh
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .cursor/README.md
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .ddev/commands/host/worktree-status
  fi

  # Set permissions
  chmod +x .cursor/*.sh
  chmod +x .cursor/lib/*.sh 2>/dev/null || true
  chmod +x .ddev/commands/host/*

  log_success "Singlesite configuration installed"
}

install_multisite() {
  local project_name
  project_name=$(get_project_name)
  local web_root
  web_root=$(detect_web_root)

  log_info "Installing multisite configuration..."

  # Extract multisite configuration from existing project
  extract_multisite_config "$web_root" "$project_name"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would generate multisite configuration"
    log_info "[DRY-RUN] Sites: ${MULTISITE_SITES[*]}"
    log_info "[DRY-RUN] DBs: ${MULTISITE_DBS[*]}"
    return
  fi

  # Clone repository to temp directory
  clone_repo

  # Create directories
  mkdir -p .cursor/lib
  mkdir -p .ddev/commands/host

  # Copy common templates
  copy_template "templates/common/.cursor/worktrees.json" ".cursor/worktrees.json"
  copy_template "templates/common/.cursor/cleanup-worktree.sh" ".cursor/cleanup-worktree.sh"
  copy_template "templates/common/.cursor/lib/logging.sh" ".cursor/lib/logging.sh"

  # Copy multisite-specific templates
  copy_template "templates/multisite/.cursor/README.md" ".cursor/README.md"
  copy_template "templates/multisite/.ddev/commands/host/worktree-status" ".ddev/commands/host/worktree-status"

  # Generate setup-worktree.sh dynamically
  generate_multisite_setup_worktree "$project_name" "$web_root"

  # Generate prerequisites.sh dynamically
  generate_multisite_prerequisites "$project_name"

  # Generate export-multisite-snapshots dynamically
  generate_multisite_export_snapshots

  # Patch sites.php for worktree support
  patch_sites_php "$project_name" "$web_root"

  # Replace __PROJECT_NAME__ in downloaded templates
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .cursor/cleanup-worktree.sh
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .cursor/README.md
    sed -i '' "s/__PROJECT_NAME__/${project_name}/g" .ddev/commands/host/worktree-status
  else
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .cursor/cleanup-worktree.sh
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .cursor/README.md
    sed -i "s/__PROJECT_NAME__/${project_name}/g" .ddev/commands/host/worktree-status
  fi

  # Set permissions
  chmod +x .cursor/*.sh
  chmod +x .cursor/lib/*.sh
  chmod +x .ddev/commands/host/*

  log_success "Multisite configuration installed (auto-configured)"
}

#------------------------------------------------------------------------------
# Generate setup-worktree.sh for multisite
#------------------------------------------------------------------------------
generate_multisite_setup_worktree() {
  local project_name="$1"
  local web_root="$2"

  log_info "Generating setup-worktree.sh..."

  # Build SITES array
  local sites_array="SITES=(\n"
  for site in "${MULTISITE_SITES[@]}"; do
    sites_array+="  \"${site}\"\n"
  done
  sites_array+=")"

  # Build DB_NAMES array
  local db_names_array="DB_NAMES=(\n"
  for db in "${MULTISITE_DBS[@]}"; do
    db_names_array+="  \"${db}\"\n"
  done
  db_names_array+=")"

  # Build FILES_DIRS array
  local files_dirs_array="FILES_DIRS=(\n"
  files_dirs_array+="  \"\${WEB_ROOT}/sites/default/files\"\n"
  for site in "${MULTISITE_SITES[@]}"; do
    if [[ "$site" != "default" ]]; then
      files_dirs_array+="  \"\${WEB_ROOT}/sites/${site}/files\"\n"
    fi
  done
  files_dirs_array+=")"

  # Build ADDITIONAL_HOSTNAMES for config.local.yaml
  local additional_hostnames=""
  for site in "${MULTISITE_SITES[@]}"; do
    if [[ "$site" != "default" ]]; then
      local prefix=$(echo "$site" | cut -d'.' -f1)
      additional_hostnames+="  - ${prefix}.\${PROJECT_NAME}\n"
    fi
  done

  # Build DB imports
  local db_imports="# Import main database\n"
  db_imports+="import_db \"db\" \"\${ROOT_WORKTREE_PATH}/\${SNAPSHOTS_DIR}/main.sql.gz\" \"Main DB\"\n"
  for mapping in "${MULTISITE_SITE_TO_DB[@]}"; do
    local site="${mapping%%:*}"
    local db="${mapping##*:}"
    if [[ "$site" != "default" && "$db" != "db" ]]; then
      local prefix=$(echo "$site" | cut -d'.' -f1)
      db_imports+="\nimport_db \"${db}\" \"\${ROOT_WORKTREE_PATH}/\${SNAPSHOTS_DIR}/${db}.sql.gz\" \"${prefix^} DB\""
    fi
  done

  # Build required snapshots for prerequisites
  local required_snapshots="\"main.sql.gz\""
  for db in "${MULTISITE_DBS[@]}"; do
    if [[ "$db" != "db" ]]; then
      required_snapshots+="\n    \"${db}.sql.gz\""
    fi
  done

  cat > .cursor/setup-worktree.sh << SETUP_EOF
#!/bin/bash
#
# Cursor Worktree Setup Script for Drupal/DDEV (Multisite)
# Auto-generated by cursor-worktree-drupal installer
#
# Project: ${project_name}
# Sites: ${MULTISITE_SITES[*]}
# Databases: ${MULTISITE_DBS[*]}
#

set -e

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\${SCRIPT_DIR}/lib/logging.sh"
source "\${SCRIPT_DIR}/lib/prerequisites.sh"

WORKTREE_ID="\${CURSOR_WORKTREE_ID:-\${1:-}}"

if [[ -z "\$WORKTREE_ID" ]]; then
  log_error "WORKTREE_ID is required"
  exit 1
fi

# Auto-detect ROOT_WORKTREE_PATH if not set
if [[ -z "\$ROOT_WORKTREE_PATH" ]]; then
  # In a git worktree, .git is a file pointing to the main repo
  if [[ -f ".git" ]]; then
    # Get the main worktree path (first line from git worktree list)
    ROOT_WORKTREE_PATH=\$(git worktree list --porcelain | grep "^worktree " | head -1 | cut -d' ' -f2-)
  fi
fi

if [[ -z "\$ROOT_WORKTREE_PATH" ]]; then
  log_error "Could not detect ROOT_WORKTREE_PATH - are you in a git worktree?"
  exit 1
fi

PROJECT_NAME="${project_name}-\${WORKTREE_ID}"
SNAPSHOTS_DIR=".ddev/db-dumps"
WEB_ROOT="${web_root}"

# Multisite configuration (auto-detected)
$(echo -e "$sites_array")

$(echo -e "$db_names_array")

$(echo -e "$files_dirs_array")

#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
import_db() {
  local db_name="\$1"
  local snapshot_file="\$2"
  local description="\$3"

  if [[ ! -f "\$snapshot_file" ]]; then
    log_warn "Snapshot not found: \${snapshot_file}"
    return 1
  fi

  log_info "Importing \${description}..."

  if [[ "\$db_name" == "db" ]]; then
    ddev import-db --file="\$snapshot_file"
  else
    ddev import-db --database="\$db_name" --file="\$snapshot_file"
  fi

  log_success "Imported \${description}"
}

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------
log_step "Validating environment"

log_info "Worktree ID: \${WORKTREE_ID}"
log_info "Project name: \${PROJECT_NAME}"
log_info "Root worktree: \${ROOT_WORKTREE_PATH}"

check_prerequisites "\$ROOT_WORKTREE_PATH"

#------------------------------------------------------------------------------
# Copy DDEV configuration from main project
#------------------------------------------------------------------------------
log_step "Copying DDEV configuration"

if [[ ! -d ".ddev" ]]; then
  if [[ -d "\${ROOT_WORKTREE_PATH}/.ddev" ]]; then
    # Copy .ddev directory from main project (excluding runtime files)
    mkdir -p .ddev
    cp -r "\${ROOT_WORKTREE_PATH}/.ddev/config.yaml" .ddev/ 2>/dev/null || true
    cp -r "\${ROOT_WORKTREE_PATH}/.ddev/providers" .ddev/ 2>/dev/null || true
    cp -r "\${ROOT_WORKTREE_PATH}/.ddev/commands" .ddev/ 2>/dev/null || true
    cp -r "\${ROOT_WORKTREE_PATH}/.ddev/docker-compose.*.yaml" .ddev/ 2>/dev/null || true
    cp -r "\${ROOT_WORKTREE_PATH}/.ddev/.gitignore" .ddev/ 2>/dev/null || true
    log_success "Copied .ddev configuration from main project"
  else
    log_error "Main project .ddev directory not found: \${ROOT_WORKTREE_PATH}/.ddev"
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
# Auto-generated for Cursor worktree: \${WORKTREE_ID}
# DO NOT COMMIT THIS FILE

name: \${PROJECT_NAME}

override_config: true

additional_hostnames:
$(echo -e "$additional_hostnames")
web_environment:
  - PLATFORM_ENVIRONMENT=staging
  - CURSOR_WORKTREE_ID=\${WORKTREE_ID}
EOF

log_success "Generated .ddev/config.local.yaml"

#------------------------------------------------------------------------------
# Create Git branch
#------------------------------------------------------------------------------
log_step "Setting up Git branch"

BRANCH_NAME="worktree/\${WORKTREE_ID}"

if git show-ref --verify --quiet "refs/heads/\${BRANCH_NAME}"; then
  log_info "Branch \${BRANCH_NAME} already exists, checking out"
  git checkout "\${BRANCH_NAME}"
else
  log_info "Creating new branch: \${BRANCH_NAME}"
  git checkout -b "\${BRANCH_NAME}"
fi

log_success "Git branch ready: \${BRANCH_NAME}"

#------------------------------------------------------------------------------
# Setup files directory symlinks
#------------------------------------------------------------------------------
log_step "Setting up files directories"

for files_dir in "\${FILES_DIRS[@]}"; do
  MAIN_FILES_DIR="\${ROOT_WORKTREE_PATH}/\${files_dir}"

  if [[ -d "\$MAIN_FILES_DIR" ]]; then
    rm -rf "\$files_dir"
    mkdir -p "\$(dirname "\$files_dir")"
    ln -sf "\$MAIN_FILES_DIR" "\$files_dir"
    log_success "Symlinked: \${files_dir}"
  else
    log_warn "Main files directory not found: \${MAIN_FILES_DIR}"
    mkdir -p "\$files_dir"
    log_info "Created empty directory: \${files_dir}"
  fi
done

#------------------------------------------------------------------------------
# Start DDEV
#------------------------------------------------------------------------------
log_step "Starting DDEV"

ddev start

log_success "DDEV started"

#------------------------------------------------------------------------------
# Import databases
#------------------------------------------------------------------------------
log_step "Importing databases"

$(echo -e "$db_imports")

log_success "All databases imported"

#------------------------------------------------------------------------------
# Clear cache
#------------------------------------------------------------------------------
log_step "Clearing Drupal cache"

ddev drush cr || log_warn "Cache clear failed (may be normal for fresh installs)"

for site in "\${SITES[@]}"; do
  if [[ "\$site" != "default" ]]; then
    log_info "Clearing cache for site: \${site}"
    ddev drush --uri="\${site}" cr 2>/dev/null || log_warn "Cache clear failed for \${site}"
  fi
done

log_success "Cache cleared"

#------------------------------------------------------------------------------
# Health check & Summary
#------------------------------------------------------------------------------
log_step "Running health check"

SITE_URL="https://\${PROJECT_NAME}.ddev.site"

if curl -sI "\$SITE_URL" | head -1 | grep -q "200\|301\|302\|303"; then
  log_success "Main site is responding: \${SITE_URL}"
else
  log_warn "Main site may not be fully ready yet"
fi

LOGIN_URL=\$(ddev drush uli --uri="\$SITE_URL" 2>/dev/null || echo "")

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  ✅ Multisite Worktree Setup Complete!                             ║"
echo "╠════════════════════════════════════════════════════════════════════╣"
echo "║  Worktree ID: \${WORKTREE_ID}"
echo "║  Project: \${PROJECT_NAME}"
echo "║  Branch: \${BRANCH_NAME}"
echo "╠════════════════════════════════════════════════════════════════════╣"
echo "║  Sites:"
for site in "\${SITES[@]}"; do
  if [[ "\$site" == "default" ]]; then
    echo "║    - Main: \${SITE_URL}"
  else
    prefix=\$(echo "\$site" | cut -d'.' -f1)
    echo "║    - \${site}: https://\${prefix}.\${PROJECT_NAME}.ddev.site"
  fi
done
echo "╠════════════════════════════════════════════════════════════════════╣"
if [[ -n "\$LOGIN_URL" ]]; then
  echo "║  Admin login: \${LOGIN_URL}"
fi
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
SETUP_EOF

  log_success "Generated .cursor/setup-worktree.sh"
}

#------------------------------------------------------------------------------
# Generate prerequisites.sh for multisite
#------------------------------------------------------------------------------
generate_multisite_prerequisites() {
  local project_name="$1"

  log_info "Generating prerequisites.sh..."

  # Build required snapshots array
  local required_snapshots_code="local required_snapshots=(\n    \"main.sql.gz\""
  for db in "${MULTISITE_DBS[@]}"; do
    if [[ "$db" != "db" ]]; then
      required_snapshots_code+="\n    \"${db}.sql.gz\""
    fi
  done
  required_snapshots_code+="\n  )"

  cat > .cursor/lib/prerequisites.sh << 'PREREQ_HEADER'
#!/bin/bash
#
# Prerequisites check for Cursor worktree setup (Multisite)
# Auto-generated by cursor-worktree-drupal installer
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"

check_prerequisites() {
  local root_path="$1"
  local snapshots_dir="${root_path}/.ddev/db-dumps"

  log_step "Checking prerequisites"

  if [[ ! -d "$snapshots_dir" ]]; then
    log_error "Snapshots directory not found: ${snapshots_dir}"
    log_error "Run 'ddev export-multisite-snapshots' in the main project first"
    return 1
  fi

PREREQ_HEADER

  # Add required snapshots array
  echo "  $(echo -e "$required_snapshots_code")" >> .cursor/lib/prerequisites.sh

  cat >> .cursor/lib/prerequisites.sh << 'PREREQ_FOOTER'

  local missing=0
  for snapshot in "${required_snapshots[@]}"; do
    local snapshot_path="${snapshots_dir}/${snapshot}"
    if [[ ! -f "$snapshot_path" ]]; then
      log_error "Missing snapshot: ${snapshot}"
      missing=$((missing + 1))
    else
      log_success "Found snapshot: ${snapshot} ($(du -h "$snapshot_path" | cut -f1))"
    fi
  done

  if [[ $missing -gt 0 ]]; then
    log_error "${missing} required snapshot(s) missing"
    log_error "Run 'ddev export-multisite-snapshots' in the main project"
    return 1
  fi

  log_success "All prerequisites met"
  return 0
}

export -f check_prerequisites
PREREQ_FOOTER

  log_success "Generated .cursor/lib/prerequisites.sh"
}

#------------------------------------------------------------------------------
# Generate export-multisite-snapshots command
#------------------------------------------------------------------------------
generate_multisite_export_snapshots() {
  log_info "Generating export-multisite-snapshots..."

  cat > .ddev/commands/host/export-multisite-snapshots << 'EXPORT_HEADER'
#!/bin/bash

## Description: Export all multisite database snapshots for Cursor worktrees
## Usage: export-multisite-snapshots
## Example: ddev export-multisite-snapshots
## Auto-generated by cursor-worktree-drupal installer

set -e

SNAPSHOTS_DIR=".ddev/db-dumps"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Creating multisite database snapshots for Cursor worktrees..."

mkdir -p "$SNAPSHOTS_DIR"

echo -e "${BLUE}[INFO]${NC} Exporting main database..."
ddev export-db --gzip --file="${SNAPSHOTS_DIR}/main.sql.gz"
echo -e "${GREEN}✓${NC} Main DB exported"
EXPORT_HEADER

  # Add exports for additional databases
  for db in "${MULTISITE_DBS[@]}"; do
    if [[ "$db" != "db" ]]; then
      cat >> .ddev/commands/host/export-multisite-snapshots << EXPORT_DB

echo -e "\${BLUE}[INFO]\${NC} Exporting ${db} database..."
ddev export-db --database=${db} --gzip --file="\${SNAPSHOTS_DIR}/${db}.sql.gz"
echo -e "\${GREEN}✓\${NC} ${db^} DB exported"
EXPORT_DB
    fi
  done

  cat >> .ddev/commands/host/export-multisite-snapshots << 'EXPORT_FOOTER'

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  All snapshots created successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Files created:"
ls -lh "$SNAPSHOTS_DIR"/*.sql.gz 2>/dev/null || echo "  (no snapshots found)"
echo ""
echo "Worktrees will use these snapshots for their databases."
EXPORT_FOOTER

  log_success "Generated .ddev/commands/host/export-multisite-snapshots"
}

#------------------------------------------------------------------------------
# Patch sites.php for worktree support
#------------------------------------------------------------------------------
patch_sites_php() {
  local project_name="$1"
  local web_root="$2"
  local sites_php="${web_root}/sites/sites.php"

  log_info "Configuring sites.php for worktree support..."

  # Check if already patched
  if [[ -f "$sites_php" ]] && grep -q "CURSOR WORKTREE SUPPORT" "$sites_php" 2>/dev/null; then
    log_info "sites.php already has worktree support"
    return
  fi

  # Build multisite config array for PHP
  local php_config="\$multisite_config = [\n"
  php_config+="  'default' => [\n"
  php_config+="    'main' => '${project_name}.ddev.site',\n"
  php_config+="    'worktree_pattern' => '/^${project_name}-([a-zA-Z0-9]+)\\\\.ddev\\\\.site\$/',\n"
  php_config+="  ],\n"

  for mapping in "${MULTISITE_SITE_TO_HOSTNAME[@]}"; do
    local site="${mapping%%:*}"
    local hostname="${mapping##*:}"
    if [[ "$site" != "default" ]]; then
      local prefix=$(echo "$site" | cut -d'.' -f1)
      php_config+="  '${site}' => [\n"
      php_config+="    'main' => '${prefix}.${project_name}.ddev.site',\n"
      php_config+="    'worktree_pattern' => '/^${prefix}\\\\.${project_name}-([a-zA-Z0-9]+)\\\\.ddev\\\\.site\$/',\n"
      php_config+="  ],\n"
    fi
  done
  php_config+="];"

  # Create worktree support code
  local worktree_code
  read -r -d '' worktree_code << SITESPHP_EOF || true
<?php
/**
 * CURSOR WORKTREE SUPPORT
 * Auto-generated by cursor-worktree-drupal installer
 *
 * Handles dynamic domain mapping for worktree environments.
 * Project: ${project_name}
 */

\$host = \$_SERVER['HTTP_HOST'] ?? '';

$(echo -e "$php_config")

// Map hostnames to site directories
foreach (\$multisite_config as \$site_dir => \$config) {
  // Main DDEV hostname
  if (!empty(\$config['main'])) {
    \$sites[\$config['main']] = \$site_dir;
  }

  // Worktree pattern matching
  if (!empty(\$config['worktree_pattern']) && preg_match(\$config['worktree_pattern'], \$host)) {
    \$sites[\$host] = \$site_dir;
  }
}

SITESPHP_EOF

  if [[ -f "$sites_php" ]]; then
    # Backup existing file
    cp "$sites_php" "${sites_php}.backup"

    # Check if file starts with <?php
    if head -1 "$sites_php" | grep -q "<?php"; then
      # Insert worktree code after opening <?php
      local existing_content
      existing_content=$(tail -n +2 "$sites_php")

      # Remove the opening <?php from worktree_code since file already has it
      local worktree_without_php
      worktree_without_php=$(echo "$worktree_code" | tail -n +2)

      echo "<?php" > "$sites_php"
      echo "$worktree_without_php" >> "$sites_php"
      echo "" >> "$sites_php"
      echo "// Original sites.php content below" >> "$sites_php"
      echo "$existing_content" >> "$sites_php"
    else
      # Prepend worktree code
      local existing_content
      existing_content=$(cat "$sites_php")
      echo "$worktree_code" > "$sites_php"
      echo "" >> "$sites_php"
      echo "$existing_content" >> "$sites_php"
    fi

    log_success "Patched existing sites.php (backup: ${sites_php}.backup)"
  else
    # Create new sites.php
    echo "$worktree_code" > "$sites_php"
    log_success "Created new sites.php with worktree support"
  fi
}

#------------------------------------------------------------------------------
# Snapshot creation
#------------------------------------------------------------------------------
create_snapshots() {
  local type="$1"

  log_info "Creating database snapshots..."

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would create database snapshots"
    return
  fi

  # Check if DDEV is running
  if ! ddev describe &>/dev/null; then
    log_info "Starting DDEV..."
    ddev start
  fi

  # Create snapshots directory
  mkdir -p .ddev/db-dumps

  if [[ "$type" == "multisite" ]]; then
    # Export all detected databases
    log_info "Exporting main database..."
    ddev export-db --gzip --file=".ddev/db-dumps/main.sql.gz"
    log_success "Main database exported"

    # Export additional databases
    for db in "${MULTISITE_DBS[@]}"; do
      if [[ "$db" != "db" ]]; then
        log_info "Exporting ${db} database..."
        if ddev export-db --database="$db" --gzip --file=".ddev/db-dumps/${db}.sql.gz" 2>/dev/null; then
          log_success "${db} database exported"
        else
          log_warn "Could not export ${db} database (may not exist yet)"
        fi
      fi
    done

    log_success "All database snapshots created in .ddev/db-dumps/"
  else
    local project_name
    project_name=$(get_project_name)
    ddev export-db --gzip --file=".ddev/db-dumps/${project_name}.sql.gz"
    log_success "Database exported to .ddev/db-dumps/${project_name}.sql.gz"
  fi
}

#------------------------------------------------------------------------------
# Update .gitignore
#------------------------------------------------------------------------------
update_gitignore() {
  local entries=(
    ".ddev/config.local.yaml"
    ".ddev/db-dumps/"
  )

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would update .gitignore"
    return
  fi

  for entry in "${entries[@]}"; do
    if ! grep -qF "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
      log_info "Added to .gitignore: $entry"
    fi
  done
}

#------------------------------------------------------------------------------
# Update AGENTS.md
#------------------------------------------------------------------------------
update_agents_md() {
  local marker="## Parallel Agents Workflow"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would update AGENTS.md"
    return
  fi

  # Check if section already exists
  if [[ -f "AGENTS.md" ]] && grep -qF "$marker" AGENTS.md 2>/dev/null; then
    log_info "AGENTS.md already contains Parallel Agents section"
    return
  fi

  # Content to add
  local agents_content
  read -r -d '' agents_content << 'AGENTS_EOF'

## Parallel Agents Workflow

### Working in Worktrees

When working as a **Parallel Agent** in a worktree environment:

1. **Isolated Environment**: You have your own:
   - Git branch (`worktree/{ID}`)
   - DDEV containers
   - Database copy
   - Files are symlinked from main project

2. **After completing work**:
   ```bash
   git add -A
   git commit -m "[type]: description of changes"
   git push origin HEAD
   ```

3. **Create Pull Request** for code review:
   ```bash
   gh pr create --title "Description" --body "Details"
   ```

### ⚠️ IMPORTANT: Do NOT use "Apply"

**DO NOT use Cursor's "Apply" button** in worktrees. All changes must go through Code Review.

**Reasons:**
- Changes need human review before merging
- Multiple agents may work on overlapping code
- Config/DB changes require careful coordination

**Exceptions** (can use Apply locally):
- Minor CSS/Twig fixes without logic impact
- Documentation updates (README, comments)
- Typo fixes

### Resource Awareness

Each worktree spawns Docker containers (~500MB RAM each).

**Check resource usage:**
```bash
ddev worktree-status
```

**Stop specific worktree:**
```bash
ddev stop [project-name]-[worktree-id]
```

**Cleanup all worktrees:**
```bash
.cursor/cleanup-worktree.sh --all
```

### Recommended Cursor Settings

Add to `.cursor/settings.json`:
```json
{
  "cursor.worktreeMaxCount": 3,
  "cursor.worktreeCleanupIntervalHours": 2
}
```

### Database Changes

If your task requires database changes (config, content types, fields):

1. Make changes via Drupal admin or drush
2. Export configuration: `ddev drush cex -y`
3. Commit the exported config files
4. Document in PR what manual steps are needed

### Worktree-Specific Notes

- **No LSP**: Language Server Protocol is not available in worktrees
- **Shared files**: `/sites/default/files` is symlinked - be careful with file operations
- **Separate cache**: Each worktree has its own cache - run `ddev drush cr` after changes

---

*Parallel Agents section added by [cursor-worktree-drupal](https://github.com/droptica/cursor-worktree-drupal)*
AGENTS_EOF

  if [[ -f "AGENTS.md" ]]; then
    # Append to existing file
    echo "$agents_content" >> AGENTS.md
    log_success "Added Parallel Agents section to existing AGENTS.md"
  else
    # Create new file with header
    cat > AGENTS.md << 'HEADER_EOF'
# Project Guidelines for AI Agents

This file contains instructions and guidelines for AI agents working on this project.
HEADER_EOF
    echo "$agents_content" >> AGENTS.md
    log_success "Created AGENTS.md with Parallel Agents section"
  fi
}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
show_summary() {
  local type="$1"
  local project_name
  project_name=$(get_project_name)

  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${GREEN}✅ Cursor Worktree Support Installed!${NC}                             ${CYAN}║${NC}"
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Project: ${project_name}"
  echo -e "${CYAN}║${NC}  Type: ${type}"
  if [[ "$type" == "multisite" ]]; then
  echo -e "${CYAN}║${NC}  Sites: ${MULTISITE_SITES[*]}"
  echo -e "${CYAN}║${NC}  Databases: ${MULTISITE_DBS[*]}"
  fi
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Files created/updated:                                            ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    .cursor/worktrees.json                                          ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    .cursor/setup-worktree.sh                                       ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    .cursor/cleanup-worktree.sh                                     ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    .cursor/lib/logging.sh                                          ${CYAN}║${NC}"
  if [[ "$type" == "multisite" ]]; then
  echo -e "${CYAN}║${NC}    .cursor/lib/prerequisites.sh                                    ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    .ddev/commands/host/export-multisite-snapshots                  ${CYAN}║${NC}"
  local web_root
  web_root=$(detect_web_root)
  echo -e "${CYAN}║${NC}    ${web_root}/sites/sites.php (patched)                           ${CYAN}║${NC}"
  fi
  echo -e "${CYAN}║${NC}    AGENTS.md (AI agent instructions)                               ${CYAN}║${NC}"
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Next steps:                                                       ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    1. Commit the new files to your repository                      ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    2. Open project in Cursor                                       ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    3. Use 'Run in worktree' for parallel agent tasks               ${CYAN}║${NC}"
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Recommended Cursor settings (in .cursor/settings.json):           ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    {                                                               ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}      \"cursor.worktreeMaxCount\": 3,                                 ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}      \"cursor.worktreeCleanupIntervalHours\": 2                      ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}    }                                                               ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Documentation: https://github.com/droptica/cursor-worktree-drupal"
  echo ""
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
main() {
  show_header

  echo -e "${CYAN}${BOLD}Installer v${VERSION}${NC}"
  echo ""

  check_requirements

  local web_root
  web_root=$(detect_web_root)
  log_success "Web root: ${web_root}/"

  local project_name
  project_name=$(get_project_name)
  log_success "Project name: ${project_name}"

  local project_type
  if [[ -n "$FORCE_TYPE" ]]; then
    project_type="$FORCE_TYPE"
    log_info "Project type forced to: ${project_type}"
  else
    project_type=$(detect_project_type)
    log_success "Detected project type: ${project_type}"
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY-RUN mode - no files will be modified"
  fi

  echo ""

  if [[ "$project_type" == "multisite" ]]; then
    install_multisite
  else
    install_singlesite
  fi

  update_gitignore
  update_agents_md

  create_snapshots "$project_type"

  show_summary "$project_type"
}

main "$@"
