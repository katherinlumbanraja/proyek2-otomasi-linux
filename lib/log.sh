#!/bin/bash
LOG_FILE="${LOG_FILE:-logs/sysinfo.log}"

_log() {
    local level="$1"; shift
    local waktu
    waktu=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$waktu] [$level] $*" | tee -a "$LOG_FILE"
}

log_info()  { _log "INFO"  "$@"; }
log_warn()  { _log "WARN"  "$@"; }
log_error() { _log "ERROR" "$@" >&2; }

# log LEVEL "pesan" - pembungkus yang dipakai bin/sysinfo.sh
log() {
  local level="${1:-INFO}"; shift
  case "$level" in
    WARN)  log_warn  "$@" ;;
    ERROR) log_error "$@" ;;
    *)     log_info  "$@" ;;
  esac
}

# die KODE "pesan" - catat error lalu keluar dengan exit status KODE
die() {
  local code="${1:-1}"; shift
  log_error "$@"
  exit "$code"
}
