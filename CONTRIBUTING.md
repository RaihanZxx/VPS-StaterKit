# Contributing to VPS Starter Kit

Thank you for your interest in contributing! This guide will help you understand how to contribute effectively.

## Code of Conduct

- Be respectful and professional
- Welcome diverse perspectives
- Report issues constructively
- Help others learn and grow

## Getting Started

### Prerequisites
- Bash 4.0+
- git 2.0+
- sudo access (for testing scripts)
- Optional: ShellCheck, shfmt, BATS

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/VPS-StarterKit.git
   cd VPS-StarterKit
   ```

2. **Install development tools:**
   ```bash
   make install-shellcheck
   make install-shfmt
   make install-bats
   ```

3. **Verify setup:**
   ```bash
   make check-tools
   ```

## Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/my-feature
# or for bug fixes:
git checkout -b fix/issue-description
```

### 2. Make Your Changes
- Follow existing code style (see Code Style section)
- Keep scripts focused and modular
- Add functions to `lib/common.sh` if they're reusable
- Write descriptive commit messages

### 3. Test Your Changes
```bash
# Run linting
make lint

# Check formatting
make format

# Run tests
make test

# Test manually (if script requires sudo)
bash src/your-script.sh
```

### 4. Commit Your Changes
```bash
git add .
git commit -m "type: Description of changes

Detailed explanation if needed."
```

### 5. Push and Create Pull Request
```bash
git push origin feature/my-feature
```

Then create a PR on GitHub.

## Code Style Guide

### Bash Styling
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source the common library
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"

# Use descriptive function names
do_something() {
  local var="$1"
  local status=0
  
  # Use log functions for output
  log_info "Doing something..."
  
  if some_command "$var"; then
    log_success "Done!"
  else
    log_error "Failed to do something"
    return 1
  fi
  
  return $status
}

main() {
  # Validate requirements
  require_sudo
  
  # Call functions
  do_something "value"
}

main "$@"
```

### Key Style Points
1. **Use `set -euo pipefail`** - Exit on error, undefined vars, pipe failures
2. **Quote variables:** `"$var"` not `$var`
3. **Use local variables** in functions
4. **Use log functions:** `log_info`, `log_error`, `log_warn`, `log_success`
5. **Use functions from lib/common.sh** when applicable
6. **Add comments** for complex logic, not obvious code
7. **Keep functions focused** - one responsibility per function
8. **Use meaningful names** - `get_local_ip` not `get_ip1`

### Formatting
Run shfmt to auto-format:
```bash
make format
```

Or manually:
```bash
shfmt -i 2 -w your-script.sh
```

## Adding New Features

### New Installation Script
If you're adding a new installer (e.g., `install-postgresql.sh`):

1. **Create the script:**
   ```bash
   cp src/install-docker.sh src/install-postgresql.sh
   ```

2. **Use the common library:**
   ```bash
   source "${LIB_DIR}/common.sh"
   ```

3. **Support multiple distributions:**
   ```bash
   case "$(get_distro_id)" in
     ubuntu|debian) install_debian_like ;;
     fedora) install_fedora_like ;;
     *) log_error "Unsupported distro"; exit 1 ;;
   esac
   ```

4. **Use log functions for feedback**
5. **Test on multiple OS versions** if possible

### New Setup/Configuration Script
If you're adding a new setup script (e.g., `setup-ssl.sh`):

1. **Follow the structure:**
   - Source lib/common.sh
   - Define helper functions
   - Create main() function
   - Use require_sudo where needed
   - Use prompt_yes_no() for confirmations

2. **Add validation:**
   - Check prerequisites (require_cmd)
   - Validate inputs (is_valid_port, is_valid_ip)
   - Test configuration before applying

### Adding Reusable Functions to lib/common.sh
If your function could be useful in multiple scripts:

1. **Add to lib/common.sh**
2. **Document with comments**
3. **Add it to the appropriate section** (Service Management, Network Functions, etc.)
4. **Add unit tests** in tests/test-common.bats
5. **Export the function** (it's already done at the bottom)

Example:
```bash
# ============================================================================
# My New Functions
# ============================================================================

my_new_function() {
  local param="$1"
  # Implementation
  echo "$param"
}

export -f my_new_function
```

Then add test:
```bash
@test "my_new_function should return input" {
  result=$(my_new_function "test")
  [[ "$result" == "test" ]]
}
```

## Testing

### Running Tests
```bash
make test          # Run all tests
make test-common-lib   # Test library only
make test-scripts      # Test scripts
```

### Writing Tests
Use BATS (Bash Automated Testing System):

```bash
@test "description of what is being tested" {
  # Test code here
  result=$(some_function)
  [[ "$result" == "expected_value" ]]
}
```

See `tests/test-common.bats` for examples.

## Documentation

### Updating Documentation
1. Keep doc/*.md files up to date
2. Update troubleshooting.md if adding new features
3. Update CHANGELOG if it exists
4. Add comments to complex scripts/functions

### Documentation Standards
- Use clear, simple language
- Include examples where helpful
- Document assumptions and prerequisites
- Note any breaking changes

## Pull Request Process

1. **Update the README.md** if adding new features
2. **Add tests** for new functionality
3. **Run `make validate`** before submitting
4. **Write descriptive PR title and description:**
   ```
   Title: Add PostgreSQL installation script
   
   Description:
   - Adds install-postgresql.sh for PostgreSQL setup
   - Supports Ubuntu/Debian, RHEL/CentOS, openSUSE, Arch
   - Includes database initialization and user setup
   - Includes tests in test suite
   ```
5. **Link any related issues** (#123)
6. **Request review** from maintainers

## Review Criteria

PRs will be reviewed for:
- ✅ Code style consistency
- ✅ Use of common library functions
- ✅ Proper error handling
- ✅ Security considerations
- ✅ Test coverage
- ✅ Documentation
- ✅ Support for multiple distributions

## Commit Message Format

```
type: subject line (max 50 chars)

Longer explanation if needed (wrapped at 72 chars).

References:
- Relates to #issue-number
- Closes #issue-number
```

### Type Prefixes
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `test:` - Tests
- `chore:` - Build, dependencies
- `perf:` - Performance improvements
- `security:` - Security fixes

## Security Considerations

When contributing, ensure:
- [ ] No hardcoded secrets/passwords/API keys
- [ ] No unvalidated user input
- [ ] Proper use of sudo (validated requirements)
- [ ] Safe file operations (proper permissions)
- [ ] No dangerous commands (rm -rf, etc.)
- [ ] Sensitive operations have confirmations

## Need Help?

- **Questions:** Create a GitHub Discussion
- **Bugs:** Open a GitHub Issue with details
- **Features:** Propose in Discussions first
- **Documentation:** Clarify issues in PR description

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be recognized in:
- Git commit messages
- CONTRIBUTORS file (when created)
- Project releases

Thank you for contributing to VPS Starter Kit! 🚀
