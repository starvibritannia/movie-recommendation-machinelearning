# FilmMatch - Aplikasi Rekomendasi Film (Flutter)

Aplikasi mobile untuk Capstone Project Machine Learning Kelompok 5 (Sekolah
Vokasi IPB). Aplikasi menerima kriteria film dari user, mengirimnya ke backend
FastAPI, lalu menampilkan daftar film yang paling mirip.

## Status

- [x] Arsitektur & scaffolding project
- [x] Tema dark (referensi UI 3: aplikasi streaming aksen oranye-coral)
- [x] Halaman input kriteria (genre, rating, durasi, tahun, kata kunci)
- [x] Halaman hasil + halaman detail
- [x] API client + fallback data dummy
- [x] Kontrak API (`docs/api_contract.md`)
- [ ] Koneksi ke model `.pkl` asli (nunggu Tahap 3 selesai)

## Struktur Folder

```
lib/
  main.dart                     # composition root (rangkai dependency)
  app.dart                      # MaterialApp + tema
  core/
    constants/
      api_constants.dart        # base URL & endpoint FastAPI
      app_strings.dart          # label UI + daftar 25 genre
    theme/
      app_colors.dart           # design token warna
      app_theme.dart            # ThemeData dark
    errors/
      failures.dart             # ServerFailure, NetworkFailure, dst
    utils/
      formatters.dart           # format durasi, votes, persen
  domain/                       # lapisan bisnis, murni Dart
    entities/
      movie.dart
      recommendation_criteria.dart
    repositories/
      recommendation_repository.dart
    usecases/
      get_recommendations.dart
  data/                         # lapisan data (JSON, HTTP, file dummy)
    models/
      movie_model.dart
      recommendation_response.dart
    datasources/
      recommendation_remote_datasource.dart   # HTTP ke FastAPI
      recommendation_local_datasource.dart    # baca assets/mock
    repositories/
      recommendation_repository_impl.dart     # remote + fallback mock
  presentation/
    providers/
      recommendation_provider.dart            # state filter & hasil (Discover)
      trending_provider.dart                  # state daftar trending
      watchlist_provider.dart                 # state watchlist + simpan lokal
    pages/
      splash_page.dart
      main_shell.dart                         # kerangka 3 tab + bottom nav
      trending_page.dart                      # tab 1: film trending
      discover_page.dart                      # tab 2: form kriteria (ML)
      results_page.dart                       # daftar hasil + detail + bookmark
      watchlist_page.dart                     # tab 3: koleksi film
    widgets/
      movie_card.dart
      match_badge.dart
      server_status_badge.dart
assets/mock/
  recommendation_mock.json      # data dummy saat backend belum siap
docs/
  api_contract.md               # kontrak API lengkap
  api_contract.yaml             # versi OpenAPI
```

## Alur Data

```
UI (form kriteria)
  -> RecommendationProvider.search()
  -> GetRecommendations (use case)
  -> RecommendationRepositoryImpl
       |- RecommendationRemoteDataSource  ->  POST /recommend  (FastAPI)
       |- RecommendationLocalDataSource   ->  assets/mock/*.json (fallback)
  -> MovieModel.fromJson()
  -> UI (kartu rekomendasi)
```

## Cara Jalanin

```bash
flutter pub get
flutter run
```

Test unit (format kriteria & parsing model):

```bash
flutter test
```

## Ganti Base URL Backend

Edit `lib/core/constants/api_constants.dart`:

| Device           | Base URL                    |
| ---------------- | --------------------------- |
| Android emulator | `http://10.0.2.2:8000`      |
| iOS simulator    | `http://localhost:8000`     |
| HP fisik         | `http://<IP-komputer>:8000` |

## Catatan Desain

- Dataset tidak menyediakan URL poster, jadi poster diganti placeholder gradien
  dengan inisial judul. Kalau backend nanti menambah `poster_url`, cukup ganti
  widget `_PosterPlaceholder` di `movie_card.dart` dan `_PosterHero` di
  `results_page.dart` menjadi `Image.network`.
- Warna mengikuti referensi UI 3: latar `#0E0E12`, kartu `#1C1C22`, aksen
  oranye `#FF7A00` ke coral `#FF3D5A`.
- Splash -> Home (form) -> Results (daftar) -> Detail. Navigasi masih pakai
  `Navigator.push` sederhana, belum ada named route.
