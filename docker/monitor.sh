#!/usr/bin/env bash
# docker/monitor.sh - periksa resource limit dan tampilkan monitoring container
# Exit: 0 sukses | 3 docker/container tidak ada
set -euo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"
sg_need_cmd docker
NAME="sysguard-svc"
docker ps --format '{{.Names}}' | grep -qx "$NAME" || sg_die 3 "Container tidak berjalan: $NAME"

echo "== Limit terpasang (NanoCpus: 500000000 = 0.5 CPU, Memory dalam byte) =="
docker inspect "$NAME" --format 'NanoCpus={{.HostConfig.NanoCpus}} Memory={{.HostConfig.Memory}} Privileged={{.HostConfig.Privileged}}'
echo "== Pemakaian resource saat ini =="
docker stats --no-stream "$NAME"
echo "== Log container (20 baris terakhir) =="
docker logs --tail 20 "$NAME" 2>&1
echo "== Network =="
docker inspect "$NAME" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{end}}'
sg_log INFO "Monitoring container dicatat"
exit 0
