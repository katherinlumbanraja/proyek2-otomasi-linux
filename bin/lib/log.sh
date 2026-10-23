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
