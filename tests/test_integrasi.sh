#!/usr/bin/env bash
# tests/test_integrasi.sh - uji integrasi Modul 1 + Modul 2 (sysguard.sh)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$BASE_DIR/bin/sysguard.sh"
T="$BASE_DIR/backups/test-int"
PORT=18081
pass=0; fail=0

check() {  # check <id> <exit_diharapkan> <perintah...>
  local id="$1" expect="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [[ $got -eq $expect ]]; then echo "PASS  $id (exit=$got)"; pass=$((pass+1))
  else echo "FAIL  $id (diharapkan=$expect, dapat=$got)"; fail=$((fail+1)); fi
}

SRVDIR="$(mktemp -d)"; echo ok > "$SRVDIR/index.html"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SRVDIR" >/dev/null 2>&1 &
SRV_PID=$!
trap 'kill $SRV_PID 2>/dev/null; rm -rf "$SRVDIR"' EXIT
sleep 1
rm -rf "$T"; mkdir -p "$T"

# INT-01: layanan hidup -> backup jalan -> restore terverifikasi
check "INT-01 berhasil: monitoring OK, backup dan restore terverifikasi" 0 "$S" -u "http://127.0.0.1:$PORT/" -t 100 -d "$T"
N1="$(ls "$T"/*.tar.gz 2>/dev/null | wc -l)"
[[ -f "$BASE_DIR/restore/verifikasi/catatan.txt" ]] \
  && { echo "PASS  INT-01b file hasil restore ada"; pass=$((pass+1)); } \
  || { echo "FAIL  INT-01b file hasil restore tidak ada"; fail=$((fail+1)); }

# INT-02: layanan mati -> backup HARUS ditolak (exit 20) dan tidak ada backup baru
check "INT-02 gagal: layanan mati, backup ditolak (exit 20)" 20 "$S" -u "http://127.0.0.1:18999/" -d "$T"
N2="$(ls "$T"/*.tar.gz 2>/dev/null | wc -l)"
[[ "$N1" == "$N2" ]] \
  && { echo "PASS  INT-02b tidak ada backup baru saat ditolak ($N1 -> $N2)"; pass=$((pass+1)); } \
  || { echo "FAIL  INT-02b backup bertambah saat seharusnya ditolak ($N1 -> $N2)"; fail=$((fail+1)); }

rm -rf "$T" "$BASE_DIR/restore/verifikasi"
echo "Ringkasan integrasi: $pass lulus, $fail gagal"
[[ $fail -eq 0 ]]
