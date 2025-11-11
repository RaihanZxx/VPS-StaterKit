# VPS Starter Kit - Features & Components

## Overview
VPS Starter Kit provides a comprehensive collection of shell scripts and utilities for bootstrapping and hardening a fresh VPS quickly. It's designed for administrators who want a solid foundation with security best practices baked in.

## Core Components

### 1. Dashboard & Menu System (`start.sh`)
The main entry point that provides:
- **System Information Dashboard:**
  - Current user and OS
  - Local and public IP addresses
  - SSH port configuration
  - CPU cores and RAM
  - Disk space (total and available)

- **Interactive Menu:**
  - Easy access to all setup scripts
  - Numbered menu selection
  - Automatic error handling
  - Script output capture

- **Optional System Update:**
  - Automatically detect package manager (apt, dnf, yum, zypper, pacman)
  - Update packages before running scripts
  - Fallback handling for unsupported distributions

### 2. Installation Scripts

#### Docker Installation (`install-docker.sh`)
- Multi-distribution support (Ubuntu, Debian, Fedora, CentOS, RHEL, openSUSE, Arch)
- Official Docker repository configuration
- Docker Compose plugin integration
- Automatic service enablement
- Shell completion setup (bash and fish)
- User group management

#### Nginx Installation (`install-nginx.sh`)
- Distribution-aware package selection
- Automatic service start and enablement
- Quick verification of installation

### 3. Configuration & Setup Scripts

#### Basic SSH & Firewall Setup (`setup-basic.sh`)
- SSH service enablement
- Port verification
- UFW firewall configuration
- Basic UFW rules for SSH access
- Optional cleanup of duplicate rules

#### Advanced Security Setup (`advanced-setup.sh`)
- SSH root login disable (PermitRootLogin)
- Safe SSH port change with multi-step verification
- Configuration backup before changes
- Automatic service restart and validation
- Backup restoration capability

#### Swap File Management (`setup-swap.sh`)
- Detailed system specifications display
- Intelligent swap size recommendations based on:
  - RAM amount
  - Available disk space
  - System type (server vs workstation)
- User-friendly interactive sizing
- Safety checks and validations

### 4. Security Hardening Scripts

#### Fail2ban Setup (`setup-fail2ban.sh`)
- Fail2ban installation across distributions
- SSH jail configuration with customizable ports
- Automatic configuration validation
- Service enablement and status monitoring
- Ban/unban management helpers
- Integration with firewall rules

#### UFW Firewall Management (`setup-ufw.sh`)
- Interactive firewall rule management
- Support for multiple protocols (TCP, UDP)
- HTTP/HTTPS convenience presets
- Default policy configuration
- Custom rule creation with descriptions
- Rule deletion guidance
- Real-time status monitoring
- Enable/disable controls

### 5. Shared Utilities Library (`lib/common.sh`)

#### Color & Logging Functions
- TTY auto-detection
- Colored output (info, success, warning, error, debug)
- Consistent message formatting
- Debug mode support

#### Command & Requirement Checks
- `need_cmd()` - Check if command exists
- `require_cmd()` - Exit if command missing
- `require_sudo()` - Validate sudo availability
- `require_root()` - Ensure root execution

#### System Information Functions
- OS detection and identification
- CPU core counting
- RAM availability
- Disk space (total and available)
- Network IP detection (local and public)
- SSH port discovery
- Distribution identification

#### Package Management
- Automatic package manager detection
- Universal `pkg_install()` interface
- `pkg_update()` for system updates
- Support for: apt, dnf, yum, zypper, pacman

#### Service Management
- `enable_service()` - Enable and start
- `start_service()` - Start service
- `stop_service()` - Stop service
- `restart_service()` - Restart service
- `service_status()` - Check status
- Dual support for systemctl and service commands

#### Validation Functions
- `is_valid_port()` - Port range validation (1-65535)
- `is_valid_ip()` - IPv4 address validation

#### File Operations
- `backup_file()` - Create timestamped backups
- `restore_backup()` - Restore from backups

#### User Interaction
- `prompt_yes_no()` - Yes/no confirmations
- `prompt_input()` - User input collection with defaults

#### Utility Functions
- Number formatting (GiB, MiB, KiB conversion)

