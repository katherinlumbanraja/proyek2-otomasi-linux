#!/usr/bin/env bash
# tests/test_modul1.sh - uji Modul 1 (check.sh): 1 berhasil + 3 gagal
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
C="$BASE_DIR/bin/check.sh"
PORT=18080
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

check "M1-01 berhasil: layanan hidup, disk di bawah ambang" 0  "$C" -u "http://127.0.0.1:$PORT/" -t 100
check "M1-02 gagal: layanan mati"                           10 "$C" -u "http://127.0.0.1:18999/"
check "M1-03 gagal: disk melewati ambang (-t 1)"            11 "$C" -u "http://127.0.0.1:$PORT/" -t 1
check "M1-04 gagal: ambang bukan angka"                     2  "$C" -u "http://127.0.0.1:$PORT/" -t abc

echo "Ringkasan Modul 1: $pass lulus, $fail gagal"
[[ $fail -eq 0 ]]
