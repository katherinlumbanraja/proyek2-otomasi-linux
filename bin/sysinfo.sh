#!/usr/bin/env bash
# bin/sysinfo.sh - Otomasi pengumpulan informasi sistem Linux
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/log.sh"
source "$BASE_DIR/lib/validate.sh"
source "$BASE_DIR/lib/collect.sh"

OUT_DIR="$BASE_DIR/output"
SECTION="all"

usage() {
  cat <<USAGE
Pemakaian: $0 [-o folder_output] [-s all|os|cpu|mem|disk|net] [-h]
Exit code: 0 sukses | 1 gagal umum | 2 argumen salah | 3 command tidak ada | 4 output gagal
USAGE
}

while getopts ":o:s:h" opt; do
  case "$opt" in
    o) OUT_DIR="$OPTARG" ;;
    s) SECTION="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

log INFO "Mulai. section=$SECTION outdir=$OUT_DIR"
validate_section "$SECTION"
for c in uname hostname free df nproc; do require_cmd "$c"; done
validate_outdir "$OUT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$OUT_DIR/sysinfo_${TS}.txt"
TMP_FILE="$(mktemp "$OUT_DIR/.tmp.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

{
  echo "Laporan sistem - $(date '+%F %T')"
  for s in os cpu mem disk net; do
    if [[ "$SECTION" == "all" || "$SECTION" == "$s" ]]; then
      "section_$s"; echo
    fi
  done
} > "$TMP_FILE" || die 1 "Gagal mengumpulkan informasi"

mv "$TMP_FILE" "$OUT_FILE"   # tulis ke temp dulu agar tidak ada file setengah jadi
log INFO "Sukses. Laporan: $OUT_FILE"
exit 0
