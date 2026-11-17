# PROGRESS PROYEK - SISTEM REKOMENDASI FILM

Tanggal update : 17 November 2026
Kelompok       : 5 (Kelas A1, Teknologi Rekayasa Komputer, Sekolah Vokasi IPB)
Anggota        : Mohammad Jamil Satrio Wahyudianto, Najmalia Nur Azizah, Syah Fauza Bintang Prawira
Dosen pengampu : Dodik Ariyanto S.T.P., M.Si.
Judul          : Komparasi Algoritma K-Means, Agglomerative Hierarchical, dan DBSCAN pada Sistem Rekomendasi Film Berbasis Kemiripan Fitur

---

## 0. Ringkasan Status

| Area | Status | Catatan |
|---|---|---|
| Konsep, proposal, studi literatur | SELESAI | Proposal + panduan + 5 jurnal sudah ada |
| Dataset & EDA (Tahap 2) | BELUM | Belum ada notebook, `pandas` belum terpasang |
| Modeling 3 algoritma (Tahap 3) | BELUM | Nunggu data bersih dari Tahap 2 |
| Backend FastAPI | SEBAGIAN | Stub jalan, endpoint + validasi + test OK, model asli belum dipasang |
| Aplikasi Flutter | SEBAGIAN | UI + arsitektur + 3 tab + watchlist selesai, belum terhubung model asli |
| Kontrak API | SELESAI | `docs/api_contract.md` + `docs/api_contract.yaml` |
| PPT laporan (A-O) | BELUM | |
| Video demo (<= 7 menit) | BELUM | |

Perkiraan ketuntasan area yang sudah dikerjakan: **API + kerangka UI sekitar 60%**, **ML pipeline sekitar 10%**, **laporan 0%**.

---

## 1. Konsep & Referensi (SELESAI)

