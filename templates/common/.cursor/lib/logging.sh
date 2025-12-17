#!/bin/bash
#
# Logging functions for Cursor worktree scripts
#
# Optional variables (can be set before or after sourcing):
#   WORKTREE_ID        - worktree identifier (for separate log files)
#   ROOT_WORKTREE_PATH - main project path (for centralized logs)
#
# Note: LOG_FILE is determined lazily on first log call, allowing
# WORKTREE_ID to be set after sourcing this file.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Logging Setup ---
LOG_HOSTNAME="${LOG_HOSTNAME:-$(hostname -s 2>/dev/null || echo "localhost")}"
LOG_PID="${LOG_PID:-$$}"

# Determine log directory - prefer main project for centralized logs
if [[ -n "$ROOT_WORKTREE_PATH" ]]; then
  LOG_DIR="${ROOT_WORKTREE_PATH}/.cursor/logs"
else
  SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  LOG_DIR="${SCRIPT_DIR}/logs"
fi

# Create logs directory
mkdir -p "$LOG_DIR"

# LOG_FILE will be determined dynamically by get_log_file function
# This allows WORKTREE_ID to be set after sourcing this file
LOG_FILE=""

get_log_file() {
  # Return cached value if already determined
  if [[ -n "$LOG_FILE" ]]; then
    echo "$LOG_FILE"
    return
  fi
  
  # Determine log file based on WORKTREE_ID
  if [[ -n "$WORKTREE_ID" ]]; then
    LOG_FILE="${LOG_DIR}/worktree-${WORKTREE_ID}.log"
  else
    # Fallback: extract ID from current directory
    local current_dir_id
    current_dir_id="$(pwd)"
    current_dir_id="${current_dir_id##*/}"
    if [[ -n "$current_dir_id" ]]; then
      LOG_FILE="${LOG_DIR}/worktree-${current_dir_id}.log"
    else
      LOG_FILE="${LOG_DIR}/worktree.log"
    fi
  fi
  echo "$LOG_FILE"
}

# Core logging function - writes to file
log_to_file() {
  local level="${1:-INFO}"
  local message="$2"
  local timestamp
  local log_file
  timestamp=$(date '+%b %d %H:%M:%S')
  log_file="$(get_log_file)"
  echo "${timestamp} ${LOG_HOSTNAME} worktree[${LOG_PID}]: [${level}] ${message}" >> "$log_file"
}

# Logging functions - output to both console and file
log() {
  local level="$1"
  shift
  local message="$*"
  echo -e "[$(date '+%H:%M:%S')] [${level}] ${message}"
  local clean_level=$(echo -e "$level" | sed 's/\x1b\[[0-9;]*m//g')
  log_to_file "$clean_level" "$message"
}

log_info() { log "${BLUE}INFO${NC}" "$@"; }
log_success() { log "${GREEN}OK${NC}" "$@"; }
log_warn() { log "${YELLOW}WARN${NC}" "$@"; }
log_error() { log "${RED}ERROR${NC}" "$@"; }

log_step() {
  local message="$*"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}▶ ${message}${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  log_to_file "STEP" "$message"
}

log_resources() {
  local cpu_usage ram_usage ram_total
  if [[ "$(uname)" == "Darwin" ]]; then
    cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.1f", s}')
    ram_total=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1f", $1/1024/1024/1024}')
    ram_used=$(vm_stat 2>/dev/null | awk '/Pages active/{a=$3}/Pages wired/{w=$4}/Pages compressed/{c=$5}END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",c);printf "%.1f",(a+w+c)*4096/1024/1024/1024}')
    ram_usage="${ram_used:-0}/${ram_total:-0}GB"
  else
    cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    ram_usage=$(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}')
  fi
  log_to_file "STATS" "CPU: ${cpu_usage:-0}% | RAM: ${ram_usage:-N/A}"
}

log_error_handler() {
  local exit_code=$?
  local line_no=${1:-unknown}
  [[ $exit_code -ne 0 ]] && log_to_file "ERROR" "Script failed at line $line_no with exit code $exit_code"
}
