# Proyek 2: Otomasi dan Container Linux - sysinfo

## Use case dan tujuan

`sysinfo.sh` adalah modul otomasi administrasi Linux untuk mengumpulkan informasi sistem
(OS, CPU, memori, disk, jaringan) dan menyimpannya sebagai laporan teks bertimestamp.

Tujuannya: administrator mendapat gambaran kondisi sistem dengan satu perintah yang aman
(hanya membaca, tidak mengubah sistem), tercatat di log, dan mudah dikembangkan pada
tahap berikutnya (P12-P15).

## Struktur repositori

| Path | Fungsi |
|---|---|
| `bin/sysinfo.sh` | Program utama (parsing opsi dengan `getopts`, alur, exit status) |
| `lib/log.sh` | Pencatatan log berlevel (INFO/WARN/ERROR), fungsi `log` dan `die` |
| `lib/validate.sh` | Validasi input dan prasyarat: `validate_section`, `validate_outdir`, `require_cmd`, dan pemeriksaan umum |
| `lib/collect.sh` | Pengumpulan data: `section_os`, `section_cpu`, `section_mem`, `section_disk`, `section_net` |
| `tests/run_tests.sh` | Pengujian fungsi validasi (7 kasus) |
| `config/` | Contoh konfigurasi tanpa credential |
| `docs/` | Hasil uji dan contoh log |
| `output/` | Folder laporan bawaan (dibuat saat dijalankan, tidak di-commit) |
| `logs/` | File log (dibuat saat dijalankan, tidak di-commit) |
| `KONTRIBUSI.md` | Catatan kontribusi anggota |

## Prasyarat

Ubuntu/Linux dengan bash dan perintah `uname`, `hostname`, `free`, `df`, `nproc`,
serta `date`, `tee`, `grep`, `cut`, dan `sed`.

Perintah `ip` bersifat opsional: bila tidak ada, section `net` memakai `hostname -I`.
Perintah `uptime -p` juga punya cadangan (tertulis `tidak-tersedia` bila gagal).

## Cara menjalankan

Jalankan dari **direktori utama repositori**, karena lokasi log bawaan (`logs/sysinfo.log`)
relatif terhadap direktori tempat perintah dijalankan.

```bash
git clone https://github.com/katherinlumbanraja/proyek2-otomasi-linux.git
cd proyek2-otomasi-linux
mkdir -p /tmp/out
bash bin/sysinfo.sh -o /tmp/out -s all
```

Opsi:

- `-o DIR` : direktori output (harus ada dan bisa ditulis). Bawaan: `output/` di dalam repositori
- `-s SECTION` : `all` (bawaan), `os`, `cpu`, `mem`, `disk`, atau `net`
- `-h` : tampilkan bantuan

Isi setiap section:

| Section | Informasi yang dikumpulkan |
|---|---|
| `os` | distribusi, hostname, versi kernel, arsitektur, uptime |
| `cpu` | model, jumlah core, load average |
| `mem` | penggunaan RAM dan swap (`free -h`) |
| `disk` | penggunaan disk per filesystem, tanpa tmpfs/devtmpfs (`df -h`) |
| `net` | antarmuka dan alamat IP (`ip -brief address`) |

Laporan ditulis ke file sementara terlebih dahulu, lalu dipindahkan ke file akhir, sehingga
tidak ada laporan setengah jadi bila proses gagal di tengah jalan.

## Cara memverifikasi

```bash
bash bin/sysinfo.sh -o /tmp/out -s all
echo $?                      # harus 0 (jalankan tepat setelah perintah di atas)
ls /tmp/out/sysinfo_*.txt    # laporan terbentuk
cat /tmp/out/sysinfo_*.txt   # isi laporan sesuai section
cat logs/sysinfo.log         # ada catatan "Sukses. Laporan: ..."
bash tests/run_tests.sh      # semua tes lulus
```

Nilai di laporan dapat dibandingkan dengan perintah manual seperti `free -h`, `df -h`, dan `uname -r`.

## Exit status

