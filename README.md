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
