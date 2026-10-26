#!/usr/bin/env bash
# lib/collect.sh - pengumpulan informasi sistem (hanya membaca, tidak mengubah sistem)
# Di-source oleh bin/sysinfo.sh. Setiap fungsi section_* mencetak ke stdout.

section_os() {
  echo "== OS =="
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    ( . /etc/os-release; echo "Distribusi : ${PRETTY_NAME:-tidak diketahui}" )
  else
    echo "Distribusi : tidak diketahui"
  fi
  echo "Hostname   : $(hostname)"
  echo "Kernel     : $(uname -r)"
  echo "Arsitektur : $(uname -m)"
  echo "Uptime     : $(uptime -p 2>/dev/null || echo tidak-tersedia)"
}

section_cpu() {
  echo "== CPU =="
  local model=""
  if [ -r /proc/cpuinfo ]; then
    model="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
  fi
  echo "Model      : ${model:-tidak diketahui}"
  echo "Jumlah core: $(nproc)"
  if [ -r /proc/loadavg ]; then
    echo "Load avg   : $(cut -d' ' -f1-3 /proc/loadavg)"
  fi
}

section_mem() {
  echo "== Memori =="
  free -h
}

section_disk() {
  echo "== Disk =="
  df -h -x tmpfs -x devtmpfs
}

section_net() {
  echo "== Jaringan =="
  if command -v ip >/dev/null 2>&1; then
    ip -brief address
  else
    echo "Alamat IP  : $(hostname -I 2>/dev/null || echo tidak-tersedia)"
  fi
}
