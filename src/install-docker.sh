#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"

CURRENT_SHELL=${SHELL:-}
SHELL_NAME=$(basename "${CURRENT_SHELL:-sh}")
case "$SHELL_NAME" in
  bash|fish) ;;
  *) SHELL_NAME=bash ;;
esac

enable_and_start() {
  if need_cmd systemctl; then
    sudo systemctl enable --now docker || true
  elif need_cmd service; then
    sudo service docker start || true
  fi
}

install_debian_like() {
  local distro=$1
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  local arch
  arch=$(dpkg --print-architecture)
  local codename
  codename=$(. /etc/os-release && echo "${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo stable)}")
  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro} ${codename} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  enable_and_start
}

install_fedora_like() {
  if need_cmd dnf; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    sudo yum -y install yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  enable_and_start
}

install_opensuse_like() {
  sudo zypper refresh
  sudo zypper install -y docker docker-compose
  enable_and_start
}

install_arch_like() {
  sudo pacman -Sy --noconfirm --needed docker docker-compose
  enable_and_start
}

setup_shell_completion() {
  if ! need_cmd docker; then return; fi
  case "$SHELL_NAME" in
    bash)
      if docker completion bash >/dev/null 2>&1; then
        mkdir -p "${HOME}/.local/share/bash-completion/completions"
        docker completion bash > "${HOME}/.local/share/bash-completion/completions/docker"
      fi
      ;;
    fish)
      if docker completion fish >/dev/null 2>&1; then
        mkdir -p "${HOME}/.config/fish/completions"
        docker completion fish > "${HOME}/.config/fish/completions/docker.fish"
      fi
      ;;
  esac
}

main() {
  echo "Detected shell: ${SHELL_NAME}"
  require_sudo

  if need_cmd docker; then
    echo "Docker already installed; configuring shell completion..."
    setup_shell_completion
    echo "Done. You may need to restart your shell."
    exit 0
  fi

  if [ -r /etc/os-release ]; then . /etc/os-release; else echo "/etc/os-release not found" >&2; exit 1; fi

  case "${ID:-}" in
    ubuntu|debian)
      install_debian_like "${ID}"
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
        *debian*) install_debian_like "debian" ;;
        *rhel*|*fedora*) install_fedora_like ;;
        *suse*) install_opensuse_like ;;
        *arch*) install_arch_like ;;
        *) echo "Unsupported distro: ${ID:-unknown}. Exiting." >&2; exit 1 ;;
      esac
      ;;
  esac

  sudo usermod -aG docker "$USER" || true
  setup_shell_completion

  echo "Docker installed. Service started. User added to 'docker' group."
  echo "Log out and back in (or run: newgrp docker) for group changes to take effect."
}

main "$@"
