#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC_DIR="${SCRIPT_DIR}/src"

# Colors
if [ -t 1 ]; then
  C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m";
  C_CYAN="\033[36m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_WHITE="\033[97m"; C_MAGENTA="\033[35m"; C_BLUE="\033[34m"; C_RED="\033[31m"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_WHITE=""; C_MAGENTA=""; C_BLUE=""; C_RED=""
fi

need_cmd() { command -v "$1" >/dev/null 2>&1; }
numfmt_gib() { awk -v b="$1" 'BEGIN {printf "%.2f", b/1024/1024/1024}'; }

maybe_update_upgrade() {
  echo
  read -r -p "Run system package update/upgrade now? (y/n): " ans || true
  case "${ans,,}" in
    y|yes)
      if ! need_cmd sudo; then
        echo -e "${C_RED}sudo not found. Cannot perform update as non-root.${C_RESET}"
        return 0
      fi
      echo -e "${C_CYAN}Updating packages...${C_RESET}"
      if need_cmd apt-get; then
        sudo apt-get update -y && sudo apt-get upgrade -y || true
      elif need_cmd dnf; then
        sudo dnf -y upgrade || true
      elif need_cmd yum; then
        sudo yum -y update || true
      elif need_cmd zypper; then
        sudo zypper refresh && sudo zypper update -y || true
      elif need_cmd pacman; then
        sudo pacman -Syu --noconfirm || true
      else
        echo -e "${C_YELLOW}Unsupported package manager. Skipping.${C_RESET}"
      fi
      ;;
    *) ;;
  esac
}

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
    pip=$(curl -fsS --max-time 3 https://api.ipify.org || true)
  elif need_cmd wget; then
    pip=$(wget -qO- --timeout=3 https://api.ipify.org || true)
  fi
  echo "${pip:--}"
}

get_os_name() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-${NAME:-Linux}}"
  else
    uname -sr
  fi
}

get_ssh_port() {
  local port=""
  if need_cmd sshd; then
    if sshd -T >/dev/null 2>&1; then
      port=$(sshd -T 2>/dev/null | awk '/^port / {print $2; exit}')
    fi
  fi
  if [ -z "$port" ]; then
    local candidate=""
    for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do
      [ -r "$f" ] || continue
      candidate=$(awk 'tolower($1)=="port"{p=$2} END{if(p) print p}' "$f" || true)
      if [ -n "$candidate" ]; then port="$candidate"; fi
    done
  fi
  echo "${port:-22}"
}

get_cpu_cores() { nproc 2>/dev/null || echo 1; }
get_ram_bytes() { awk '/MemTotal/ {print $2*1024}' /proc/meminfo; }
get_disk_bytes_total() { df -B1 --output=size / | tail -1 | tr -d ' '; }
get_disk_bytes_avail() { df -B1 --output=avail / | tail -1 | tr -d ' '; }

print_dashboard() {
  local user os ssh_port cores ram_b disk_total_b disk_avail_b ip_local ip_public
  user=$(whoami)
  os=$(get_os_name)
  ssh_port=$(get_ssh_port)
  cores=$(get_cpu_cores)
  ram_b=$(get_ram_bytes)
  disk_total_b=$(get_disk_bytes_total)
  disk_avail_b=$(get_disk_bytes_avail)
  ip_local=$(get_local_ip)
  ip_public=$(get_public_ip)

  local ram_gb disk_total_gb disk_avail_gb
  ram_gb=$(numfmt_gib "$ram_b")
  disk_total_gb=$(numfmt_gib "$disk_total_b")
  disk_avail_gb=$(numfmt_gib "$disk_avail_b")

  echo -e "${C_BOLD}${C_CYAN}=== VPS DASHBOARD ===${C_RESET}"
  printf "%b%-16s%b %b%s%b\n" "$C_WHITE" "User:" "$C_RESET" "$C_GREEN" "$user" "$C_RESET"
  printf "%b%-16s%b %b%s%b\n" "$C_WHITE" "OS:" "$C_RESET" "$C_GREEN" "$os" "$C_RESET"
  printf "%b%-16s%b %b%s%b\n" "$C_WHITE" "IP (Local):" "$C_RESET" "$C_GREEN" "$ip_local" "$C_RESET"
  printf "%b%-16s%b %b%s%b\n" "$C_WHITE" "IP (Public):" "$C_RESET" "$C_GREEN" "$ip_public" "$C_RESET"
  printf "%b%-16s%b %b%s%b\n" "$C_WHITE" "SSHD Port:" "$C_RESET" "$C_GREEN" "$ssh_port" "$C_RESET"
  if [ "$ssh_port" = "22" ]; then
    echo -e "${C_YELLOW}Warning:${C_RESET} ${C_BOLD}SSHD is using the default port 22.${C_RESET} ${C_YELLOW}Consider changing the port in /etc/ssh/sshd_config (or sshd_config.d) and restart sshd to improve security.${C_RESET}"
  fi
  printf "%b%-16s%b %b%s cores%b\n" "$C_WHITE" "CPU Cores:" "$C_RESET" "$C_GREEN" "$cores" "$C_RESET"
  printf "%b%-16s%b %b%s GiB%b\n" "$C_WHITE" "RAM Total:" "$C_RESET" "$C_GREEN" "$ram_gb" "$C_RESET"
  printf "%b%-16s%b %b%s GiB%b\n" "$C_WHITE" "Disk Total (/):" "$C_RESET" "$C_GREEN" "$disk_total_gb" "$C_RESET"
  printf "%b%-16s%b %b%s GiB%b\n" "$C_WHITE" "Disk Avail (/):" "$C_RESET" "$C_GREEN" "$disk_avail_gb" "$C_RESET"
}

list_scripts() {
  [ -d "$SRC_DIR" ] || return 0
  find "$SRC_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | sort
}

run_menu() {
  while true; do
    echo
    echo -e "${C_BOLD}${C_BLUE}Available scripts in src/:${C_RESET}"
    mapfile -t scripts < <(list_scripts)
    if [ "${#scripts[@]}" -eq 0 ]; then
      echo -e "${C_YELLOW}No .sh scripts found in src/.${C_RESET}"
      return 0
    fi
    local i=1
    for s in "${scripts[@]}"; do
      echo "  [$i] $(basename "$s")"
      i=$((i+1))
    done
    echo "  [q] Quit"
    echo
    read -r -p "Select an option: " choice || true
    case "$choice" in
      q|Q) break ;;
      '' ) continue ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#scripts[@]}" ]; then
          local sel="${scripts[$((choice-1))]}"
          echo -e "${C_MAGENTA}Running: ${C_BOLD}$(basename "$sel")${C_RESET}\n"
          bash "$sel" || true
          echo -e "\n${C_DIM}Done. Press Enter to return to menu...${C_RESET}"
          read -r _ || true
        else
          echo -e "${C_RED}Invalid choice.${C_RESET}"
        fi
        ;;
    esac
  done
}

main() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo -e "${C_RED}${C_BOLD}This application cannot run as root.${C_RESET}"
    echo -e "${C_YELLOW}Please create a non-root user, then run this script as that user.${C_RESET}\n"
    cat <<'EOF'
Example commands:

# Debian/Ubuntu
adduser <username>
usermod -aG sudo <username>

# RHEL/CentOS/Alma/Rocky
useradd -m -s /bin/bash <username>
passwd <username>
usermod -aG wheel <username>

# Switch to the new user
su - <username>
EOF
    exit 1
  fi
  maybe_update_upgrade
  print_dashboard
  run_menu
}

main "$@"
