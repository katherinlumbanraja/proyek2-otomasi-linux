#!/usr/bin/env bash
# docker/run.sh - build image, lalu jalankan (atau buat ulang) container dengan limit CPU/memori
# Exit: 0 sukses | 3 docker tidak ada | 9 build/run gagal
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$BASE_DIR/lib/common.sh"

IMAGE="sysguard-svc:1.0"
NAME="sysguard-svc"
NET="sysguard-net"
PORT="8080"

sg_need_cmd docker
mkdir -p "$BASE_DIR/data"

sg_log INFO "Build image $IMAGE"
docker build -t "$IMAGE" "$BASE_DIR/docker" >/dev/null || sg_die 9 "docker build gagal"

docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET" >/dev/null

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  sg_log INFO "Container lama ditemukan, dihapus dulu (data di data/ tidak ikut terhapus)"
  docker rm -f "$NAME" >/dev/null
fi

sg_log INFO "Run container $NAME (cpu 0.5, memori 128m, port 127.0.0.1:$PORT)"
docker run -d --name "$NAME" --network "$NET" \
  --cpus 0.5 --memory 128m \
  --cap-drop ALL --security-opt no-new-privileges \
  -p "127.0.0.1:$PORT:8080" \
  -v "$BASE_DIR/data:/usr/share/nginx/html/data:ro" \
  "$IMAGE" >/dev/null || sg_die 9 "docker run gagal"

sg_log INFO "Menunggu layanan siap (maks 20 detik)"
for _ in $(seq 1 20); do
  if curl -s -o /dev/null -m 2 "http://127.0.0.1:$PORT/"; then
    sg_log INFO "Container berjalan dan layanan merespons: http://127.0.0.1:$PORT/"
    exit 0
  fi
  sleep 1
done
docker logs --tail 20 "$NAME" >&2 || true
sg_die 9 "Layanan tidak merespons setelah 20 detik"
exit 0
