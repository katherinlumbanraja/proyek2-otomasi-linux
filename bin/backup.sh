#!/usr/bin/env bash
# bin/backup.sh - Modul 2: backup data simulasi + checksum + manifest
# Exit: 0 sukses | 2 input salah | 3 tidak ditemukan | 4 tujuan tidak bisa ditulis | 5 backup gagal
# Stdout: path file archive (untuk dipakai script lain). Log ke stderr.
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"
source "$BASE_DIR/lib/archive.sh"

SRC="$BASE_DIR/data"
DEST="$BASE_DIR/backups"

usage() {
  cat <<USAGE
Pemakaian: $0 [-s folder_sumber] [-d folder_tujuan] [-h]
  -s  sumber, harus di dalam data/ (bawaan: data/)
  -d  tujuan backup, harus di dalam repo (bawaan: backups/)
Exit: 0 sukses | 2 input salah | 3 tidak ditemukan | 4 tujuan tidak bisa ditulis | 5 gagal
USAGE
}

while getopts ":s:d:h" opt; do
  case "$opt" in
    s) SRC="$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) sg_die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; sg_die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

for c in tar sha256sum find sort xargs realpath; do sg_need_cmd "$c"; done
validate_src "$SRC"
validate_inside_repo "$DEST"
SRC="$(realpath -m "$SRC")"
DEST="$(realpath -m "$DEST")"

mkdir -p "$DEST" 2>/dev/null || sg_die 4 "Tidak bisa membuat folder tujuan: $DEST"
[[ -w "$DEST" ]] || sg_die 4 "Folder tujuan tidak bisa ditulis: $DEST"

FILE_COUNT="$(find "$SRC" -type f | wc -l)"
(( FILE_COUNT > 0 )) || sg_die 2 "Sumber tidak berisi file: $SRC"

NAME="backup_$(date +%Y%m%d_%H%M%S)_$$"
ARCHIVE="$DEST/$NAME.tar.gz"
sg_log INFO "Backup mulai. sumber=$SRC file=$FILE_COUNT tujuan=$ARCHIVE"

tar -czf "$ARCHIVE" -C "$SRC" . || { rm -f "$ARCHIVE"; sg_die 5 "tar gagal membuat archive"; }

# manifest: checksum tiap file (untuk verifikasi hasil restore)
( cd "$SRC" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) > "$DEST/$NAME.manifest" \
  || sg_die 5 "Gagal membuat manifest"
# checksum archive (untuk mendeteksi perubahan pada archive)
( cd "$DEST" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256" ) \
  || sg_die 5 "Gagal membuat checksum archive"

sg_log INFO "Backup sukses: $ARCHIVE"
echo "$ARCHIVE"
exit 0
