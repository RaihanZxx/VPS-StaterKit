#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"

check_ufw() {
  need_cmd ufw
}

install_ufw() {
  require_sudo

  local pm
  pm=$(detect_pkg_manager)

  log_info "Installing UFW via $pm..."

  case "$pm" in
    apt)
      sudo apt-get update -y
      sudo apt-get install -y ufw
      ;;
    dnf)
      sudo dnf -y install ufw
      ;;
    yum)
      sudo yum -y install ufw
      ;;
    zypper)
      sudo zypper refresh
      sudo zypper install -y ufw
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed ufw
      ;;
    *)
      log_error "Unsupported package manager: $pm"
      exit 1
      ;;
  esac

  log_success "UFW installed"
}

show_status() {
  require_sudo

  echo
  log_info "Current UFW status:"
  sudo ufw status verbose || true
  echo
}

setup_basic_rules() {
  require_sudo

  log_info "Setting up basic UFW rules..."

  sudo ufw default deny incoming
  log_success "Default incoming: DENY"

  sudo ufw default allow outgoing
  log_success "Default outgoing: ALLOW"

  sudo ufw default deny routed
  log_success "Default routed: DENY"
}

allow_ssh() {
  require_sudo

  local ssh_port
  ssh_port=$(get_ssh_port)

  log_info "Adding rule to allow SSH on port $ssh_port..."

  if [ "$ssh_port" = "22" ]; then
    sudo ufw allow OpenSSH || sudo ufw allow 22/tcp || true
  else
    sudo ufw allow "$ssh_port"/tcp || true
  fi

  log_success "SSH port $ssh_port allowed"
}

allow_web() {
  require_sudo

  log_info "Adding rules to allow HTTP/HTTPS..."
  sudo ufw allow 80/tcp || true
  sudo ufw allow 443/tcp || true
  log_success "HTTP (80) and HTTPS (443) allowed"
}

interactive_add_rule() {
  require_sudo

  echo
  log_info "=== Add Custom UFW Rule ==="
  echo "Format: port/protocol (e.g., 8080/tcp, 5353/udp, 53)"
  echo

  local rule
  rule=$(prompt_input "Enter port/protocol (or press Enter to skip): " "")

  if [ -z "$rule" ]; then
    log_info "Skipping custom rule"
    return
  fi

  local description
  description=$(prompt_input "Enter description (optional): " "")

  if [ -n "$description" ]; then
    sudo ufw allow "$rule" comment "$description" || true
  else
    sudo ufw allow "$rule" || true
  fi

  log_success "Rule added: $rule"
}

interactive_delete_rule() {
  require_sudo

  echo
  log_info "=== Delete UFW Rule ==="
  show_status
  log_info "Numbered rules are shown above. To delete a rule by number, use:"
  echo "  sudo ufw delete <number>"
  echo
  log_info "Or delete by rule:"
  echo "  sudo ufw delete allow <port/protocol>"
  echo
  log_warn "This script does not delete rules interactively. Use the commands above."
}

enable_firewall() {
  require_sudo

  if sudo ufw status | grep -qi "active"; then
    log_info "UFW is already active"
    return
  fi

  log_info "Enabling UFW..."
  if prompt_yes_no "Enable UFW now? (This will apply all rules)"; then
    sudo ufw --force enable
    log_success "UFW enabled"
  else
    log_warn "UFW not enabled. Remember to enable it when ready!"
  fi
}

main() {
  log_info "=== UFW Firewall Setup Assistant ==="
  echo

  require_sudo

  if ! check_ufw; then
    log_warn "UFW is not installed"
    if prompt_yes_no "Install UFW now?"; then
      install_ufw
    else
      log_error "UFW is required. Exiting."
      exit 1
    fi
  fi

  show_status

  while true; do
    echo
    echo -e "${C_BOLD}${C_BLUE}UFW Management Options:${C_RESET}"
    echo "  [1] Show status"
    echo "  [2] Setup basic default rules (deny in, allow out)"
    echo "  [3] Allow SSH"
    echo "  [4] Allow HTTP/HTTPS"
    echo "  [5] Add custom rule interactively"
    echo "  [6] Delete rule (instructions)"
    echo "  [7] Enable firewall"
    echo "  [8] Disable firewall"
    echo "  [q] Quit"
    echo

    local choice
    choice=$(prompt_input "Select an option: " "")

    case "$choice" in
      1) show_status ;;
      2) setup_basic_rules ;;
      3) allow_ssh ;;
      4) allow_web ;;
      5) interactive_add_rule ;;
      6) interactive_delete_rule ;;
      7) enable_firewall ;;
      8)
        if prompt_yes_no "Disable UFW?"; then
          require_sudo
          sudo ufw --force disable
          log_success "UFW disabled"
        fi
        ;;
      q|Q) break ;;
      *)
        log_warn "Invalid choice. Please select a valid option."
        ;;
    esac
  done

  echo
  log_success "UFW setup completed!"
}

main "$@"