Lokasi: `C:\Projek Rekomendasi Film\Konsep dan referensi\`

- [x] Proposal Projek (`Proposal Projek.docx`) - latar belakang, permasalahan, tujuan, dataset, 14 variabel, 5 jurnal, tabel studi literatur
- [x] Panduan Master Blueprint (`Panduan Pemahaman Menyeluruh Sistem & Proyek Machine Learning - Kelompok 5.pdf`) - alur 5 fase end-to-end, roadmap pembagian tugas, checklist 5 luaran
- [x] Screenshot deskripsi kolom dataset Kaggle (`Deskripsi_Kolom_Dataset.jpg`)
- [x] Screenshot genre dataset Kaggle (`Jenis_Genre_di_Dataset.jpg`)

Hal penting yang sudah dipahami dari dokumen:

- Sistem 2 tahap: clustering makro (K-Means, Agglomerative, DBSCAN) -> pilih model terbaik -> pencarian kemiripan mikro (KNN / Cosine Similarity) di dalam klaster
- Evaluasi: Silhouette Score, Davies-Bouldin Index, Elbow Method, visualisasi PCA
- Alur Flutter: input kriteria -> FastAPI -> preprocessing -> prediksi klaster -> KNN/Cosine -> kartu rekomendasi

Catatan kecil / ketidakkonsistenan antar dokumen (perlu diputusin nanti):

- Ukuran dataset: panduan tulis 130,45 MB, screenshot Kaggle tulis 171,61 MB (versi 7: 178,5 MB)
- Nama kolom: proposal tulis `votes`, screenshot Kaggle tulis `num_votes`
- Jumlah genre: file CSV 16 genre, filter Kaggle menampilkan 25 genre

---

## 2. Dataset & Machine Learning (BELUM)

Lokasi target: belum ada folder khusus, usulan `C:\Projek Rekomendasi Film\modeling\` (notebook) dan `C:\Projek Rekomendasi Film\data\` (CSV).

- [ ] Download / kumpulkan 16 file CSV dari Kaggle (`rajugc/imdb-movies-dataset-based-on-genre`)
- [ ] Gabung 16 CSV, deduplikasi berdasarkan `movie_id`
- [ ] EDA: statistik deskriptif, missing value, outlier, histogram, bar chart, boxplot, scatter, heatmap korelasi
- [ ] Preprocessing: bersihkan `runtime` ("161 min"), tipe data numerik, missing value, imputasi `certificate`, transformasi `votes` (log1p / IQR)
- [ ] Feature engineering: `MultiLabelBinarizer` genre, `TF-IDF` sinopsis, `StandardScaler`/`MinMaxScaler`
- [ ] Split train/test (80/20)
- [ ] Latih K-Means (Elbow + Silhouette)
- [ ] Latih Agglomerative Hierarchical (dendrogram)
- [ ] Latih DBSCAN (eps, min_samples, noise)
- [ ] Bandingkan 3 model, tentukan pemenang
- [ ] Export model, scaler, encoder, KNN ke `.pkl` / `.joblib`

Dependency yang belum terpasang: `pandas` (numpy & scikit-learn sudah ada).

---

## 3. Backend FastAPI (SEBAGIAN - stub selesai)

Lokasi: `C:\Projek Rekomendasi Film\backend\`

- [x] Struktur project (`main.py`, `app/schemas.py`, `app/recommender.py`, `app/data/movies.json`)
- [x] `GET /health` - status server + status model
- [x] `POST /recommend` - terima kriteria, balik Top-N film
- [x] Validasi request (rating 0-10, runtime_min <= runtime_max, year_start <= year_end, top_n 1-50)
- [x] Penilaian kemiripan deterministik untuk stub
- [x] CORS middleware
- [x] Katalog dummy 16 film
- [x] 7 test TestClient, semua lolos
- [x] Server dijalankan & di-curl, semua endpoint merespons benar
- [ ] Pasang model `.pkl` asli (`Recommender.load_model`)
- [ ] Ganti penilaian stub dengan prediksi klaster + KNN/Cosine asli
- [ ] Katalog ganti ke data hasil preprocessing
- [ ] (Opsional) endpoint `GET /trending`

Verifikasi yang sudah dilakukan:

- `python -m uvicorn main:app --port 8000` -> startup OK
- `GET /health` -> `{"status":"ok","model_loaded":false,"model_name":null,"cluster_count":0}`
- `POST /recommend` body `{}` -> 200, The Dark Knight match 92.2%
- `POST /recommend` filter Sci-Fi -> 200, Inception di atas
- `POST /recommend` dengan `min_rating: 11` -> 422

---

## 4. Aplikasi Flutter (SEBAGIAN - UI & arsitektur selesai)

Lokasi: `C:\Projek Rekomendasi Film\aplikasi\`
Package: `com.kelompok5.film_recommendation` | Flutter 3.44.6 | Dart 3.12.2

### 4.1 Arsitektur & fondasi

- [x] Scaffold project, dependency `provider`, `http`, `shared_preferences`
- [x] Pola clean architecture: `core`, `domain`, `data`, `presentation`
- [x] Dependency injection manual di `main.dart` (MultiProvider)
- [x] Entity, use case, repository interface + implementasi
- [x] Data source remote (HTTP) + local (dummy) + fallback otomatis
- [x] Model request/response + parser JSON fleksibel
- [x] Penanganan error: `ServerFailure`, `NetworkFailure`, `CacheFailure`, `ValidationFailure`
- [x] Util format durasi, votes, persen

### 4.2 Desain (mengikuti Referensi UI 3)

- [x] Tema dark cinematic: background `#0B0E12` -> `#12161B`
- [x] Aksen oranye `#FF7A18`, oranye terang `#FFB03A`, coral `#FF4D2D`
- [x] Background glow (oranye kanan atas, teal kiri bawah, coral bawah) di `AppBackground`
- [x] Glassmorphism: `GlassCard`, `GlassNavBar`, `GlassSearchField`
- [x] `AppScaffold` supaya semua halaman punya latar glow + app bar transparan
- [x] Nav bar melayang dengan `extendBody`, item aktif dapat pill oranye
- [x] Tombol & logo dengan glow

### 4.3 Halaman & navigasi

- [x] Splash -> MainShell
- [x] Tab 1 Trending: header banner, daftar film, pull-to-refresh
- [x] Tab 2 Discover: form kriteria (25 genre, slider rating, range durasi, range tahun, slider jumlah, kata kunci)
- [x] Halaman hasil: daftar kartu film + badge match + badge cluster
- [x] Halaman detail: poster hero, rating, metadata, genre, sinopsis, kru, tombol bookmark
- [x] Tab 3 Watchlist: tambah/hapus, swipe untuk hapus, empty state
- [x] Watchlist tersimpan lokal via `shared_preferences`
- [x] Badge status server di halaman Discover

### 4.4 Data dummy & kontrak

- [x] `assets/mock/recommendation_mock.json` (8 film)
- [x] `docs/api_contract.md` + `docs/api_contract.yaml`
- [x] Base URL `http://10.0.2.2:8000` di `api_constants.dart`

### 4.5 Verifikasi

- [x] `flutter analyze` -> no issues found
- [x] `flutter test` -> 9 test lolos
- [x] `flutter build apk --debug` -> sukses

### 4.6 Yang belum

- [ ] Uji end-to-end di emulator dengan backend nyala
- [ ] Poster asli (dataset tidak punya URL poster, sekarang placeholder gradien)
- [ ] Halaman onboarding/splash yang lebih kaya
- [ ] State loading skeleton, empty state, error state yang lebih halus
- [ ] Trending pakai data/endpoint asli (sekarang mock)
- [ ] Nama aplikasi & icon launcher khusus
- [ ] Ambiguitas: tab default sekarang Trending (`_currentIndex = 0`)

---

## 5. Kontrak API (SELESAI)

