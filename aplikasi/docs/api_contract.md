# Kontrak API: Flutter ↔ FastAPI

Dokumen ini jadi **satu-satunya sumber kebenaran** soal format data antara
aplikasi mobile (Flutter) dan backend (FastAPI). Selama backend dan Flutter
mengikuti dokumen ini, kedua pihak bisa dikerjakan paralel tanpa saling tunggu.

- Base URL development (Android emulator): `http://10.0.2.2:8000`
- Base URL iOS simulator: `http://localhost:8000`
- Base URL HP fisik: `http://<IP-lokal-komputer>:8000`
- Semua request/response memakai `application/json; charset=utf-8`

---

## 1. POST /recommend

Mengirim kriteria film yang diinginkan user, lalu menerima daftar film yang
paling mirip di dalam klaster yang tepat.

### Request

`POST /recommend`

```json
{
  "genres": ["Action", "Sci-Fi"],
  "min_rating": 7.5,
  "runtime_min": 90,
  "runtime_max": 150,
  "year_start": 2015,
  "year_end": 2024,
  "keyword": "space",
  "top_n": 10
}
```

| Field         | Tipe            | Wajib | Keterangan                                              |
| ------------- | --------------- | :---: | ------------------------------------------------------- |
| `genres`      | array of string |   ✓   | Daftar genre yang diinginkan. Boleh kosong = semua genre. |
| `min_rating`  | number          |   ✓   | Rating IMDb minimum, rentang 0.0 - 10.0.                |
| `runtime_min` | integer         |   ✓   | Durasi minimum dalam menit.                             |
| `runtime_max` | integer         |   ✓   | Durasa maksimum dalam menit.                            |
| `year_start`  | integer         |   ✓   | Tahun rilis terawal.                                    |
| `year_end`    | integer         |   ✓   | Tahun rilis terakhir.                                   |
| `keyword`     | string / null   |   ✓   | Kata kunci tema atau judul. Null / string kosong = diabaikan. |
| `top_n`       | integer         |   ✓   | Jumlah film yang diminta, maksimal 50.                  |

> Catatan: `keyword` dikirim sebagai `null` (bukan string kosong) kalau user
> tidak mengisinya. Lihat `RecommendationCriteria.toJson()` di Flutter.

### Response (200 OK)

Backend boleh membalas **dua bentuk**, Flutter menerima dua-duanya.

Bentuk A (disarankan, memberi info tambahan):

```json
{
  "recommendations": [
    {
      "movie_id": "tt1375666",
      "movie_name": "Inception",
      "year": 2010,
      "certificate": "PG-13",
      "runtime": 148,
      "genre": ["Action", "Sci-Fi", "Thriller"],
      "rating": 8.8,
      "votes": 2500000,
      "description": "A thief who steals corporate secrets...",
      "director": "Christopher Nolan",
      "star": ["Leonardo DiCaprio", "Joseph Gordon-Levitt", "Elliot Page"],
      "match_percent": 96.4,
      "cluster_label": 3
    }
  ],
  "predicted_cluster": 3,
  "total_candidates": 842,
  "elapsed_ms": 45.2
}
```

Bentuk B (array polos, lebih simpel kalau backend belum final):

```json
[
  {
    "movie_id": "tt1375666",
    "movie_name": "Inception",
    "year": 2010,
    "certificate": "PG-13",
    "runtime": 148,
    "genre": ["Action", "Sci-Fi"],
    "rating": 8.8,
    "votes": 2500000,
    "description": "...",
    "director": "Christopher Nolan",
    "star": ["Leonardo DiCaprio"],
    "match_percent": 96.4,
    "cluster_label": 3
  }
]
```

### Field response

