# Panduan Deploy Backend NeVie ke VPS Gratis (Oracle Cloud Always Free)

Tujuannya: backend FastAPI yang tadinya cuma jalan di laptop (`http://192.168.1.7:8000`)
jadi jalan 24/7 di internet lewat `https://api.domain-kamu.com`, jadi siapa pun bisa
coba aplikasinya tanpa ngatur IP lokal.

---

## 0. Ringkasan arsitektur

```
HP kamu / HP orang lain
      │  HTTPS
      ▼
┌──────────────┐        ┌────────────────────┐
│  Caddy       │  HTTP  │  uvicorn (FastAPI) │
│  :443 + TLS  ├───────►│  :8000 (internal)  │
│  (Let's Enc.)│        │  bundle model      │
└──────────────┘        └────────────────────┘
   Oracle Cloud Always Free (Ubuntu, ARM)
```

- **Caddy** yang urus HTTPS otomatis (pasang sertifikat Let's Encrypt, auto-perpanjang).
- **Backend cuma dengar di dalam jaringan Docker**, port `8000` nggak dibuka ke internet.
- Data model (bundle 154 MB) ikut di dalam image, nggak perlu transfer manual.

### Kenapa wajib punya domain?
Android **memblokir koneksi HTTP polos** kecuali diizinkan eksplisit. Sertifikat
self-signed juga nggak dipercaya HP. Caddy baru bisa minta sertifikat Let's Encrypt
kalau ada nama domain yang mengarah ke IP server. Jadi domain itu syarat, bukan pelengkap.

### Sebelum mulai — cek lokal dulu
```bash
cd backend
python -m uvicorn main:app --port 8000
curl http://127.0.0.1:8000/health
```
Harus balikin `{"status":"ok", ...}`. Kalau ini belum jalan, selesaikan dulu.

---

## 1. Bikin akun Oracle Cloud Always Free

1. Buka <https://www.oracle.com/cloud/free/> → **Start for free**.
2. Isi data, verifikasi email, lalu **verifikasi identitas dengan kartu**
   (kredit/debit atau PayPal). Ini cuma verifikasi, **nggak ditagih** selama kamu
   tetap di batas gratis.
3. **Pilih Home Region dengan hati-hati.** Instance gratis WAJIB dibuat di home
   region, dan **home region nggak bisa diganti** setelah akun jadi. Buat latency
   dari Indonesia, `ap-jakarta-1` paling dekat, `ap-singapore-1` jadi cadangan.
4. Kartu yang dipakai: **kartu kredit, atau debit yang bisa dipakai seperti
   kredit**. Debit PIN-only, kartu virtual, prepaid, dan single-use **ditolak**.
   Oracle bisa menahan dana sementara (hold) 3–5 hari, itu bukan tagihan.

> ⚠️ Yang paling sering bikin gagal: saat bikin instance muncul
> *"Out of capacity for VM.Standard.A1.Flex"*. Itu berarti kuota ARM gratis di
> region itu sedang penuh. Solusinya: coba lagi nanti, atau pindah region.

---

## 2. Bikin instance (komputernya)

1. Console → menu hamburger → **Compute → Instances → Create instance**.
2. Isi:
   - **Name**: `nevie-api`
   - **Image**: Ubuntu 24.04 (ARM)
   - **Shape**: `VM.Standard.A1.Flex` → **2 OCPU + 12 GB RAM**
     (itu plafon Always Free: total 2 OCPU & 12 GB per akun, Oracle menghitungnya
     sebagai 1.500 OCPU-jam + 9.000 GB-jam per bulan. RAM 12 GB sudah lega buat
     bundle model 154 MB)
   - **Boot volume**: biarkan default (**50 GB**), total gratis 200 GB
   - Pilih image **Ubuntu 24.04 biasa, bukan Minimal** (Minimal bermasalah di ARM)
3. **SSH keys**: pilih *Generate a key pair for me*, lalu **simpan file `.key`**
   yang diunduh. Tanpa itu kamu nggak bisa masuk ke server.
4. **Public IP**: pastikan dapat alamat IP publik (ephemeral = gratis).
5. Setelah jadi, catat **IP publik**-nya (misal `129.146.xx.xx`).

Kalau gagal terus karena kapasitas, alternatif shape gratis lain:
`VM.Standard.E2.1.Micro` (AMD, 1 OCPU / **1 GB RAM**) — tapi **berisiko OOM**
pas memuat bundle, jadi kalau bisa pakai A1.

---

## 3. Aturan firewall (VCN)

1. Console → Networking → **Virtual Cloud Networks** → VCN kamu → **Security Lists**
   → Default Security List → **Add Ingress Rules**, tambahkan:

| Port | Source CIDR | Deskripsi |
| ---- | ----------- | --------- |
| 22   | `0.0.0.0/0` | SSH (kalau mau dibatasi, isi IP kamu) |
| 80   | `0.0.0.0/0` | HTTP (buat validasi sertifikat) |
| 443  | `0.0.0.0/0` | HTTPS — ini yang dipakai aplikasi |

> ❌ **Jangan** buka port `8000`. Backend cuma boleh dikenal oleh Caddy di dalam
> jaringan Docker. Kalau dibuka, siapa pun bisa langsung menyentuh API tanpa TLS.

> 🔎 Ada **dua firewall**: Security List di console, dan `iptables` di dalam
> Ubuntu. Kalau port masih nggak bisa diakses padahal security list sudah benar,
> cek yang di dalam server:
> ```bash
> sudo iptables -L INPUT -n --line-numbers | head
> ```
> Oracle Ubuntu image punya aturan bawaan yang ketat. Kalau perlu, izinkan:
> ```bash
> sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
> sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
> sudo apt install -y iptables-persistent
> sudo netfilter-persistent save
> ```

---

## 4. Domain + DNS

Opsi termurah & paling gampang:

- **Gratis**: daftar subdomain di <https://www.duckdns.org> (butuh akun Google/GitHub)
  → kamu dapat `nama-pilihan.duckdns.org`.
- **Gratis**: <https://freedns.afraid.org> (subdomain dari domain milik orang lain).
- **Murah**: beli domain sendiri (`.xyz` ~ Rp20–30 rb/tahun, `.id` lebih mahal).

Lalu buat **DNS A record**:

```
api.domain-kamu.com   A   129.146.xx.xx
```

Cek propagasi:
```bash
dig +short api.domain-kamu.com
```

---

## 5. Install Docker & jalanin deploy

Masuk ke server:
```bash
ssh -i ~/Downloads/nama-key.key ubuntu@129.146.xx.xx
chmod 600 ~/Downloads/nama-key.key
```

Pasang Docker:
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
newgrp docker          # aktifkan grup tanpa logout
docker --version && docker compose version
```

Ambil kode (repo publik, jadi cukup clone):
```bash
git clone https://github.com/starvibritannia/movie-recommendation-machinelearning.git
cd movie-recommendation-machinelearning/deploy
```
> Ganti URL di atas dengan URL repo kamu yang benar.

Siapkan konfigurasi:
```bash
cp .env.example .env
nano .env               # isi API_DOMAIN=api.domain-kamu.com
```

Jalankan:
```bash
docker compose up -d --build
docker compose ps
docker compose logs -f api
```

Catatan:
- Build image sekitar 600 MB–1 GB (ada bundle model), jadi menunggu itu normal.
- Backend butuh ~30–60 detik buat `joblib.load` sebelum `/health` siap.
  Caddy akan sempat balas error 502 sementara — itu wajar.
- Caddy baru minta sertifikat saat domain sudah mengarah benar. Kalau `/health`
  lokal belum hijau, tunggu, jangan panik dulu.

Uji dari server:
```bash
curl -sS http://127.0.0.1:8000/health     # lewat container
curl -sSI https://api.domain-kamu.com/health
```

Uji dari **HP kamu, pakai data seluler (bukan Wi-Fi yang sama)** supaya yakin
ini beneran publik:
```bash
curl https://api.domain-kamu.com/health
curl -X POST https://api.domain-kamu.com/recommend \
  -H 'Content-Type: application/json' \
  -d '{"genres":["Sci-Fi"],"min_rating":7.5,"runtime_min":90,"runtime_max":210,"year_start":2000,"year_end":2024,"keyword":null,"top_n":10}'
```
Dan buka `https://api.domain-kamu.com/docs` di browser HP — kalau Swagger UI
muncul, backend sudah bisa diakses publik.

---

## 6. Arahkan aplikasi Flutter ke server

Base URL sekarang bisa dioverride waktu build (`--dart-define`), jadi kodenya
tetap netral:

```bash
cd aplikasi

# Uji di emulator, backend-nya di VPS:
flutter run --dart-define=API_BASE_URL=https://api.domain-kamu.com

# Build release buat dibagikan / Play Store:
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.domain-kamu.com

# Atau buat bundle (Play Store):
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.domain-kamu.com
```

> ⚠️ Default `API_BASE_URL` di `api_constants.dart` masih alamat lokal, jadi
> **jangan lupa `--dart-define`** setiap kali build yang mau dipublikasikan.

Soal `android:usesCleartextTraffic="true"` di `AndroidManifest.xml`: karena
produksi pakai HTTPS, sebaiknya diatur ulang. Pilihan:
- **Paling aman**: ganti jadi `"false"`, tapi uji lokal lewat HTTP jadi mati.
- **Kompromi**: biarkan `"true"` (aplikasi ini belum menangani data sensitif),
  atau pasang `network_security_config.xml` yang mengizinkan HTTP **hanya** ke
  IP lokal/emulator. Kalau mau, aku bisa bikinkan konfigurasinya.

---

## 7. Kalau nggak mau beli domain (Cloudflare Tunnel)

Alternatif tanpa domain, tapi ada konsekuensinya:

- Pasang `cloudflared` di VPS, lalu `cloudflared tunnel --url http://127.0.0.1:8000`.
- Kamu dapat URL `https://xxxx.trycloudflare.com` — **HTTPS, gratis, tanpa buka port 443**.
- Tapi URL itu **berubah tiap cloudflared restart**, jadi aplikasi harus di-build
  ulang tiap ganti URL. Cocok buat demo singkat, **nggak cocok untuk publik jangka panjang**.
- Kalau kamu punya domain yang dikelola di Cloudflare, pakai *named tunnel* +
  hostname → URL-nya permanen.

---

## 8. Perawatan harian

```bash
docker compose logs -f api        # lihat log
docker compose pull && docker compose up -d   # update image
docker compose restart api        # kalau perlu mulai ulang
df -h                             # pantau disk
free -m                           # pantau RAM
```

Hal yang perlu diperhatikan:

- **RAM**: bundle model dimuat sekali (~1 GB). Jangan tambah `--workers` lebih
  dari satu — Dockerfile sudah memaksakan `--workers 1`.
- **Sertifikat**: Caddy memperpanjang otomatis. Kalau gagal, biasanya karena
  DNS belum propagasi saat pertama kali start → tinggal `docker compose restart caddy`.
- **Biaya**: pastikan tidak melewati batas gratis (2 OCPU A1, 12 GB RAM, 200 GB disk,
  10 TB egress/bulan). Di Always Free, pemakaian di atas itu **ditagih**.
- **Idle**: Oracle boleh "menarik kembali" sumber daya Always Free yang lama
  nggak terpakai. Kalau server ini mau hidup terus, sempatkan cek balaiknya
  tiap beberapa hari (cron sederhana / heartbeat) supaya nggak di-reclaim.

---

## 9. Troubleshooting cepat

| Gejala | Kemungkinan | Perbaikan |
| ------ | ----------- | --------- |
| `Out of capacity for VM.Standard.A1.Flex` | Kuota ARM gratis penuh | Ganti region, coba lagi besok, atau pakai E2.1.Micro |
| Container api langsung mati / `Killed` | RAM kurang (OOM) | Naikkan RAM, pastikan `--workers 1` |
| 502 Bad Gateway pas pertama start | Model lagi dimuat | Tunggu ~1 menit, cek `docker compose logs api` |
| Sertifikat nggak jadi (`DNS problem`) | DNS belum propagasi / A record salah | Cek `dig api.domain`, lalu restart Caddy |
| HP nggak bisa konek | Port 443 belum dibuka / DNS | Cek security list + `dig`, tes pakai data seluler |
| Port 80/443 tetap ketutup padahal security list OK | `iptables` bawaan Ubuntu Oracle | Lihat catatan dua firewall di bagian 3 |
| Aplikasi masih hit IP lokal | Lupa `--dart-define` | Build ulang dengan `API_BASE_URL` yang benar |

---

## 10. Buku besar langkah (checklist)

- [ ] Backend lokal sehat (`/health` OK)
- [ ] Akun Oracle + instance A1 (2 OCPU / 12 GB) + simpan SSH key
- [ ] Security list: buka 22, 80, 443 — **port 8000 tertutup**
- [ ] Domain + A record → IP publik (propagasi beres)
- [ ] Docker terpasang, `deploy/.env` terisi
- [ ] `docker compose up -d --build` sukses, `/health` hijau
- [ ] `/docs` bisa dibuka dari HP (data seluler)
- [ ] `flutter build apk --release --dart-define=API_BASE_URL=...`
- [ ] Tes install APK di HP lain → dapat rekomendasi

---

## Berkas yang disiapkan repo

| Berkas | Fungsi |
| ------ | ------ |
| `backend/Dockerfile` | Image produksi (uvicorn, 1 worker, healthcheck) |
| `backend/.dockerignore` | Jaga-jaga `.venv`/`__pycache__` nggak ikut ke image |
| `deploy/docker-compose.yml` | Orkestrasi api + caddy |
| `deploy/Caddyfile` | Reverse proxy + TLS otomatis |
| `deploy/.env.example` | Contoh isian `API_DOMAIN` / `API_HOST` |
| `deploy/.env` | Isianmu sendiri (di-gitignore) |
