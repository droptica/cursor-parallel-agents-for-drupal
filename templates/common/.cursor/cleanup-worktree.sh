#!/bin/bash
#
# Cursor Worktree Cleanup Script for Drupal/DDEV
#
# This script cleans up orphaned DDEV projects from worktrees.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
PROJECT_PREFIX="__PROJECT_NAME__-"
CLEANUP_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --all) CLEANUP_ALL=true; shift ;;
    --help|-h)
      echo "Usage: cleanup-worktree.sh [--all]"
      echo ""
      echo "Options:"
      echo "  --all    Stop and remove all worktree DDEV projects"
      echo ""
      exit 0
      ;;
    *) shift ;;
  esac
done

#------------------------------------------------------------------------------
# Find worktree DDEV projects
#------------------------------------------------------------------------------
log_step "Finding worktree DDEV projects"

# Get list of running DDEV projects matching our pattern
WORKTREE_PROJECTS=$(docker ps --format '{{.Names}}' 2>/dev/null | grep "ddev-${PROJECT_PREFIX}" | sed 's/ddev-//' | sed 's/-web$//' | sort -u || echo "")

if [[ -z "$WORKTREE_PROJECTS" ]]; then
  log_info "No worktree DDEV projects found"
  exit 0
fi

log_info "Found worktree projects:"
echo "$WORKTREE_PROJECTS" | while read -r project; do
  echo "  - $project"
done

#------------------------------------------------------------------------------
# Get active worktrees
#------------------------------------------------------------------------------
ACTIVE_WORKTREES=""
if command -v git &>/dev/null && [[ -d ".git" ]]; then
  ACTIVE_WORKTREES=$(git worktree list --porcelain 2>/dev/null | grep "^worktree" | awk '{print $2}' || echo "")
fi

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------
log_step "Cleaning up orphaned projects"

echo "$WORKTREE_PROJECTS" | while read -r project; do
  if [[ -z "$project" ]]; then
    continue
  fi

  # Extract worktree ID from project name
  WORKTREE_ID="${project#${PROJECT_PREFIX}}"

  # Check if this worktree still exists
  IS_ORPHAN=true
  if [[ -n "$ACTIVE_WORKTREES" ]]; then
    echo "$ACTIVE_WORKTREES" | while read -r worktree_path; do
      if [[ "$worktree_path" == *"$WORKTREE_ID"* ]]; then
        IS_ORPHAN=false
        break
      fi
    done
  fi

  if [[ "$CLEANUP_ALL" == "true" ]] || [[ "$IS_ORPHAN" == "true" ]]; then
    log_info "Stopping: $project"

    # Try to stop the DDEV project
    if ddev stop "$project" 2>/dev/null; then
      log_success "Stopped: $project"
    else
      log_warn "Could not stop: $project (may already be stopped)"
    fi

    # Remove the project
    if ddev delete -O "$project" 2>/dev/null; then
      log_success "Removed: $project"
    else
      log_warn "Could not remove: $project"
    fi
  else
    log_info "Keeping active worktree: $project"
  fi
done

log_success "Cleanup complete"
