#!/usr/bin/env bash
# docker/stop.sh - hentikan container (opsi -r: hapus juga container dan network)
set -euo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"
sg_need_cmd docker
NAME="sysguard-svc"; NET="sysguard-net"
docker stop "$NAME" >/dev/null 2>&1 && sg_log INFO "Container dihentikan: $NAME" || sg_log WARN "Container tidak berjalan: $NAME"
if [[ "${1:-}" == "-r" ]]; then
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
  sg_log INFO "Container dan network dihapus (folder data/ tetap ada)"
fi
exit 0
