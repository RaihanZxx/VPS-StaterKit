# VPS Starter Kit

Minimal, script-driven toolkit to bootstrap and harden a fresh VPS quickly. Includes a colored dashboard with menu runner, Docker/Nginx installers, SSH hardening helpers, swap setup assistant, and basic firewall configuration.

## Features
- start.sh: dashboard (user, OS, IPs, SSH port, CPU, RAM, disk) + interactive menu for scripts in src/
- Root guard: if run as root, offers to create a non-root user, copies the app to that user’s home, and re-runs
- Optional system update step before dashboard
- Installers: install-docker.sh, install-nginx.sh
- Setup: setup-basic.sh (enable SSH, UFW rules), setup-swap.sh (show specs, recommend swap, prompt size)
- Hardening: advanced-setup.sh (disable PermitRootLogin, change SSH port safely)

## Quick start
```bash
chmod +x start.sh
./start.sh
```

## Requirements
- A modern Linux with systemd
- sudo access for privileged operations
- Optional: ufw, curl/wget, rsync

## Project layout
```
start.sh                # Dashboard + menu
src/
  install-docker.sh
  install-nginx.sh
  setup-basic.sh
  setup-swap.sh
  advanced-setup.sh
introduction/
  vps.md                # What is a VPS?
doc/
  README.md             # Docs index
  getting-started.md
  security-hardening.md
```

## Security notes
- Always keep at least one active SSH session when changing SSH settings/ports
- Regularly update packages and review firewall rules

## License
See LICENSE.
