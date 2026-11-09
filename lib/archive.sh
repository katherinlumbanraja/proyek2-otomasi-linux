#!/usr/bin/env bash
# lib/archive.sh - validasi path untuk backup dan restore
# Sumber backup HANYA boleh di dalam folder data/ milik repo (data simulasi).

ALLOWED_SRC_BASE="${ALLOWED_SRC_BASE:-$BASE_DIR/data}"

# validate_src <folder> -> exit 2 jika di luar data/, exit 3 jika tidak ada
validate_src() {
  local real
  [[ -n "$1" ]] || sg_die 2 "Folder sumber kosong"
  real="$(realpath -m "$1")"
  case "$real" in
    "$ALLOWED_SRC_BASE"|"$ALLOWED_SRC_BASE"/*) ;;
    *) sg_die 2 "Sumber di luar folder data simulasi: $real" ;;
  esac
  [[ -d "$real" ]] || sg_die 3 "Folder sumber tidak ditemukan: $real"
}

# validate_inside_repo <path> -> exit 2 jika di luar folder repo
validate_inside_repo() {
  local real
  [[ -n "$1" ]] || sg_die 2 "Path kosong"
  real="$(realpath -m "$1")"
  case "$real" in
    "$BASE_DIR"/*) ;;
    *) sg_die 2 "Path harus di dalam folder repo: $real" ;;
  esac
}
