# Troubleshooting Guide

## Common Issues and Solutions

### 1. Script Permission Errors

**Problem:** "Permission denied" when running scripts

**Solution:**
```bash
# Make all scripts executable
chmod +x start.sh
chmod +x src/*.sh

# Verify permissions
ls -la start.sh
```

---

### 2. Sudo Password Prompts

**Problem:** Script keeps asking for sudo password

**Solution:**
- Make sure your user is in the sudoers group:
  ```bash
  groups $USER
  ```
  
- If `sudo` is not in the output, add your user (requires current sudo access):
  ```bash
  sudo usermod -aG sudo $USER
  # On RHEL/CentOS/Fedora:
  sudo usermod -aG wheel $USER
  ```

- Log out and log back in for the changes to take effect

---

### 3. SSH Connection Issues After Changes

**Problem:** Locked out of SSH after running advanced-setup.sh

**Prevention:** 
- **Always keep at least two SSH sessions open** when making SSH configuration changes
- Test the new configuration in a separate session before closing the original

**Recovery:**
1. If you have console/ILO access to the server:
   - Connect via console
   - Restore SSH config from backup:
     ```bash
     sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
     sudo systemctl restart sshd
     ```

2. If using a provider like AWS/DigitalOcean:
   - Use their web console to connect
   - Restore the SSH configuration
   - Verify the port and settings

---

### 4. UFW Firewall Locked Me Out

**Problem:** UFW blocks SSH access after setup-ufw.sh

**Solution:**
1. Connect via console access if available
2. Check UFW status:
   ```bash
   sudo ufw status
   ```

3. If SSH rule is missing:
   ```bash
   sudo ufw allow OpenSSH
   # or for non-standard port:
   sudo ufw allow 2222/tcp
   ```

4. Reload UFW:
   ```bash
   sudo systemctl restart ufw
   ```

---

### 5. Docker Installation Fails

**Problem:** "E: Unable to locate package" or similar during docker install

**Causes & Solutions:**

- **Unsupported Distribution:**
  ```bash
  # Check your OS
  cat /etc/os-release
  ```
  Docker supports: Ubuntu, Debian, Fedora, CentOS, RHEL, openSUSE, Arch

- **Stale Package Cache:**
  ```bash
  sudo apt-get update -y
  # Then retry docker installation
  ```

- **Missing GPG Key (apt-based systems):**
  ```bash
  # Manual fix:
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  ```

---

### 6. Nginx Installation Issues

**Problem:** Nginx fails to start or won't bind to port 80/443

**Check if ports are in use:**
```bash
sudo ss -tulpen | grep -E ':(80|443)'
# or
sudo netstat -tulpen | grep -E ':(80|443)'
```

**Kill conflicting service:**
```bash
# Find the process using port 80
sudo lsof -i :80

# Kill it (replace PID)
sudo kill -9 <PID>

# Restart Nginx
sudo systemctl restart nginx
```

---

### 7. Fail2ban Not Blocking Attempts

**Problem:** fail2ban installed but not blocking IP addresses

**Debug steps:**
```bash
# Check if fail2ban is running
sudo systemctl status fail2ban

# Check jail status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Check logs
sudo tail -f /var/log/fail2ban.log

# Check iptables rules
sudo iptables -L -n | grep -i fail2ban
```

**Common causes:**
1. Jail not enabled (check `/etc/fail2ban/jail.local`)
2. Filter rules too permissive (check `/etc/fail2ban/filter.d/sshd.conf`)
3. logpath pointing to wrong file (common on different distros)

**Fix:**
```bash
# Restart fail2ban after making changes
sudo systemctl restart fail2ban

# Verify it's working
sudo fail2ban-client status sshd
```

---

### 8. Swap File Not Created

**Problem:** setup-swap.sh shows recommendation but file not created

**Reason:** The script only provides recommendations, doesn't create the file automatically.

**Manual swap creation:**
```bash
# Create swap file (4GB example)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent (add to /etc/fstab)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
swapon --show
free -h
```

---

### 9. Package Manager Detection Issues

**Problem:** Script can't detect package manager

**Check available managers:**
```bash
# Test which package managers are available
command -v apt-get && echo "apt-get found"
command -v dnf && echo "dnf found"
command -v yum && echo "yum found"
command -v zypper && echo "zypper found"
command -v pacman && echo "pacman found"
```

---

### 10. Permission Issues with lib/common.sh

**Problem:** "lib/common.sh not found" or sourcing fails

**Solution:**
```bash
# Make sure lib directory exists and is readable
ls -la lib/
ls -la lib/common.sh

# Make common.sh executable
chmod +x lib/common.sh

# Check for syntax errors
bash -n lib/common.sh
```

---

### 11. System Commands Not Found

**Problem:** get_os_name, get_cpu_cores, etc. return empty or errors

**Causes:**
- /proc/meminfo, /proc/cpuinfo, or /etc/os-release missing
- df command not available

**Check:**
```bash
# These should all exist on modern Linux systems
cat /proc/meminfo
cat /proc/cpuinfo
cat /etc/os-release
df --help
```

---

## Debug Mode

Enable debug output for troubleshooting:
```bash
# Set DEBUG environment variable
DEBUG=1 ./start.sh

# Or for specific scripts:
DEBUG=1 bash src/advanced-setup.sh
```

---

## Getting More Help

1. **Check logs:**
   ```bash
   # System logs
   sudo journalctl -xe
   
   # Specific service logs
   sudo journalctl -u sshd -n 50
   sudo journalctl -u fail2ban -n 50
   sudo journalctl -u nginx -n 50
   ```

2. **Test configuration syntax:**
   ```bash
   # SSH config
   sudo sshd -t
   
   # fail2ban config
   sudo fail2ban-client -d
   
   # Nginx config
   sudo nginx -t
   ```

3. **Network diagnostics:**
   ```bash
   # Check listening ports
   sudo ss -tulpen
   
   # Check active connections
   sudo ss -tan
   
   # DNS resolution test
   nslookup google.com
   ```

---

## Common Port Numbers Reference

| Service | Default Port | Protocol |
|---------|--------------|----------|
| SSH | 22 | TCP |
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| DNS | 53 | TCP/UDP |
| MySQL | 3306 | TCP |
| PostgreSQL | 5432 | TCP |
| Redis | 6379 | TCP |
| Docker | 2375 | TCP |

---

## Safety Checklist

Before making system changes:
- [ ] Backup important configurations
- [ ] Have a recovery method (console access, rescue shell, etc.)
- [ ] Keep an SSH session open when modifying SSH settings
- [ ] Test changes with UFW rules in place
- [ ] Document any custom changes made
- [ ] Have a plan to rollback if something breaks

---

## Emergency Recovery

If you completely locked yourself out:

1. **Contact your VPS provider** and request console/ILO access
2. **Boot into single-user mode** or use rescue shell
3. **Restore from backup:**
   ```bash
   # Example: restore SSH config from backup
   cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
   systemctl restart sshd
   ```
4. **Verify connectivity before closing console**

---

## Reporting Issues

If you encounter issues not covered here:
1. Collect relevant logs and error messages
2. Document what you were trying to do
3. Include your OS/distribution information
4. Check if it's a known issue in the project repository
5. Create a GitHub issue with details
