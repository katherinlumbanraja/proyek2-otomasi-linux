#!/usr/bin/env bash
# bin/check.sh - Modul 1: monitoring layanan dan kapasitas disk
# Exit: 0 OK | 2 input tidak valid | 3 command/direktori tidak ada
#       10 layanan tidak merespons | 11 disk melewati ambang
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"
source "$BASE_DIR/lib/checks.sh"

URL="http://127.0.0.1:8080/"
CHECK_PATH="$BASE_DIR"
THRESHOLD=90

usage() {
  cat <<USAGE
Pemakaian: $0 [-u url] [-p path] [-t ambang_persen] [-h]
  -u  URL layanan yang dicek (bawaan: $URL)
  -p  folder untuk cek kapasitas disk (bawaan: folder repo)
  -t  ambang pemakaian disk 1-100 (bawaan: $THRESHOLD)
Exit: 0 OK | 2 input salah | 3 command/folder tidak ada | 10 layanan mati | 11 disk penuh
USAGE
}

while getopts ":u:p:t:h" opt; do
  case "$opt" in
    u) URL="$OPTARG" ;;
    p) CHECK_PATH="$OPTARG" ;;
    t) THRESHOLD="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) sg_die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; sg_die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

for c in curl df awk; do sg_need_cmd "$c"; done
[[ "$URL" =~ ^https?://[A-Za-z0-9._:/?=%-]+$ ]] || sg_die 2 "URL tidak valid: '$URL'"
[[ "$THRESHOLD" =~ ^[0-9]+$ ]] && (( THRESHOLD >= 1 && THRESHOLD <= 100 )) \
  || sg_die 2 "Ambang harus angka 1-100, dapat: '$THRESHOLD'"
[[ -d "$CHECK_PATH" ]] || sg_die 3 "Folder tidak ditemukan: $CHECK_PATH"

sg_log INFO "Cek mulai. url=$URL path=$CHECK_PATH ambang=${THRESHOLD}%"

if check_service_http "$URL"; then
  sg_log INFO "Layanan OK (HTTP 200): $URL"
else
  sg_die 10 "Layanan tidak merespons HTTP 200: $URL"
fi

USAGE_PCT="$(disk_usage_pct "$CHECK_PATH")"
if check_disk_below "$CHECK_PATH" "$THRESHOLD"; then
  sg_log INFO "Disk OK: ${USAGE_PCT}% < ${THRESHOLD}%"
else
  sg_die 11 "Disk melewati ambang: ${USAGE_PCT}% >= ${THRESHOLD}%"
fi

sg_log INFO "Cek selesai: SEMUA OK"
exit 0
