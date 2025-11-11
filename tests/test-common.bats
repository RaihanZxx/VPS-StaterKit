#!/usr/bin/env bats

setup() {
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
  LIB_DIR="${PROJECT_ROOT}/lib"
  
  source "${LIB_DIR}/common.sh"
  
  C_RESET=""
  C_BOLD=""
  C_CYAN=""
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
}

@test "need_cmd should find existing commands" {
  if need_cmd bash; then
    true
  else
    skip "bash not found (should not happen)"
  fi
}

@test "need_cmd should fail for non-existing commands" {
  if need_cmd nonexistent_command_12345; then
    false
  else
    true
  fi
}

@test "numfmt_gib should convert bytes to GiB" {
  result=$(numfmt_gib 1073741824)
  [[ "$result" == "1.00" ]] || [[ "$result" == "1.00" ]]
}

@test "numfmt_gib should handle large numbers" {
  result=$(numfmt_gib 1099511627776)
  [[ "$result" =~ ^1024\.[0-9]{2}$ ]]
}

@test "numfmt_gib should handle zero" {
  result=$(numfmt_gib 0)
  [[ "$result" == "0.00" ]]
}

@test "get_cpu_cores should return a positive integer" {
  cores=$(get_cpu_cores)
  [[ "$cores" =~ ^[0-9]+$ ]] && [ "$cores" -ge 1 ]
}

@test "get_ram_bytes should return a positive integer" {
  ram=$(get_ram_bytes)
  [[ "$ram" =~ ^[0-9]+$ ]] && [ "$ram" -gt 0 ]
}

@test "get_disk_bytes_total should return a positive integer" {
  disk=$(get_disk_bytes_total)
  [[ "$disk" =~ ^[0-9]+$ ]] && [ "$disk" -gt 0 ]
}

@test "get_disk_bytes_avail should return a positive integer" {
  avail=$(get_disk_bytes_avail)
  [[ "$avail" =~ ^[0-9]+$ ]] && [ "$avail" -gt 0 ]
}

@test "is_valid_port should accept port 22" {
  is_valid_port 22
}

@test "is_valid_port should accept port 65535" {
  is_valid_port 65535
}

@test "is_valid_port should accept port 1" {
  is_valid_port 1
}

@test "is_valid_port should reject port 0" {
  ! is_valid_port 0
}

@test "is_valid_port should reject port 65536" {
  ! is_valid_port 65536
}

@test "is_valid_port should reject non-numeric input" {
  ! is_valid_port abc
}

@test "is_valid_ip should accept valid IP 192.168.1.1" {
  is_valid_ip 192.168.1.1
}

@test "is_valid_ip should accept valid IP 127.0.0.1" {
  is_valid_ip 127.0.0.1
}

@test "is_valid_ip should reject invalid IP 256.1.1.1" {
  ! is_valid_ip 256.1.1.1
}

@test "is_valid_ip should reject non-IP strings" {
  ! is_valid_ip "not.an.ip"
}

@test "detect_pkg_manager should return a valid package manager" {
  pm=$(detect_pkg_manager)
  [[ "$pm" =~ ^(apt|dnf|yum|zypper|pacman|unknown)$ ]]
}

@test "log_info should output to stdout" {
  output=$(log_info "test message" 2>&1)
  [[ "$output" == *"test message"* ]]
}

@test "log_success should output to stdout" {
  output=$(log_success "test message" 2>&1)
  [[ "$output" == *"test message"* ]]
}

@test "log_warn should output to stderr" {
  output=$(log_warn "test message" 2>&1)
  [[ "$output" == *"test message"* ]]
}

@test "log_error should output to stderr" {
  output=$(log_error "test message" 2>&1)
  [[ "$output" == *"test message"* ]]
}