| Kode | Arti |
|---|---|
| 0 | Sukses |
| 1 | Gagal mengumpulkan informasi |
| 2 | Opsi atau input tidak valid |
| 3 | Direktori atau perintah wajib tidak ditemukan |
| 4 | Direktori output tidak bisa ditulis |

Contoh kondisi gagal:

```bash
bash bin/sysinfo.sh -s xyz                 # exit 2 (section tidak valid)
bash bin/sysinfo.sh -o /folder/tidak/ada   # exit 3 (direktori tidak ditemukan)
bash bin/sysinfo.sh -o                     # exit 2 (opsi -o butuh nilai)
```

## Pengujian

### 1. Pengujian fungsi validasi (`tests/run_tests.sh`)

Hasil aktual yang dijalankan di VM: **7 lulus, 0 gagal**.

| No | Kasus | Jenis |
|---|---|---|
| 1 | integer valid | berhasil |
| 2 | integer huruf ditolak | gagal (ditolak) |
| 3 | range dalam batas | berhasil |
| 4 | range di luar batas | gagal (ditolak) |
| 5 | string kosong ditolak | gagal (ditolak) |
| 6 | file ada | berhasil |
| 7 | file tidak ada | gagal (ditolak) |

### 2. Pengujian program utama (`bin/sysinfo.sh`)

| No | Kasus | Perintah | Harapan |
|---|---|---|---|
| A | Berhasil | `bash bin/sysinfo.sh -o /tmp/out -s all` | exit 0, laporan terbentuk, log INFO |
| B | Gagal: section tidak valid | `bash bin/sysinfo.sh -s xyz` | exit 2, log ERROR |
| C | Gagal: direktori tidak ada | `bash bin/sysinfo.sh -o /folder/tidak/ada` | exit 3, log ERROR |
| D | Gagal: opsi tanpa nilai | `bash bin/sysinfo.sh -o` | exit 2, log ERROR |

Hasil aktual kasus A-D dicatat di `docs/` setelah benar-benar dijalankan
(lihat contoh pada bagian Log).

## Log

Setiap aktivitas (mulai, sukses, peringatan, error) dicatat dengan timestamp dan level
(`INFO`, `WARN`, `ERROR`), ditampilkan di layar dan ditambahkan ke file log.
Lokasi log diatur lewat variabel `LOG_FILE` (bawaan: `logs/sysinfo.log`):

```bash
LOG_FILE=/tmp/sysinfo.log bash bin/sysinfo.sh -o /tmp/out -s all
```

Format satu baris log:

```
[2026-10-26 13:11:52] [INFO] Tes selesai: 7 lulus, 0 gagal
```

## Konfigurasi

Contoh konfigurasi ada di `config/` dan tidak berisi credential. Jangan menyimpan
password, token, private key, atau data pribadi di repositori.

## Keamanan

- Script hanya membaca informasi sistem dan menulis laporan serta log; konfigurasi sistem tidak diubah.
- Opsi `-s` dan `-o` divalidasi sebelum dipakai.
- Laporan section `net` memuat alamat IP. Sanitasi laporan dan log sebelum dibagikan atau dilampirkan.

## Pembersihan

Script hanya menulis laporan ke direktori output dan log ke `logs/`. Hapus hasilnya dengan:

```bash
rm -f /tmp/out/sysinfo_*.txt
rm -f output/sysinfo_*.txt
rm -f logs/sysinfo.log
```

## Rollback

Script tidak mengubah konfigurasi sistem, sehingga rollback cukup menghapus laporan dan log
(lihat Pembersihan). Untuk mengembalikan kode ke versi bertag:

```bash
git fetch --tags
git checkout P2-CHECKPOINT-P11-v01
```

## Kontribusi

Pembagian tugas anggota ada di [KONTRIBUSI.md](KONTRIBUSI.md).

## Batasan

- Keluaran baru berupa teks.
- Section jaringan memakai `ip -brief address`; hasilnya bergantung pada sistem.
- Output dinamis (hostname, IP, penggunaan memori) berbeda pada setiap sistem.
- Pengujian otomatis baru mencakup fungsi validasi; pengujian program utama (A-D) masih dijalankan manual.
- Belum ada penjadwalan otomatis; direncanakan pada tahap P12-P15.

