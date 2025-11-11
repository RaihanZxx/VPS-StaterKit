#!/usr/bin/env bash

# ============================================================================
# VPS Starter Kit - Common Utilities Library
# ============================================================================
# Shared functions, color definitions, and utilities for all scripts
# Source this file at the beginning of any script: source "$(dirname "$0")/../lib/common.sh"
# ============================================================================

# ============================================================================
# Colors (auto-detect TTY)
# ============================================================================
if [ -t 1 ]; then
  C_RESET="\033[0m"
  C_BOLD="\033[1m"
  C_DIM="\033[2m"
  C_CYAN="\033[36m"
  C_GREEN="\033[32m"
  C_YELLOW="\033[33m"
  C_WHITE="\033[97m"
  C_MAGENTA="\033[35m"
  C_BLUE="\033[34m"
  C_RED="\033[31m"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_CYAN=""; C_GREEN=""
  C_YELLOW=""; C_WHITE=""; C_MAGENTA=""; C_BLUE=""; C_RED=""
fi

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
  echo -e "${C_CYAN}${C_BOLD}[INFO]${C_RESET} $*"
}

log_success() {
  echo -e "${C_GREEN}${C_BOLD}[OK]${C_RESET} $*"
}

log_warn() {
  echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $*" >&2
}

log_error() {
  echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $*" >&2
}

log_debug() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo -e "${C_DIM}[DEBUG] $*${C_RESET}" >&2
  fi
}

# ============================================================================
# Command & Requirement Checks
# ============================================================================

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  local cmd="$1"
  local msg="${2:-$cmd is required but not found}"
  if ! need_cmd "$cmd"; then
    log_error "$msg"
    exit 1
  fi
}

require_sudo() {
  if ! need_cmd sudo; then
    log_error "sudo is required"
    exit 1
  fi
  if ! sudo -n true 2>/dev/null; then
    log_error "This operation requires sudo access"
    exit 1
  fi
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
  fi
}

# ============================================================================
# System Information Functions
# ============================================================================

get_distro_id() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

get_os_name() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-${NAME:-Linux}}"
  else
    uname -sr
  fi
}

get_cpu_cores() {
  nproc 2>/dev/null || echo 1
}

get_ram_bytes() {
  awk '/MemTotal/ {print $2*1024}' /proc/meminfo
}

get_disk_bytes_total() {
  df -B1 --output=size / 2>/dev/null | tail -1 | tr -d ' '
}

get_disk_bytes_avail() {
  df -B1 --output=avail / 2>/dev/null | tail -1 | tr -d ' '
}

# ============================================================================
# Format Functions
# ============================================================================

numfmt_gib() {
  awk -v b="$1" 'BEGIN {printf "%.2f", b/1024/1024/1024}'
}

numfmt_mib() {
  awk -v b="$1" 'BEGIN {printf "%.2f", b/1024/1024}'
}

numfmt_kib() {
  awk -v b="$1" 'BEGIN {printf "%.2f", b/1024}'
}

# ============================================================================
# Network Functions
# ============================================================================

get_local_ip() {
  local ip=""
  if need_cmd hostname; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}') || true
  fi
  if [ -z "$ip" ] && need_cmd ip; then
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}') || true
  fi
  echo "${ip:--}"
}

get_public_ip() {
  local pip=""
  if need_cmd curl; then
    pip=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)
  elif need_cmd wget; then
    pip=$(wget -qO- --timeout=3 https://api.ipify.org 2>/dev/null || true)
  fi
  echo "${pip:--}"
}

# ============================================================================
# SSH Functions
# ============================================================================

get_ssh_port() {
  local port=""
  if need_cmd sshd; then
    port=$(sshd -T 2>/dev/null | awk '/^port / {print $2; exit}') || true
  fi
  if [ -z "$port" ]; then
    local candidate=""
    for f in /etc/ssh/sshd_config $(find /etc/ssh/sshd_config.d -type f 2>/dev/null || true); do
      [ -r "$f" ] || continue
      candidate=$(awk 'tolower($1)=="port"{p=$2} END{if(p) print p}' "$f" 2>/dev/null || true)
      [ -n "$candidate" ] && port="$candidate"
    done
  fi
  echo "${port:-22}"
}

# ============================================================================
# Package Manager Detection
# ============================================================================

