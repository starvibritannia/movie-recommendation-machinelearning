# Backend (FastAPI) - FilmMatch

Stub backend untuk aplikasi rekomendasi film. Kontrak API lengkap ada di
`../aplikasi/docs/api_contract.md`.

## Struktur

```
backend/
  main.py                  # entry point FastAPI
  app/
    __init__.py
    schemas.py             # model request/response (pydantic)
    recommender.py         # mesin rekomendasi + penilaian kemiripan
    data/
      movies.json          # katalog dummy (16 film)
  tests/
    test_api.py            # test endpoint pakai TestClient
  requirements.txt
```

## Install & Jalankan

```bash
cd backend
python -m venv .venv
source .venv/Scripts/activate     # Windows git-bash
pip install -r requirements.txt
python -m uvicorn main:app --reload --port 8000
```

Docs interaktif: http://127.0.0.1:8000/docs

## Endpoint

| Method | Path        | Fungsi                                        |
| ------ | ----------- | --------------------------------------------- |
| GET    | `/`         | Info API                                      |
| GET    | `/health`   | Cek server + status model `.pkl`              |
| POST   | `/recommend`| Terima kriteria, balik Top-N film rekomendasi |

### Contoh request

```bash
curl -X POST http://127.0.0.1:8000/recommend \
  -H "Content-Type: application/json" \
  -d '{"genres":["Action","Sci-Fi"],"min_rating":7.5,"runtime_min":90,"runtime_max":210,"year_start":2000,"year_end":2024,"keyword":null,"top_n":10}'
```

## Jalankan test

```bash
pip install pytest httpx
python -m pytest tests -q
```

## Kapan model asli dipasang

Setelah Tahap 3 (modeling + export `.pkl`) selesai:

```python
# main.py
recommender.load_model("model/best_model.pkl")
```

Lalu di `Recommender.recommend`, alih-alih `_score` dummy, panggil model untuk
memprediksi klaster input lalu KNN / cosine similarity di dalam klaster itu.
Interface API tidak perlu berubah.

## Catatan

- `app/data/movies.json` sekarang dipakai stub. Nanti diganti katalog hasil
  preprocessing (film unik dari 16 CSV).
- `pandas`, `numpy`, `scikit-learn`, `joblib` di `requirements.txt` memang
  belum dipakai stub, tapi sengaja dicantumkan karena akan dipakai Tahap 2-3.
