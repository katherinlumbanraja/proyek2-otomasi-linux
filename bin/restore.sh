#!/usr/bin/env bash
# bin/restore.sh - Modul 2: restore archive + verifikasi checksum dan isi file
# Exit: 0 sukses | 2 input salah | 3 file tidak ditemukan | 5 ekstraksi gagal
#       6 checksum archive tidak cocok | 7 verifikasi isi file gagal
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"
source "$BASE_DIR/lib/archive.sh"

ARCHIVE=""
TARGET="$BASE_DIR/restore"

usage() {
  cat <<USAGE
Pemakaian: $0 -a file.tar.gz [-d folder_tujuan] [-h]
  -a  archive yang direstore (wajib; harus ada .sha256 dan .manifest di sebelahnya)
  -d  tujuan restore, harus di dalam repo (bawaan: restore/)
Exit: 0 sukses | 2 input salah | 3 tidak ditemukan | 5 ekstrak gagal | 6 checksum salah | 7 isi tidak cocok
USAGE
}

while getopts ":a:d:h" opt; do
  case "$opt" in
    a) ARCHIVE="$OPTARG" ;;
    d) TARGET="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) sg_die 2 "Opsi -$OPTARG butuh nilai" ;;
    *) usage; sg_die 2 "Opsi tidak dikenal: -$OPTARG" ;;
  esac
done

for c in tar sha256sum realpath; do sg_need_cmd "$c"; done
[[ -n "$ARCHIVE" ]] || { usage; sg_die 2 "Opsi -a wajib diisi"; }
[[ "$ARCHIVE" == *.tar.gz ]] || sg_die 2 "Archive harus berekstensi .tar.gz: $ARCHIVE"
validate_inside_repo "$TARGET"
ARCHIVE="$(realpath -m "$ARCHIVE")"
TARGET="$(realpath -m "$TARGET")"

BASE="${ARCHIVE%.tar.gz}"
[[ -f "$ARCHIVE" ]]            || sg_die 3 "Archive tidak ditemukan: $ARCHIVE"
[[ -f "$ARCHIVE.sha256" ]]     || sg_die 3 "File checksum tidak ditemukan: $ARCHIVE.sha256"
[[ -f "$BASE.manifest" ]]      || sg_die 3 "Manifest tidak ditemukan: $BASE.manifest"

sg_log INFO "Restore mulai. archive=$ARCHIVE target=$TARGET"

# 1) periksa integritas archive SEBELUM diekstrak
if ( cd "$(dirname "$ARCHIVE")" && sha256sum -c --quiet "$(basename "$ARCHIVE").sha256" ) >/dev/null 2>&1; then
  sg_log INFO "Checksum archive cocok"
else
  sg_die 6 "Checksum archive TIDAK cocok (archive berubah/rusak): $ARCHIVE"
fi

# 2) ekstrak
mkdir -p "$TARGET"
tar -xzf "$ARCHIVE" -C "$TARGET" || sg_die 5 "Ekstraksi gagal"

# 3) verifikasi isi file hasil restore terhadap manifest
if ( cd "$TARGET" && sha256sum -c --quiet "$BASE.manifest" ) >/dev/null 2>&1; then
  sg_log INFO "Verifikasi isi file OK: semua file sama dengan manifest"
else
  sg_die 7 "Verifikasi isi file GAGAL: ada file berbeda/hilang"
fi

sg_log INFO "Restore sukses: $TARGET"
exit 0
