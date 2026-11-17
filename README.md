# Movie Recommendation Machine Learning

Capstone Project Mata Kuliah Pembelajaran Mesin (Machine Learning)
Kelompok 5 - Kelas A1, Teknologi Rekayasa Komputer, Sekolah Vokasi IPB.

**Anggota**

- Mohammad Jamil Satrio Wahyudianto (J0404241015)
- Najmalia Nur Azizah (J0404241018)
- Syah Fauza Bintang Prawira (J0404241116)

**Dosen pengampu:** Dodik Ariyanto S.T.P., M.Si.

## Deskripsi

Sistem rekomendasi film 2 tahap: pengelompokan katalog IMDb dengan 3 algoritma
clustering (K-Means, Agglomerative Hierarchical, DBSCAN) lalu pencarian
kemiripan terdekat (KNN / Cosine Similarity) di dalam klaster terbaik.
Dibungkus jadi aplikasi mobile Flutter yang terhubung ke backend FastAPI.

## Struktur Folder

```
Konsep dan referensi/   proposal, panduan master blueprint, screenshot dataset
UI Referensi/           referensi desain UI (dipakai: Referensi UI 3)
aplikasi/               project Flutter (UI + arsitektur + kontrak API)
backend/                project FastAPI (stub + titik pasang model .pkl)
Progress/               catatan progress & checklist pengerjaan
```

## Cara Menjalankan

### Backend (FastAPI)

```bash
cd backend
python -m uvicorn main:app --reload --port 8000
```

Docs interaktif: http://127.0.0.1:8000/docs

### Aplikasi (Flutter)

```bash
cd aplikasi
flutter pub get
flutter run
```

## Status Pengerjaan

- [x] Proposal, panduan, studi literatur
- [x] Kontrak API
- [x] Aplikasi Flutter (UI, 3 tab, watchlist lokal)
- [x] Backend FastAPI (stub, validasi, test)
- [ ] EDA & preprocessing dataset (Tahap 2)
- [ ] Modeling 3 algoritma clustering (Tahap 3)
- [ ] Integrasi model .pkl ke backend
- [ ] PPT laporan (A-O) & video demo

Detail lengkap ada di `Progress/PROGRESS.md`.

## Kontrak API

- `GET /health` - cek server & status model
- `POST /recommend` - kriteria film -> daftar rekomendasi

Spesifikasi lengkap: `aplikasi/docs/api_contract.md`.
