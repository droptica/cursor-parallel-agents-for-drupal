#!/bin/bash
#
# Logging functions for Cursor worktree scripts
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
  local level="$1"
  shift
  echo -e "[$(date '+%H:%M:%S')] [${level}] $*"
}

log_info() {
  log "${BLUE}INFO${NC}" "$@"
}

log_success() {
  log "${GREEN}OK${NC}" "$@"
}

log_warn() {
  log "${YELLOW}WARN${NC}" "$@"
}

log_error() {
  log "${RED}ERROR${NC}" "$@"
}

log_step() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}▶ $*${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}