Lokasi: `C:\Projek Rekomendasi Film\aplikasi\docs\`

- [x] `POST /recommend`: request `genres`, `min_rating`, `runtime_min`, `runtime_max`, `year_start`, `year_end`, `keyword`, `top_n`
- [x] Response: `recommendations` + `predicted_cluster`, `total_candidates`, `elapsed_ms`
- [x] Field film: `movie_id`, `movie_name`, `year`, `certificate`, `runtime`, `genre`, `rating`, `votes`, `description`, `director`, `star`, `match_percent`, `cluster_label`
- [x] `GET /health`
- [x] Aturan error 400 / 422 / 500 / 503
- [x] Catatan endpoint opsional `/trending` dan sync watchlist
- [x] Versi OpenAPI (`api_contract.yaml`)

---

## 6. Deliverables Wajib ke Dosen (Tahap 5)

- [ ] Model ML terlatih, dibandingkan minimal 3 algoritma, dievaluasi mendalam
- [ ] Aplikasi mobile Flutter + FastAPI yang berfungsi dari input sampai rekomendasi
- [ ] Source code terstruktur & berkomentar (notebook + backend + Flutter + repo GitHub)
- [ ] PPT laporan poin A sampai O
- [ ] Video demo maksimal 7 menit (perkenalan tim, alur ML, perbandingan model, live run aplikasi)

---

## 7. Action Items Berikutnya (urutan prioritas)

1. **Tahap 2**: install `pandas`, siapkan notebook EDA + preprocessing di Google Colab/Jupyter
2. **Tahap 3**: latih 3 algoritma clustering, evaluasi, export `.pkl`
3. **Integrasi backend**: `load_model` + ganti scorer stub dengan model asli
4. **Uji end-to-end**: jalankan `uvicorn` lalu buka app di emulator, pastikan Discover balik hasil dari server
5. **Trending asli**: ambil daftar populer dari dataset / tambah endpoint `/trending`
6. **Tahap 5**: susun PPT A-O, rekam video demo
7. **Repo GitHub**: rapikan struktur, tulis README, push
8. (Opsional) poster film, onboarding, perapian UI

---

## 8. Environment & Perintah Penting

| Item | Versi / Nilai |
|---|---|
| Flutter | 3.44.6 (stable) |
| Dart | 3.12.2 |
| Python | 3.11.16 |
| fastapi | 0.133.1 |
| pydantic | 2.13.4 |
| uvicorn | 0.41.0 |
| scikit-learn | 1.9.0 |
| pandas | BELUM terpasang |
| pytest | BELUM terpasang (test backend dijalankan manual via TestClient) |

Perintah:

```bash
# Flutter
cd "C:/Projek Rekomendasi Film/aplikasi"
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run

# Backend
cd "C:/Projek Rekomendasi Film/backend"
python -m uvicorn main:app --reload --port 8000
# docs: http://127.0.0.1:8000/docs
```

Base URL backend: `lib/core/constants/api_constants.dart`

| Device | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| HP fisik | `http://<IP-komputer>:8000` |

---

## 9. File Kunci

```
C:\Projek Rekomendasi Film\
  Konsep dan referensi\
    Proposal Projek.docx
    Panduan Pemahaman Menyeluruh ... Kelompok 5.pdf
    Deskripsi_Kolom_Dataset.jpg
    Jenis_Genre_di_Dataset.jpg
  UI Referensi\
    Referensi UI 1..5.png        (UI 3 dipilih sebagai acuan)
  aplikasi\                      (Flutter)
    lib\main.dart                (composition root)
    lib\core\constants\api_constants.dart
    lib\core\theme\              (warna + tema)
    lib\domain\                  (entity, repository, use case)
    lib\data\                    (model, datasource, repository impl)
    lib\presentation\pages\      (splash, main_shell, trending, discover, results, watchlist)
    lib\presentation\widgets\    (glass_card, glass_nav_bar, app_background, movie_card, ...)
    lib\presentation\providers\  (recommendation, trending, watchlist)
    assets\mock\recommendation_mock.json
    docs\api_contract.md
    docs\api_contract.yaml
  backend\                       (FastAPI stub)
    main.py
    app\schemas.py
    app\recommender.py
    app\data\movies.json
    tests\test_api.py
  Progress\
    PROGRESS.md                  (file ini)
```

---

## 10. Keputusan yang Sudah Diambil

- Referensi UI dipakai: **Referensi UI 3** (KuKu, dark cinematic + aksen oranye + glassmorphism)
- State management: `provider` (ringan, tanpa codegen)
- Watchlist: lokal via `shared_preferences`, tanpa login
- Navigasi: 3 tab (Trending, Discover, Watchlist)
- Backend: FastAPI, stub dulu, model `.pkl` dipasang belakangan tanpa ubah kontrak
- Poster: placeholder dulu, dataset tidak menyediakan URL poster