---

# SysGuard v2: Monitoring, Backup, dan Container

Proyek Akhir Praktikum Sistem Operasi, **Pilihan A (Backup dan Monitoring Layanan)**. Dua modul saling terhubung:

- **Modul 1 Monitoring** (`bin/check.sh`): memeriksa layanan (HTTP 200) dan kapasitas disk.
- **Modul 2 Backup dan Restore** (`bin/backup.sh`, `bin/restore.sh`): backup data simulasi dengan checksum, lalu restore dan verifikasi isi.
- **Integrasi** (`bin/sysguard.sh`): hasil monitoring menentukan backup dilanjutkan atau ditolak; hasil restore selalu diverifikasi.

Seluruh data yang diproses adalah data simulasi di folder `data/` (bukan data sistem maupun data pribadi).

## Struktur komponen SysGuard
| Path | Fungsi |
|---|---|
| `bin/check.sh`, `lib/checks.sh` | Modul 1: cek layanan dan kapasitas disk |
| `bin/backup.sh`, `bin/restore.sh`, `lib/archive.sh` | Modul 2: backup, restore, validasi path |
| `bin/sysguard.sh` | Integrasi kedua modul |
| `bin/send_backup.sh` | Kirim backup lewat SCP |
| `lib/common.sh` | Log dan exit untuk SysGuard (`logs/sysguard.log`); modul sysinfo memakai `lib/log.sh` (`logs/sysinfo.log`) |
| `docker/Dockerfile`, `docker/run.sh`, `docker/stop.sh`, `docker/monitor.sh` | Image, siklus container, monitoring |
| `tests/test_modul1.sh`, `tests/test_modul2.sh`, `tests/test_integrasi.sh` | Pengujian SysGuard |
| `data/` | Data simulasi |

## Kebutuhan lingkungan
Ubuntu/Linux dengan bash, curl, tar, sha256sum, python3 (untuk test), openssh-client dan openssh-server (untuk SCP), serta Docker (`docker.io`).

## Arsitektur dan pembagian host/container
```
Host (VM Ubuntu)                              Container Docker
+------------------------------------+       +---------------------------+
| bin/check.sh      (monitoring)     | HTTP  | sysguard-svc (nginx)      |
| bin/backup.sh     (backup)         |------>| non-root, port 8080       |
| bin/restore.sh    (restore)        |       | CPU 0.5, memori 128 MB    |
| bin/sysguard.sh   (integrasi)      |       | /data (bind mount, ro)    |
| bin/send_backup.sh (SCP)           |       +---------------------------+
+------------------------------------+
```

| Komponen | Lokasi | Alasan |
|---|---|---|
| Layanan yang dimonitor (nginx) | Container | Mudah dibuat ulang dan dibatasi resource |
| Data simulasi `data/` | Bind mount dari host (read-only di container) | Tetap ada walau container dihapus |
| Script monitoring, backup, restore, integrasi | Host | Mengontrol dari luar tanpa Docker socket |
| Akses SCP dan user `backupuser` | Host | Akses aman dan uji permission |

Alur: `bin/check.sh` memeriksa layanan dan disk. Jika OK, `bin/backup.sh` membuat archive dan `bin/restore.sh` memverifikasinya. Jika monitoring gagal, backup ditolak (exit 20).

## Network dan persistensi
- Container berada di network `sysguard-net`; port dipublikasikan hanya ke `127.0.0.1:8080`, sehingga tidak terbuka ke jaringan luar.
- Folder `data/` di-mount ke container sebagai bind mount read-only. Setelah container dihapus dan dibuat ulang (`bash docker/stop.sh -r` lalu `bash docker/run.sh`), isi `data/` tetap tersedia.

## Resource limit
Container dijalankan dengan `--cpus 0.5` dan `--memory 128m`, tanpa `--privileged` dan tanpa Docker socket. Penerapannya diperiksa dengan `bash docker/monitor.sh` (NanoCpus, Memory, Privileged, `docker stats`, log, network).

