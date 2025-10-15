# Getting Started

1) Launch the dashboard and menu:
```bash
chmod +x start.sh
./start.sh
```

2) Recommended order (menu items under src/):
- setup-basic.sh: enable SSH service, set basic UFW rules
- advanced-setup.sh: disable root login, optionally change SSH port
- install-docker.sh: install Docker engine and completions
- install-nginx.sh: install and start Nginx
- setup-swap.sh: review specs and configure a swap file size

3) Keep one SSH session open when applying SSH changes.
