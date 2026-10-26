#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
source lib/log.sh
source lib/validate.sh

LOG_FILE="logs/test.log"
LULUS=0
GAGAL=0

cek() {
    local nama="$1"; shift
    if "$@"; then echo "LULUS: $nama"; ((LULUS++))
    else echo "GAGAL: $nama"; ((GAGAL++)); fi
}

cek_gagal() {
    local nama="$1"; shift
    if "$@"; then echo "GAGAL: $nama"; ((GAGAL++))
    else echo "LULUS: $nama"; ((LULUS++)); fi
}

cek       "integer valid"         validate_integer 42
cek_gagal "integer huruf ditolak" validate_integer abc
cek       "range dalam batas"     validate_range 5 1 10
cek_gagal "range di luar batas"   validate_range 50 1 10
cek_gagal "string kosong ditolak" validate_not_empty ""
cek       "file ada"              validate_file_exists lib/log.sh
cek_gagal "file tidak ada"        validate_file_exists tidak_ada.txt

log_info "Tes selesai: $LULUS lulus, $GAGAL gagal"
echo "Total: $LULUS lulus, $GAGAL gagal"
[[ $GAGAL -eq 0 ]]
