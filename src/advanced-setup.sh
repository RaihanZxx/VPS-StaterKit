#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }

require_sudo() {
  if ! need_cmd sudo; then
    echo "sudo is required" >&2
    exit 1
  fi
}

get_permitrootlogin() {
  local val=""
  if need_cmd sshd; then
    val=$(sshd -T 2>/dev/null | awk '/^permitrootlogin /{print $2; exit}') || true
  fi
  if [ -z "$val" ]; then
    # Parse config files (last match wins)
    local line
    for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do
      [ -r "$f" ] || continue
      line=$(awk 'tolower($1)=="permitrootlogin"{v=$2} END{if(v) print v}' "$f" 2>/dev/null || true)
      [ -n "$line" ] && val="$line"
    done
  fi
  echo "${val:-unknown}"
}

disable_permitrootlogin() {
  # Prefer drop-in override if supported
  if [ -d /etc/ssh/sshd_config.d ]; then
    echo "+ Writing drop-in: /etc/ssh/sshd_config.d/disable-root-login.conf"
    echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/disable-root-login.conf >/dev/null
  else
    # Edit main config with backup
    local cfg="/etc/ssh/sshd_config"
    if [ -w "$cfg" ] || sudo test -w "$cfg"; then
      echo "+ Backing up $cfg to ${cfg}.bak"
      sudo cp -a "$cfg" "${cfg}.bak"
      if grep -qi '^\s*PermitRootLogin\s' "$cfg"; then
        echo "+ Updating PermitRootLogin in $cfg"
        sudo sed -ri 's/^\s*PermitRootLogin\s+.*/PermitRootLogin no/i' "$cfg"
      else
        echo "+ Appending PermitRootLogin no to $cfg"
        echo "PermitRootLogin no" | sudo tee -a "$cfg" >/dev/null
      fi
    else
      echo "Cannot modify $cfg" >&2
      exit 1
    fi
  fi

  echo "+ Validating sshd configuration"
  if need_cmd sshd && sudo sshd -t; then
    :
  else
    echo "sshd -t failed or not available" >&2
    exit 1
  fi

  echo "+ Reloading SSH service"
  sudo systemctl reload ssh || sudo systemctl reload sshd || \
  sudo systemctl restart ssh || sudo systemctl restart sshd || true
}

get_ssh_port() {
  local port=""
  if need_cmd sshd; then
    port=$(sshd -T 2>/dev/null | awk '/^port / {print $2; exit}') || true
  fi
  if [ -z "$port" ]; then
    local candidate=""
    for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do
      [ -r "$f" ] || continue
      candidate=$(awk 'tolower($1)=="port"{p=$2} END{if(p) print p}' "$f" 2>/dev/null || true)
      [ -n "$candidate" ] && port="$candidate"
    done
  fi
  echo "${port:-22}"
}

set_ssh_port() {
  local new_port="$1"
  if [ -d /etc/ssh/sshd_config.d ]; then
    echo "+ Writing drop-in: /etc/ssh/sshd_config.d/port-override.conf"
    echo "Port ${new_port}" | sudo tee /etc/ssh/sshd_config.d/port-override.conf >/dev/null
  else
    local cfg="/etc/ssh/sshd_config"
    echo "+ Backing up $cfg to ${cfg}.bak"
    sudo cp -a "$cfg" "${cfg}.bak" 2>/dev/null || true
    echo "+ Removing existing Port lines (commented or not) from $cfg"
    sudo sed -ri '/^\s*#?\s*Port\s+/d' "$cfg"
    echo "+ Appending Port ${new_port} to $cfg"
    echo "Port ${new_port}" | sudo tee -a "$cfg" >/dev/null
  fi
  echo "+ Validating sshd configuration"
  if need_cmd sshd && sudo sshd -t; then :; else echo "sshd -t failed" >&2; exit 1; fi
}

change_port_flow() {
  local cur_port
  cur_port=$(get_ssh_port)
  if [ "$cur_port" != "22" ]; then
    echo "Current SSH port is $cur_port (not 22); skipping port change prompt."
    return 0
  fi
  read -r -p "Ganti port SSH dari 22? (y/n): " ans || true
  case "${ans,,}" in
    y|yes)
      read -r -p "Masukkan port baru (1-65535, selain 22): " new_port
      if ! echo "$new_port" | grep -Eq '^[0-9]+$' || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ] || [ "$new_port" -eq 22 ]; then
        echo "Port tidak valid." >&2; exit 1
      fi
      set_ssh_port "$new_port"
      if need_cmd ufw; then
        echo "+ sudo ufw allow ${new_port}/tcp"
        sudo ufw allow "${new_port}/tcp" || true
      fi
      echo "+ sudo systemctl daemon-reload"
      sudo systemctl daemon-reload || true
      echo "+ sudo systemctl restart ssh.socket"
      sudo systemctl restart ssh.socket || true
      echo "+ sudo systemctl restart sshd"
      sudo systemctl restart sshd || true

      while true; do
        read -r -p "Sudah bisa login menggunakan port ${new_port}? (y/n): " ok || true
        case "${ok,,}" in
          y|yes)
            if need_cmd ufw; then
              sudo ufw delete allow OpenSSH || true
              sudo ufw delete allow 22/tcp || true
            fi
            echo "Konfigurasi selesai."
            break
            ;;
          *) echo "Silakan coba login lagi dengan port ${new_port}." ;;
        esac
      done
      ;;
    *) echo "Lewati pergantian port." ;;
  esac
}

main() {
  require_sudo
  local cur
  cur=$(get_permitrootlogin | tr 'A-Z' 'a-z')
  if [ "$cur" = "yes" ]; then
    read -r -p "PermitRootLogin is 'yes'. Disable it now? (y/n): " ans || true
    case "${ans,,}" in
      y|yes) disable_permitrootlogin; echo "PermitRootLogin disabled." ;;
      *) echo "Skipped. No changes made." ;;
    esac
  else
    echo "PermitRootLogin is '$cur'. Nothing to change."
  fi

  change_port_flow
}

main "$@"
