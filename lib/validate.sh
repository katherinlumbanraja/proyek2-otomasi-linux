#!/bin/bash

validate_not_empty() {
    [[ -n "$1" ]]
}

validate_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

validate_range() {
    validate_integer "$1" && (( $1 >= $2 && $1 <= $3 ))
}

validate_file_exists() {
    [[ -f "$1" ]]
}

# validate_section NAMA - hanya all|os|cpu|mem|disk|net. Gagal: exit 2
validate_section() {
  case "${1:-}" in
    all|os|cpu|mem|disk|net) return 0 ;;
    *) die 2 "Section tidak valid: '${1:-}' (pilihan: all os cpu mem disk net)" ;;
  esac
}

# validate_outdir PATH - harus ada dan bisa ditulis. Gagal: exit 3 / 4
validate_outdir() {
  local d="${1:-}"
  [ -n "$d" ] || die 2 "Direktori output kosong"
  [ -d "$d" ] || die 3 "Direktori output tidak ditemukan: $d"
  [ -w "$d" ] || die 4 "Direktori output tidak bisa ditulis: $d"
}

# require_cmd NAMA - perintah harus tersedia. Gagal: exit 3
require_cmd() {
  command -v "${1:-}" >/dev/null 2>&1 || die 3 "Perintah wajib tidak ditemukan: ${1:-}"
}
