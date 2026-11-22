"""
FilmMatch API (stub).

Server FastAPI untuk aplikasi rekomendasi film. Sekarang isinya masih data
dummy dengan penilaian deterministik, tapi strukturnya disiapkan supaya model
klustering asli (K-Means / Agglomerative / DBSCAN) bisa dipasang tanpa ubah
interface.

Jalankan:
    cd backend
    python -m uvicorn main:app --reload --port 8000

Buka docs interaktif:
    http://127.0.0.1:8000/docs
"""

from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.recommender import Recommender
from app.schemas import (
    HealthResponse,
    RecommendRequest,
    RecommendResponse,
)

# Katalog dummy lokal. Kalau bundle model ada, katalog asli otomatis dipakai.
MOVIES_PATH = "app/data/movies.json"
BUNDLE_PATH = Path(__file__).resolve().parent / "app" / "data" / "model_bundle.joblib"

# Dipakai sederhana dulu: satu objek recommender global.
recommender = Recommender(
    MOVIES_PATH,
    bundle_path=str(BUNDLE_PATH) if BUNDLE_PATH.exists() else None,
)

app = FastAPI(
    title="FilmMatch Recommendation API",
    version="0.1.0",
    description="Stub backend untuk sistem rekomendasi film 2-tahap (clustering + similarity).",
)

# CORS dibuka lebar supaya gampang dites dari browser / Swagger UI.
# Di produksi sebaiknya dipersempit ke origin aplikasi saja.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["meta"])
def root() -> dict:
    return {
        "name": "FilmMatch API",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
        "recommend": "/recommend",
    }


@app.get("/health", response_model=HealthResponse, tags=["meta"])
def health() -> HealthResponse:
    """Cek server hidup + status model .pkl (belum dimuat di stub ini)."""
    return recommender.health()


@app.post("/recommend", response_model=RecommendResponse, tags=["recommend"])
def recommend(payload: RecommendRequest) -> RecommendResponse:
    """
    Terima kriteria film dari Flutter, balik daftar film paling mirip.

    Selama model .pkl belum ada, hasil dihitung dari data dummy dengan
    penilaian kemiripan yang deterministik, supaya UI bisa ditest end-to-end.
    """
    return recommender.recommend(payload)
