#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }

require_sudo() {
  if ! need_cmd sudo; then
    echo "sudo is required to install packages" >&2
    exit 1
  fi
}

enable_and_start() {
  if need_cmd systemctl; then
    sudo systemctl enable --now nginx || true
  elif need_cmd service; then
    sudo service nginx start || true
  fi
}

install_debian_like() {
  sudo apt-get update -y
  sudo apt-get install -y nginx
  enable_and_start
}

install_fedora_like() {
  if need_cmd dnf; then
    sudo dnf -y install nginx
  else
    sudo yum -y install epel-release || true
    sudo yum -y install nginx
  fi
  enable_and_start
}

install_opensuse_like() {
  sudo zypper refresh
  sudo zypper install -y nginx
  enable_and_start
}

install_arch_like() {
  sudo pacman -Sy --noconfirm --needed nginx
  enable_and_start
}

main() {
  require_sudo

  if [ -r /etc/os-release ]; then . /etc/os-release; else echo "/etc/os-release not found" >&2; exit 1; fi

  case "${ID:-}" in
    ubuntu|debian)
      install_debian_like
      ;;
    fedora)
      install_fedora_like
      ;;
    centos|rhel|rocky|almalinux)
      install_fedora_like
      ;;
    opensuse*|sles)
      install_opensuse_like
      ;;
    arch|manjaro)
      install_arch_like
      ;;
    *)
      case "${ID_LIKE:-}" in
        *debian*) install_debian_like ;;
        *rhel*|*fedora*) install_fedora_like ;;
        *suse*) install_opensuse_like ;;
        *arch*) install_arch_like ;;
        *) echo "Unsupported distro: ${ID:-unknown}. Exiting." >&2; exit 1 ;;
      esac
      ;;
  esac

  echo "Nginx installed and started."
}

main "$@"
