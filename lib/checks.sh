#!/usr/bin/env bash
# lib/checks.sh - fungsi pemeriksaan layanan dan kapasitas disk

# check_service_http <url> [timeout_detik] -> sukses jika HTTP 200
check_service_http() {
  local url="$1" to="${2:-3}" code
  code="$(curl -s -o /dev/null -m "$to" -w '%{http_code}' "$url" || true)"
  [[ "$code" == "200" ]]
}

# disk_usage_pct <path> -> cetak persentase pemakaian (angka saja)
disk_usage_pct() {
  df -P "$1" | awk 'NR==2 {gsub("%","",$5); print $5}'
}

# check_disk_below <path> <batas_persen> -> sukses jika pemakaian < batas
check_disk_below() {
  local usage
  usage="$(disk_usage_pct "$1")"
  [[ -n "$usage" && "$usage" -lt "$2" ]]
}
