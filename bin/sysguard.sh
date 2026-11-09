#!/usr/bin/env bash
# bin/sysguard.sh - Integrasi: monitoring menentukan backup lanjut/ditolak, lalu restore + verifikasi
# Exit: 0 sukses | 20 backup DITOLAK karena monitoring gagal | selain itu: kode dari modul terkait
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"

URL="http://127.0.0.1:8080/"
THRESHOLD=90
SRC="$BASE_DIR/data"
DEST="$BASE_DIR/backups"
VERIFY_DIR="$BASE_DIR/restore/verifikasi"

usage() {
  cat <<USAGE
Pemakaian: $0 [-u url] [-t ambang] [-s sumber] [-d tujuan_backup] [-h]
Alur: check.sh -> (jika OK) backup.sh -> restore.sh ke restore/verifikasi -> verifikasi
Exit: 0 sukses | 20 backup ditolak (monitoring gagal) | kode lain dari modul terkait
USAGE
}

while getopts ":u:t:s:d:h" opt; do
  case "$opt" in
    u) URL="$OPTARG" ;;
    t) THRESHOLD="$OPTARG" ;;
    s) SRC="$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) sg_die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; sg_die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

sg_log INFO "SysGuard mulai"
mkdir -p "$DEST"

# Tahap 1: monitoring (disk yang dicek = lokasi backup)
rc=0
"$BASE_DIR/bin/check.sh" -u "$URL" -t "$THRESHOLD" -p "$DEST" 2>/dev/null || rc=$?
if (( rc != 0 )); then
  sg_log WARN "Monitoring gagal (kode $rc) -> BACKUP DITOLAK"
  exit 20
fi
sg_log INFO "Monitoring OK -> backup dilanjutkan"

# Tahap 2: backup
rc=0
ARCHIVE="$("$BASE_DIR/bin/backup.sh" -s "$SRC" -d "$DEST" 2>/dev/null)" || rc=$?
(( rc == 0 )) || sg_die "$rc" "Backup gagal (kode $rc)"

# Tahap 3: restore + verifikasi ke folder terpisah
rm -rf "$VERIFY_DIR"
rc=0
"$BASE_DIR/bin/restore.sh" -a "$ARCHIVE" -d "$VERIFY_DIR" 2>/dev/null || rc=$?
(( rc == 0 )) || sg_die "$rc" "Restore/verifikasi gagal (kode $rc)"

sg_log INFO "SysGuard selesai: backup dan restore terverifikasi ($ARCHIVE)"
exit 0