## Instalasi
```bash
git clone https://github.com/katherinlumbanraja/proyek2-otomasi-linux.git
cd proyek2-otomasi-linux
sudo apt install -y curl python3 openssh-client openssh-server docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"      # lalu login ulang
```

## Akses aman (SCP)
Siapkan user dan folder khusus dengan permission ketat:
```bash
sudo adduser --disabled-password --gecos "" backupuser
sudo mkdir -p /srv/sysguard-backup
sudo chown backupuser:backupuser /srv/sysguard-backup
sudo chmod 700 /srv/sysguard-backup
```
Kunci SSH dibuat di `~/.ssh` dan tidak pernah dimasukkan ke repository. Pengiriman backup:
```bash
bash bin/send_backup.sh -f backups/<nama>.tar.gz -t backupuser@127.0.0.1:/srv/sysguard-backup
```

## Menjalankan
```bash
bash docker/run.sh        # build image dan jalankan container
bash bin/sysguard.sh      # monitoring -> backup -> restore -> verifikasi
```
Modul dapat dijalankan sendiri:
```bash
bash bin/check.sh
bash bin/backup.sh
bash bin/restore.sh -a backups/<nama>.tar.gz -d restore/demo
```

## Menguji
```bash
bash tests/test_modul1.sh      # Modul 1: M1-01 sampai M1-04
bash tests/test_modul2.sh      # Modul 2: M2-01 sampai M2-05
bash tests/test_integrasi.sh   # Integrasi: INT-01, INT-01b, INT-02, INT-02b
```
Test memakai layanan simulasi lokal (python http.server). Demo dengan container dan pengujian SCP dijalankan manual di VM.

## Exit status SysGuard
| Kode | Arti |
|------|------|
| 0 | Sukses |
| 2 | Input atau opsi tidak valid (termasuk sumber di luar `data/`) |
| 3 | File, folder, atau perintah tidak ditemukan |
| 4 | Folder tujuan tidak bisa ditulis |
| 5 | Backup atau ekstraksi gagal |
| 6 | Checksum archive tidak cocok |
| 7 | Verifikasi isi file gagal |
| 8 | SCP gagal (akses ditolak atau jaringan) |
| 9 | Build atau run container gagal |
| 10 | Layanan tidak merespons HTTP 200 |
| 11 | Pemakaian disk melewati ambang |
| 20 | Backup ditolak karena monitoring gagal |

## Memantau
```bash
bash docker/monitor.sh
tail -20 logs/sysguard.log
```

## Cleanup
```bash
bash docker/stop.sh -r            # hapus container dan network
docker rmi sysguard-svc:1.0       # hapus image (dapat dibangun ulang dari Dockerfile)
rm -rf backups restore logs
```
Folder `data/` tidak dihapus.

## Rollback
Kode:
```bash
git fetch --tags
git checkout P2-FINAL-v01
git switch main
```
Data: pulihkan dari backup yang sudah terverifikasi:
```bash
bash bin/restore.sh -a backups/<nama>.tar.gz -d restore/rollback
```

## Keamanan
- Sumber backup hanya boleh di dalam `data/`; path di luar repository ditolak.
- Container non-root, tanpa `--privileged`, tanpa Docker socket, port hanya ke localhost.
- Tidak ada password, token, atau private key di repository.

## Keterbatasan
- Data yang di-backup hanya data simulasi di folder `data/`.
- Pemeriksaan layanan hanya HTTP 200 pada satu layanan.
- SCP diuji ke `127.0.0.1` (satu VM), bukan antar mesin.
- Archive belum dienkripsi; belum ada penjadwalan otomatis dan rotasi backup.
- Test otomatis memakai layanan simulasi; pengujian SCP dan Docker dijalankan manual di VM.
- Output dinamis (waktu, ukuran, IP) berbeda di tiap sistem.

## Kontribusi
Lihat [KONTRIBUSI.md](KONTRIBUSI.md).
