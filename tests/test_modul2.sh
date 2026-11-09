#!/usr/bin/env bash
# tests/test_modul2.sh - uji Modul 2 (backup.sh, restore.sh): 2 berhasil + 3 gagal
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
B="$BASE_DIR/bin/backup.sh"
R="$BASE_DIR/bin/restore.sh"
T="$BASE_DIR/backups/test-m2"
RT="$BASE_DIR/restore/test-m2"
pass=0; fail=0

check() {  # check <id> <exit_diharapkan> <perintah...>
  local id="$1" expect="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [[ $got -eq $expect ]]; then echo "PASS  $id (exit=$got)"; pass=$((pass+1))
  else echo "FAIL  $id (diharapkan=$expect, dapat=$got)"; fail=$((fail+1)); fi
}

rm -rf "$T" "$RT"; mkdir -p "$T"
check "M2-01 berhasil: backup data simulasi"        0 "$B" -d "$T"
ARCH="$(ls "$T"/*.tar.gz | head -1)"
check "M2-02 berhasil: restore + verifikasi"        0 "$R" -a "$ARCH" -d "$RT"
check "M2-03 gagal: sumber di luar data/ ditolak"   2 "$B" -s /etc -d "$T"
check "M2-04 gagal: archive tidak ditemukan"        3 "$R" -a "$T/tidak-ada.tar.gz" -d "$RT"
# simulasi archive diubah -> checksum harus mendeteksi
"$B" -d "$T" >/dev/null 2>&1
ARCH2="$(ls -t "$T"/*.tar.gz | head -1)"
echo "data-rusak" >> "$ARCH2"
check "M2-05 gagal: archive diubah (checksum beda)" 6 "$R" -a "$ARCH2" -d "$BASE_DIR/restore/test-m2b"

rm -rf "$T" "$RT" "$BASE_DIR/restore/test-m2b"
echo "Ringkasan Modul 2: $pass lulus, $fail gagal"
[[ $fail -eq 0 ]]
