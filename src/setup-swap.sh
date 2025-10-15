#!/usr/bin/env bash
set -euo pipefail

# Colors
if [ -t 1 ]; then
  C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m";
  C_CYAN="\033[36m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_MAGENTA="\033[35m"; C_WHITE="\033[97m"; C_RED="\033[31m"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_MAGENTA=""; C_WHITE=""; C_RED=""
fi

numfmt_gib() { awk -v b="$1" 'BEGIN {printf "%.2f", b/1024/1024/1024}'; }
round() { awk -v x="$1" 'BEGIN {printf "%d", (x<0)?int(x-0.5):int(x+0.5)}'; }

get_ram_gib() { awk '/MemTotal/ {printf "%.2f", $2/1024/1024}' /proc/meminfo; }
get_cpu_model() { awk -F: '/model name/ {gsub(/^ +/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown"; }
get_cpu_cores() { nproc 2>/dev/null || echo 1; }
get_disk_bytes_total() { df -B1 --output=size / | tail -1 | tr -d ' '; }
get_disk_bytes_avail() { df -B1 --output=avail / | tail -1 | tr -d ' '; }

recommend_swap_gib() {
  local ram_gib="$1"
  local avail_gib="$2"
  local rec
  if awk -v r="$ram_gib" 'BEGIN{exit !(r<=2)}'; then
    rec=$(awk -v r="$ram_gib" 'BEGIN{printf "%.0f", r*2}')
  elif awk -v r="$ram_gib" 'BEGIN{exit !(r<=8)}'; then
    rec=$(awk -v r="$ram_gib" 'BEGIN{printf "%.0f", r}')
  elif awk -v r="$ram_gib" 'BEGIN{exit !(r<=64)}'; then
    rec=$(awk -v r="$ram_gib" 'BEGIN{printf "%.0f", r/2}')
  else
    rec=$(awk -v r="$ram_gib" 'BEGIN{printf "%.0f", r/4}')
  fi
  # Limit by available disk minus 1 GiB buffer
  local avail_int=$(round "$(awk -v a="$avail_gib" 'BEGIN{print (a-1)}')")
  if [ "$avail_int" -lt 1 ]; then echo 0; return; fi
  if [ "$rec" -gt "$avail_int" ]; then echo "$avail_int"; else echo "$rec"; fi
}

print_dashboard() {
  local cpu_model="$1" cpu_cores="$2" ram_gib="$3" disk_total_gib="$4" disk_avail_gib="$5" rec_swap_gib="$6"
  echo -e "${C_BOLD}${C_CYAN}=== VPS SPECIFICATION ===${C_RESET}"
  printf "%b%-18s%b %b%s%b\n" "$C_WHITE" "CPU Model:" "$C_RESET" "$C_GREEN" "$cpu_model" "$C_RESET"
  printf "%b%-18s%b %b%s cores%b\n" "$C_WHITE" "CPU Cores:" "$C_RESET" "$C_GREEN" "$cpu_cores" "$C_RESET"
  printf "%b%-18s%b %b%s GiB%b\n" "$C_WHITE" "RAM Total:" "$C_RESET" "$C_GREEN" "$ram_gib" "$C_RESET"
  printf "%b%-18s%b %b%s GiB%b\n" "$C_WHITE" "Disk Total (/):" "$C_RESET" "$C_GREEN" "$disk_total_gib" "$C_RESET"
  printf "%b%-18s%b %b%s GiB%b\n" "$C_WHITE" "Disk Avail (/):" "$C_RESET" "$C_GREEN" "$disk_avail_gib" "$C_RESET"
  echo -e "${C_YELLOW}Recommended swap size: ${C_BOLD}${rec_swap_gib} GiB${C_RESET}"
}

main() {
  local ram_gib cpu_model cpu_cores disk_total_bytes disk_avail_bytes disk_total_gib disk_avail_gib rec_swap_gib

  ram_gib=$(get_ram_gib)
  cpu_model=$(get_cpu_model)
  cpu_cores=$(get_cpu_cores)
  disk_total_bytes=$(get_disk_bytes_total)
  disk_avail_bytes=$(get_disk_bytes_avail)
  disk_total_gib=$(numfmt_gib "$disk_total_bytes")
  disk_avail_gib=$(numfmt_gib "$disk_avail_bytes")

  # integerish ram for recommendation math
  local ram_gib_int=$(round "$ram_gib")
  rec_swap_gib=$(recommend_swap_gib "$ram_gib_int" "$(printf '%.0f' "$disk_avail_gib")")

  print_dashboard "$cpu_model" "$cpu_cores" "$ram_gib" "$disk_total_gib" "$disk_avail_gib" "$rec_swap_gib"

  if [ "$rec_swap_gib" -eq 0 ]; then
    echo -e "${C_RED}Insufficient free disk space for swap recommendation.${C_RESET}" >&2
  fi

  echo
  read -r -p "Enter desired swap file size in GiB [default ${rec_swap_gib}]: " input_size || true
  input_size=${input_size:-$rec_swap_gib}

  if ! echo "$input_size" | grep -Eq '^[0-9]+$'; then
    echo -e "${C_RED}Invalid input. Please enter an integer GiB value.${C_RESET}" >&2
    exit 1
  fi

  local max_allowed=$(round "$(awk -v a="$disk_avail_gib" 'BEGIN{print (a-1)}')")
  if [ "$input_size" -gt "$max_allowed" ]; then
    echo -e "${C_RED}Requested size exceeds available disk space (max ${max_allowed} GiB).${C_RESET}" >&2
    exit 1
  fi

  echo -e "${C_MAGENTA}Selected swap size: ${C_BOLD}${input_size} GiB${C_RESET}"
  echo "You can now proceed to create the swap file with your chosen size."
}

main "$@"
