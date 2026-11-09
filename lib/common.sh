#!/usr/bin/env bash
# lib/common.sh - log dan die untuk modul SysGuard (v2)
# Butuh variabel BASE_DIR (diisi oleh script yang memanggil).

SG_LOG_FILE="${SG_LOG_FILE:-$BASE_DIR/logs/sysguard.log}"

# sg_log <LEVEL> <pesan...>  -> ke file log dan layar (stderr)
sg_log() {
  local level="$1"; shift
  mkdir -p "$(dirname "$SG_LOG_FILE")"
  local line
  line="[$(date '+%F %T')] [$level] $*"
  echo "$line" >> "$SG_LOG_FILE"
  echo "$line" >&2
}

# sg_die <exit_code> <pesan...> -> catat ERROR lalu keluar
sg_die() {
  local code="$1"; shift
  sg_log ERROR "$* (exit=$code)"
  exit "$code"
}

# sg_need_cmd <perintah> -> exit 3 jika tidak ada
sg_need_cmd() {
  command -v "$1" >/dev/null 2>&1 || sg_die 3 "Command wajib tidak ditemukan: $1"
}