detect_pkg_manager() {
  if need_cmd apt-get; then
    echo "apt"
  elif need_cmd dnf; then
    echo "dnf"
  elif need_cmd yum; then
    echo "yum"
  elif need_cmd zypper; then
    echo "zypper"
  elif need_cmd pacman; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

pkg_update() {
  local pm
  pm=$(detect_pkg_manager)
  case "$pm" in
    apt)
      sudo apt-get update -y && sudo apt-get upgrade -y || true
      ;;
    dnf)
      sudo dnf -y upgrade || true
      ;;
    yum)
      sudo yum -y update || true
      ;;
    zypper)
      sudo zypper refresh && sudo zypper update -y || true
      ;;
    pacman)
      sudo pacman -Syu --noconfirm || true
      ;;
    *)
      log_warn "Unsupported package manager. Skipping update."
      return 1
      ;;
  esac
}

pkg_install() {
  local packages=("$@")
  local pm
  pm=$(detect_pkg_manager)
  case "$pm" in
    apt)
      sudo apt-get install -y "${packages[@]}"
      ;;
    dnf)
      sudo dnf -y install "${packages[@]}"
      ;;
    yum)
      sudo yum -y install "${packages[@]}"
      ;;
    zypper)
      sudo zypper install -y "${packages[@]}"
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed "${packages[@]}"
      ;;
    *)
      log_error "Unsupported package manager. Cannot install packages."
      return 1
      ;;
  esac
}

# ============================================================================
# Service Management
# ============================================================================

enable_service() {
  local svc="$1"
  if need_cmd systemctl; then
    sudo systemctl enable --now "$svc" || \
    sudo systemctl enable "$svc" && sudo systemctl start "$svc" || \
    log_warn "Could not enable/start service $svc"
  elif need_cmd service; then
    sudo service "$svc" start || log_warn "Could not start service $svc"
  else
    log_error "Neither systemctl nor service found"
    return 1
  fi
}

start_service() {
  local svc="$1"
  if need_cmd systemctl; then
    sudo systemctl start "$svc"
  elif need_cmd service; then
    sudo service "$svc" start
  fi
}

stop_service() {
  local svc="$1"
  if need_cmd systemctl; then
    sudo systemctl stop "$svc"
  elif need_cmd service; then
    sudo service "$svc" stop
  fi
}

restart_service() {
  local svc="$1"
  if need_cmd systemctl; then
    sudo systemctl restart "$svc"
  elif need_cmd service; then
    sudo service "$svc" restart
  fi
}

service_status() {
  local svc="$1"
  if need_cmd systemctl; then
    sudo systemctl status "$svc" || true
  elif need_cmd service; then
    sudo service "$svc" status || true
  fi
}

# ============================================================================
# Validation Functions
# ============================================================================

is_valid_port() {
  local port="$1"
  if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
    return 0
  fi
  return 1
}

is_valid_ip() {
  local ip="$1"
  if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  fi
  return 1
}

# ============================================================================
# File & Backup Functions
# ============================================================================

backup_file() {
  local file="$1"
  local backup="${file}.bak.$(date +%s)"
  if [ -f "$file" ]; then
    if sudo test -w "$file" 2>/dev/null || [ -w "$file" ]; then
      sudo cp -a "$file" "$backup"
      log_info "Backup created: $backup"
    fi
  fi
}

restore_backup() {
  local file="$1"
  local backup="${file}.bak"
  if [ -f "$backup" ]; then
    sudo cp -a "$backup" "$file"
    log_success "Restored from backup: $backup"
  else
    log_error "Backup not found: $backup"
    return 1
  fi
}

# ============================================================================
# User Interaction
# ============================================================================

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local ans
  read -r -p "$prompt (y/n) [$default]: " ans || true
  ans="${ans:-$default}"
  case "${ans,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_input() {
  local prompt="$1"
  local default="${2:-}"
  local result
  read -r -p "$prompt" result || true
  echo "${result:-$default}"
}

# ============================================================================
# Export all functions for sourcing
# ============================================================================
export -f log_info log_success log_warn log_error log_debug
export -f need_cmd require_cmd require_sudo require_root
export -f get_distro_id get_os_name get_cpu_cores get_ram_bytes
export -f get_disk_bytes_total get_disk_bytes_avail
export -f numfmt_gib numfmt_mib numfmt_kib
export -f get_local_ip get_public_ip get_ssh_port
export -f detect_pkg_manager pkg_update pkg_install
export -f enable_service start_service stop_service restart_service service_status
export -f is_valid_port is_valid_ip
export -f backup_file restore_backup
export -f prompt_yes_no prompt_input
