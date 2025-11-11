#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC_DIR="${SCRIPT_DIR}/src"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/common.sh"

maybe_update_upgrade() {
  echo
  if prompt_yes_no "Run system package update/upgrade now?"; then
    if ! need_cmd sudo; then
      log_error "sudo not found. Cannot perform update as non-root."
      return 0
    fi
    log_info "Updating packages..."
    pkg_update || log_warn "Package update completed with errors"
  fi
}

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
