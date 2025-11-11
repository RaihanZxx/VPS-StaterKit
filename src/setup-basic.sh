#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"

enable_ssh_service() {
  echo "+ sudo systemctl enable --now ssh"
  if ! sudo systemctl enable --now ssh; then
    echo "+ fallback: sudo systemctl enable --now sshd"
    sudo systemctl enable --now sshd
  fi
  echo "+ sudo systemctl status ssh || sudo systemctl status sshd"
  sudo systemctl status ssh || sudo systemctl status sshd || true
}

check_port_22() {
  if need_cmd ss; then
    echo "+ sudo ss -tulpen | grep ':22'"
    sudo ss -tulpen | grep ':22' || true
  else
    echo "ss not found; skipping port check" >&2
  fi
}

configure_ufw() {
  if ! need_cmd ufw; then
    echo "ufw not installed; skipping firewall configuration" >&2
    return 0
  fi
  echo "+ sudo ufw allow OpenSSH"
  sudo ufw allow OpenSSH || true
  echo "+ sudo ufw allow 22/tcp"
  sudo ufw allow 22/tcp || true
  echo "+ sudo ufw status"
  sudo ufw status || true
  echo "+ sudo ufw --force enable"
  sudo ufw --force enable || true
  echo "+ sudo ufw status"
  sudo ufw status || true
}

cleanup_ufw_port22() {
  if ! need_cmd ufw; then return 0; fi
  if sudo ufw status | grep -qi "inactive"; then
    echo "UFW is inactive; skipping cleanup"; return 0
  fi
  echo "+ checking explicit 22/tcp rules"
  if sudo ufw status | grep -q "22/tcp"; then
    if sudo ufw delete allow 22/tcp; then
      echo "Removed 'allow 22/tcp' rule(s)."
    else
      mapfile -t RULE_NUMS < <(sudo ufw status numbered | awk '{num=$1; gsub(/[^0-9]/,"",num); if (num!="" && $0 ~ /22\/tcp/) print num}' | sort -rn)
      for n in "${RULE_NUMS[@]:-}"; do
        [ -n "$n" ] || continue
        echo "+ sudo ufw delete $n"
        sudo ufw --force delete "$n" || true
      done
    fi
    sudo ufw status || true
  else
    echo "No explicit 22/tcp rule found."
  fi
}

prompt_cleanup_choice() {
  echo
  read -r -p "Hapus aturan '22/tcp' (menyisakan OpenSSH saja)? (y/n): " ans || true
  case "${ans,,}" in
    y|yes) cleanup_ufw_port22 ;;
    *) echo "Lewati pembersihan aturan." ;;
  esac
}

main() {
  require_sudo
  enable_ssh_service
  check_port_22
  configure_ufw
  prompt_cleanup_choice
}

main "$@"
