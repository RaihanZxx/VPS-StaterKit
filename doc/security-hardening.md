# Security Hardening

- SSH
  - Disable PermitRootLogin (advanced-setup.sh)
  - Change default port 22 and allow the new port in UFW
  - Use key-based auth; restrict PasswordAuthentication when feasible
- Firewall
  - Keep “OpenSSH” rule or a single explicit port rule; avoid duplicates
  - Remove legacy 22/tcp after migrating to a new port
- System hygiene
  - Update packages regularly
  - Minimal installed surface; remove unused services