| Field           | Tipe             | Keterangan                                                     |
| --------------- | ---------------- | -------------------------------------------------------------- |
| `movie_id`      | string           | ID IMDb, dipakai sebagai kunci unik.                           |
| `movie_name`    | string           | Judul film.                                                    |
| `year`          | integer / null   | Tahun rilis.                                                   |
| `certificate`   | string           | Batas usia penonton, misal `PG-13`, `R`, `Unrated`.            |
| `runtime`       | integer / null   | Durasi dalam menit (bukan teks "148 min").                     |
| `genre`         | array of string  | Genre film. Backend boleh kirim string `"Action, Sci-Fi"`, Flutter bisa parse dua-duanya. |
| `rating`        | number / null    | Rating IMDb 0.0 - 10.0.                                        |
| `votes`         | integer / null   | Jumlah suara IMDb.                                             |
| `description`   | string           | Sinopsis singkat.                                              |
| `director`      | string           | Nama sutradara.                                                |
| `star`          | array of string  | Daftar pemeran utama (bisa juga string dipisah koma).          |
| `match_percent` | number / null    | Persentase kemiripan 0 - 100, dihitung dari Cosine Similarity. |
| `cluster_label` | integer / null   | Label klaster tempat film itu berada.                          |

### Contoh response error

```json
{
  "detail": "min_rating harus di antara 0 dan 10"
}
```

| Status | Arti                                                          |
| ------ | ------------------------------------------------------------- |
| 400    | Body tidak valid / kriteria bertentangan.                     |
| 422    | Format body salah (FastAPI validation error).                 |
| 500    | Model / server error.                                         |
| 503    | Model `.pkl` belum dimuat.                                    |

Flutter melempar `ServerFailure` untuk status bukan 200, dan `NetworkFailure`
kalau koneksi gagal / timeout.

---

## 2. GET /health

Cek server FastAPI hidup. Dipakai aplikasi untuk menampilkan badge status.

### Response (200 OK)

```json
{
  "status": "ok",
  "model_loaded": true,
  "model_name": "kmeans",
  "cluster_count": 8
}
```

| Field           | Tipe    | Keterangan                                       |
| --------------- | ------- | ------------------------------------------------ |
| `status`        | string  | Selalu `"ok"` kalau server hidup.                |
| `model_loaded`  | boolean | Apakah file `.pkl` model clustering sudah dimuat. |
| `model_name`    | string  | Nama algoritma pemenang, misal `kmeans`.         |
| `cluster_count` | integer | Jumlah klaster yang dipakai.                     |

Kalau `model_loaded` masih `false`, `/recommend` akan balik 503 sampai Tahap 3
(modeling + export `.pkl`) selesai.

---

## 3. Alur pemrosesan di backend (konteks)

```
request Flutter
   ↓
validasi body (min_rating 0-10, runtime_min <= runtime_max, dst)
   ↓
preprocessing: genre → vektor biner, angka → StandardScaler
   ↓
model clustering terbaik → prediksi klaster input
   ↓
KNN / Cosine Similarity di dalam klaster itu → urutkan
   ↓
ambil top_n film, hitung match_percent
   ↓
response JSON
```

---

## 4. Mapping ke kode Flutter

| Dokumen ini           | File Flutter                                              |
| --------------------- | --------------------------------------------------------- |
| Request body          | `lib/domain/entities/recommendation_criteria.dart`        |
| Response film         | `lib/data/models/movie_model.dart`                        |
| Response pembungkus   | `lib/data/models/recommendation_response.dart`            |
| Pemanggil HTTP        | `lib/data/datasources/recommendation_remote_datasource.dart` |
| Base URL & endpoint   | `lib/core/constants/api_constants.dart`                   |
| Mode dummy (fallback) | `assets/mock/recommendation_mock.json`                    |

Kalau kontrak berubah, ubah dokumen ini dulu, baru ikutin kode di kanan.

---

## 5. Endpoint Opsional (belum dibuat)

Endpoint ini dipakai tab **Trending** dan **Watchlist** kalau nanti mau
diterapkan, tapi sekarang belum dibuat di backend.

### GET /trending

Balikin daftar film yang lagi populer musim ini, bentuk response sama dengan
daftar `Movie` di bagian 1.

```json
{
  "recommendations": [],
  "period": "2026-11",
  "total_candidates": 500
}
```

Sekarang `TrendingProvider` masih membaca `assets/mock/recommendation_mock.json`
sebagai gantinya.

### DELETE /watchlist atau sync watchlist

Watchlist sengaja **belum** di-sync ke server karena aplikasi nggak punya login.
Data disimpan lokal di HP lewat `shared_preferences`. Kalau nanti mau
multi-perangkat, baru perlu endpoint auth + watchlist.
