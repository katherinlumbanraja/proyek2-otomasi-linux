#!/usr/bin/env bash
# bin/send_backup.sh - kirim backup lewat SCP
# Exit: 0 sukses | 2 input salah | 3 file/command tidak ada | 8 SCP gagal
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"

FILE=""
TARGET=""

usage() {
  echo "Pemakaian: $0 -f archive.tar.gz -t user@host:/folder/tujuan [-h]"
  echo "Exit: 0 sukses | 2 input salah | 3 file/command tidak ada | 8 SCP gagal"
}

while getopts ":f:t:h" opt; do
  case "$opt" in
    f) FILE="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) sg_die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; sg_die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

sg_need_cmd scp
[[ -n "$FILE" && -n "$TARGET" ]] || { usage; sg_die 2 "Opsi -f dan -t wajib diisi"; }
[[ "$FILE" == *.tar.gz ]] || sg_die 2 "File harus .tar.gz: $FILE"
[[ "$TARGET" =~ ^[a-z_][a-z0-9_-]*@[A-Za-z0-9.-]+:/[A-Za-z0-9._/-]+$ ]] \
  || sg_die 2 "Format tujuan salah (user@host:/folder): '$TARGET'"
BASE="${FILE%.tar.gz}"
for f in "$FILE" "$FILE.sha256" "$BASE.manifest"; do
  [[ -f "$f" ]] || sg_die 3 "File tidak ditemukan: $f"
done

sg_log INFO "Kirim via SCP: $FILE -> $TARGET"
if scp -q -o BatchMode=yes -o ConnectTimeout=5 "$FILE" "$FILE.sha256" "$BASE.manifest" "$TARGET"; then
  sg_log INFO "SCP sukses"
else
  sg_die 8 "SCP gagal (akses ditolak, kunci salah, atau jaringan): $TARGET"
fi
exit 0
