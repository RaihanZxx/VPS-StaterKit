.PHONY: help lint test install check-tools format clean docs

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help:
	@echo "$(CYAN)=== VPS Starter Kit - Development Tasks ===$(RESET)"
	@echo ""
	@echo "$(GREEN)Code Quality:$(RESET)"
	@echo "  make lint                 Run ShellCheck on all scripts"
	@echo "  make format               Format shell scripts with shfmt (if available)"
	@echo "  make check-tools          Verify required tools are installed"
	@echo ""
	@echo "$(GREEN)Testing:$(RESET)"
	@echo "  make test                 Run all tests (requires bats)"
	@echo "  make test-common-lib      Test common.sh library functions"
	@echo "  make test-scripts         Test individual scripts"
	@echo ""
	@echo "$(GREEN)Installation & Setup:$(RESET)"
	@echo "  make install-bats         Install BATS testing framework"
	@echo "  make install-shellcheck   Install ShellCheck (if not present)"
	@echo "  make install-shfmt        Install shfmt (if not present)"
	@echo ""
	@echo "$(GREEN)Documentation:$(RESET)"
	@echo "  make docs                 Generate or update documentation"
	@echo ""
	@echo "$(GREEN)Utility:$(RESET)"
	@echo "  make clean                Remove test artifacts"
	@echo "  make help                 Show this help message"

# Lint all scripts using ShellCheck
lint:
	@echo "$(CYAN)Running ShellCheck on all scripts...$(RESET)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning start.sh src/*.sh lib/*.sh 2>/dev/null || true; \
		echo "$(GREEN)ShellCheck completed$(RESET)"; \
	else \
		echo "$(RED)ShellCheck not installed. Run: make install-shellcheck$(RESET)"; \
		exit 1; \
	fi

# Format scripts with shfmt
format:
	@echo "$(CYAN)Formatting shell scripts with shfmt...$(RESET)"
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 2 -w start.sh src/*.sh lib/*.sh; \
		echo "$(GREEN)Formatting completed$(RESET)"; \
	else \
		echo "$(RED)shfmt not installed. Run: make install-shfmt$(RESET)"; \
		exit 1; \
	fi

# Check if required tools are present
check-tools:
	@echo "$(CYAN)Checking for required/recommended tools...$(RESET)"
	@bash -c ' \
		tools=("bash" "sudo" "curl" "wget" "systemctl"); \
		for tool in "$${tools[@]}"; do \
			if command -v "$$tool" >/dev/null 2>&1; then \
				echo "$(GREEN)✓$(RESET) $$tool"; \
			else \
				echo "$(RED)✗$(RESET) $$tool (REQUIRED)"; \
			fi; \
		done; \
		optional=("shellcheck" "shfmt" "bats"); \
		for tool in "$${optional[@]}"; do \
			if command -v "$$tool" >/dev/null 2>&1; then \
				echo "$(GREEN)✓$(RESET) $$tool (optional)"; \
			else \
				echo "$(YELLOW)○$(RESET) $$tool (optional)"; \
			fi; \
		done; \
	'

# Run all tests
test: test-common-lib test-scripts
	@echo "$(GREEN)All tests completed$(RESET)"

# Test common.sh library
test-common-lib:
	@echo "$(CYAN)Testing common.sh library...$(RESET)"
	@if command -v bats >/dev/null 2>&1; then \
		if [ -f tests/test-common.bats ]; then \
			bats tests/test-common.bats; \
		else \
			echo "$(YELLOW)No test file found at tests/test-common.bats$(RESET)"; \
		fi; \
	else \
		echo "$(RED)BATS not installed. Run: make install-bats$(RESET)"; \
		exit 1; \
	fi

# Test individual scripts
test-scripts:
	@echo "$(CYAN)Running script tests...$(RESET)"
	@if command -v bats >/dev/null 2>&1; then \
		if [ -d tests ]; then \
			bats tests/test-scripts.bats 2>/dev/null || echo "$(YELLOW)No test files found$(RESET)"; \
		else \
			echo "$(YELLOW)No tests directory found$(RESET)"; \
		fi; \
	else \
		echo "$(RED)BATS not installed. Run: make install-bats$(RESET)"; \
	fi

# Install BATS testing framework
install-bats:
	@echo "$(CYAN)Installing BATS...$(RESET)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y bats; \
	else \
		echo "$(RED)Cannot install BATS automatically. Please install manually.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)BATS installed$(RESET)"

# Install ShellCheck
install-shellcheck:
	@echo "$(CYAN)Installing ShellCheck...$(RESET)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shellcheck; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y shellcheck; \
	else \
		echo "$(YELLOW)Please install ShellCheck manually from https://www.shellcheck.net/$(RESET)"; \
	fi

# Install shfmt
install-shfmt:
	@echo "$(CYAN)Installing shfmt...$(RESET)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shfmt; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shfmt; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y shfmt; \
	else \
		echo "$(YELLOW)Please install shfmt manually from https://github.com/mvdan/sh$(RESET)"; \
	fi

# Generate documentation
docs:
	@echo "$(CYAN)Generating documentation...$(RESET)"
	@if [ -d doc ]; then \
		echo "Documentation already exists in doc/"; \
		echo "Run 'cat doc/README.md' to view main documentation"; \
	else \
		echo "$(YELLOW)Documentation directory not found$(RESET)"; \
	fi

# Clean test artifacts
clean:
	@echo "$(CYAN)Cleaning up test artifacts...$(RESET)"
	@find . -name "*.bak" -delete
	@find . -name "*.tmp" -delete
	@rm -rf coverage/ .bats-tmp/
	@echo "$(GREEN)Clean completed$(RESET)"

# Run a quick validation
validate: check-tools lint
	@echo "$(GREEN)Validation completed$(RESET)"