## Development & Quality Tools

### Makefile Tasks
```bash
make lint              # ShellCheck linting
make format            # Auto-format with shfmt
make test              # Run BATS test suite
make check-tools       # Verify installed tools
make install-bats      # Install test framework
make install-shellcheck # Install linter
make install-shfmt     # Install formatter
```

### Testing Framework
- **BATS (Bash Automated Testing System)**
- Unit tests for library functions
- Validation tests for utilities
- Easy to extend with new tests

### CI/CD Pipeline (GitHub Actions)
- Automatic linting on push/PR
- Test execution
- Script syntax validation
- Code formatting checks
- Security scanning
- Multi-step validation workflow

## Distribution Support

### Fully Supported
- **Debian/Ubuntu:** apt-get package manager
- **RHEL/CentOS/Rocky/AlmaLinux:** yum/dnf package managers
- **Fedora:** dnf package manager
- **openSUSE/SLES:** zypper package manager
- **Arch/Manjaro:** pacman package manager

### Fallback Support
- Partial support for other systemd-based distributions
- Graceful degradation if specific package managers unavailable

## Key Features Summary

| Feature | Status | Coverage |
|---------|--------|----------|
| Multi-distro support | ✅ | 5+ major distributions |
| SSH hardening | ✅ | Root login disable, port change |
| Firewall setup | ✅ | UFW with interactive management |
| Fail2ban | ✅ | SSH jail, auto-configuration |
| Service management | ✅ | Enable, start, stop, restart |
| Docker installation | ✅ | All supported distributions |
| Nginx installation | ✅ | All supported distributions |
| Backup & restore | ✅ | Configuration backups |
| Testing framework | ✅ | BATS with 20+ unit tests |
| Code linting | ✅ | ShellCheck integration |
| CI/CD pipeline | ✅ | GitHub Actions |
| Documentation | ✅ | Comprehensive guides |
| Troubleshooting | ✅ | Common issues covered |
| Code reusability | ✅ | Shared library (lib/common.sh) |

## Security Features

- **SSH Security:**
  - Root login disabling
  - Custom port configuration with safe transitions
  - Configuration backups

- **Firewall:**
  - UFW integration
  - Service-aware rules
  - DRY rule management (avoid duplicates)

- **Intrusion Prevention:**
  - Fail2ban integration
  - SSH-specific jails
  - Automatic service startup

- **Code Safety:**
  - No hardcoded secrets
  - Input validation
  - Proper error handling
  - Sudo privilege management

## Extensibility

The kit is designed to be extended easily:

1. **Add new scripts:**
   - Source lib/common.sh
   - Use logging functions
   - Follow existing patterns

2. **Add reusable functions:**
   - Add to lib/common.sh
   - Export at bottom of file
   - Write tests in test-common.bats

3. **Add new setup scripts:**
   - Create in src/ directory
   - Follow naming convention (setup-*.sh or install-*.sh)
   - Include in main menu automatically

## Performance Characteristics

- **Lightweight:** All core libraries <50KB
- **Fast:** Minimal dependencies
- **Efficient:** Caching of system info where appropriate
- **Responsive:** Interactive feedback during operations

## Limitations & Known Issues

1. **Cannot run as root:** Intentionally restricted for security
2. **Requires sudo:** Must have sudoers group access
3. **systemd only:** Requires systemd init system
4. **Configuration backup limitations:** Manual restore needed in some cases
5. **No rollback automation:** Safe approach with manual verification required

## Version Compatibility

- **Bash:** 4.0+ (most distributions included by default)
- **Git:** 2.0+
- **Linux:** Any modern systemd-based distribution
- **Tested on:** Ubuntu 20.04+, Debian 11+, CentOS 8+, Fedora 35+

## Future Roadmap

Potential additions (not yet implemented):
- SSL/TLS certificate automation (Let's Encrypt)
- Automatic backup scheduling
- Monitoring setup (Prometheus, Node Exporter)
- Database initialization scripts (PostgreSQL, MySQL)
- Application deployment templates
- VPN/WireGuard setup
- Log aggregation helpers
- Performance tuning scripts

## Contributing

The kit welcomes contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](../LICENSE) file for details.
