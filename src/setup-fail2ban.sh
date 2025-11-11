#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"

check_fail2ban() {
  need_cmd fail2ban-client
}

install_fail2ban() {
  require_sudo

  local pm
  pm=$(detect_pkg_manager)

  log_info "Installing fail2ban via $pm..."

  case "$pm" in
    apt)
      sudo apt-get update -y
      sudo apt-get install -y fail2ban fail2ban-doc
      ;;
    dnf)
      sudo dnf -y install fail2ban fail2ban-doc
      ;;
    yum)
      sudo yum -y install epel-release || true
      sudo yum -y install fail2ban fail2ban-doc
      ;;
    zypper)
      sudo zypper refresh
      sudo zypper install -y fail2ban
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed fail2ban
      ;;
    *)
      log_error "Unsupported package manager: $pm"
      exit 1
      ;;
  esac

  log_success "fail2ban installed"
}

setup_ssh_jail() {
  require_sudo

  local ssh_port
  ssh_port=$(get_ssh_port)

  local config_file="/etc/fail2ban/jail.local"
  local jail_d_dir="/etc/fail2ban/jail.d"

  if [ -d "$jail_d_dir" ]; then
    config_file="${jail_d_dir}/sshd.local"
  fi

  log_info "Creating fail2ban configuration for SSH port $ssh_port..."

  cat <<EOF | sudo tee "$config_file" >/dev/null
# SSH Jail Configuration
[sshd]
enabled = true
port = $ssh_port
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
findtime = 600
bantime = 3600
action = iptables-multiport[name=SSH, port="ssh,sftp"]
         sendmail-whois[name=Fail2Ban, dest=root@localhost]
EOF

  log_success "fail2ban SSH configuration created at $config_file"
}

validate_config() {
  require_sudo

  log_info "Validating fail2ban configuration..."
  if ! sudo fail2ban-client -d 2>&1 | grep -q "Configuration:"; then
    log_warn "Configuration validation incomplete, but proceeding..."
  else
    log_success "Configuration validation passed"
  fi
}

enable_fail2ban_service() {
  require_sudo

  log_info "Starting fail2ban service..."
  enable_service fail2ban || log_warn "Could not enable fail2ban service"

  log_info "Checking fail2ban status..."
  sudo fail2ban-client status || true
}

show_jail_status() {
  require_sudo

  log_info "Displaying active jails..."
  sudo fail2ban-client status || true

  log_info "To check SSH jail specifically, run:"
  echo "  sudo fail2ban-client status sshd"

  log_info "To check blocked IPs, run:"
  echo "  sudo fail2ban-client banned"

  log_info "To unban an IP, run:"
  echo "  sudo fail2ban-client set sshd unbanip <IP>"
}

main() {
  log_info "=== Fail2ban Setup Assistant ==="
  echo

  require_sudo

  if check_fail2ban; then
    log_success "fail2ban is already installed"
  else
    if prompt_yes_no "fail2ban not found. Install it now?"; then
      install_fail2ban
    else
      log_warn "Skipping fail2ban installation"
      exit 0
    fi
  fi

  if prompt_yes_no "Configure SSH jail for fail2ban?"; then
    setup_ssh_jail
  fi

  validate_config

  if prompt_yes_no "Enable and start fail2ban service?"; then
    enable_fail2ban_service
    echo
    show_jail_status
  else
    log_warn "fail2ban service not started. You can start it later with: sudo systemctl start fail2ban"
  fi

  echo
  log_success "Fail2ban setup completed!"
  log_info "To manage fail2ban, use 'sudo fail2ban-client' commands or 'sudo systemctl' for the service"
}

main "$@"
