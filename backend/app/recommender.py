"""Mesin rekomendasi.

Arsitektur dibuat dua lapis:

1. [Recommender] di file ini: penanggung jawab mengambil katalog, menilai
   kemiripan, dan membungkus hasil.
2. Model clustering asli (.pkl) nanti dipasang lewat [Recommender.load_model],
   lalu [Recommender.recommend] tinggal memanggilnya.

Selama model belum ada, perhitungan pakai data dummy dengan skor deterministik
supaya UI Flutter tetap bisa ditest dari ujung ke ujung.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from .schemas import HealthResponse, RecommendRequest

# Pemetaan genre -> klaster. Angkanya bebas (dipakailabel klaster di UI).
GENRE_CLUSTER: Dict[str, int] = {
    "Action": 1,
    "Adventure": 1,
    "Drama": 2,
    "Crime": 2,
    "Biography": 2,
    "History": 2,
    "Sci-Fi": 3,
    "Fantasy": 3,
    "Horror": 4,
    "Thriller": 4,
    "Mystery": 4,
    "Film-Noir": 4,
    "Comedy": 5,
    "Romance": 5,
    "Musical": 5,
    "Music": 5,
    "Animation": 5,
    "Family": 5,
}

DEFAULT_CLUSTER = 6


class Recommender:
    """Ambil katalog film, hitung kemiripan, kembalikan Top-N."""

    def __init__(self, movies_path: str) -> None:
        self.movies: List[Dict[str, Any]] = self._load_movies(Path(movies_path))
        self.model_loaded = False
        self.model_name: Optional[str] = None
        self.cluster_count = 0

    # ---------------------------------------------------------------- model
    def load_model(self, model_path: str) -> None:
        """
        Pasang model clustering asli.

        Contoh pemakaian nanti (setelah Tahap 3 selesai):
            recommender.load_model("model/best_model.pkl")
        """
        path = Path(model_path)
        if not path.exists():
            raise FileNotFoundError(f"Model tidak ditemukan: {path}")

        # import joblib di sini supaya stub tetap jalan tanpa scikit-learn
        import joblib  # noqa: PLC0415

        self._model = joblib.load(path)
        self.model_loaded = True
        self.model_name = "kmeans"
        self.cluster_count = int(getattr(self._model, "n_clusters", 0))

    def health(self) -> HealthResponse:
        return HealthResponse(
            status="ok",
            model_loaded=self.model_loaded,
            model_name=self.model_name,
            cluster_count=self.cluster_count,
        )

    # ---------------------------------------------------------- rekomendasi
    def recommend(self, criteria: RecommendRequest) -> Dict[str, Any]:
        start = time.perf_counter()

        pool = self._filter(self.movies, criteria)
        if not pool:
            # Filter memang nggak nemu apa-apa, longgarkan supaya UI tetap ada
            # isi. Kalau hasilnya sedikit, kita kembalikan apa adanya.
            pool = self.movies

        scored = [(self._score(movie, criteria), movie) for movie in pool]
        scored.sort(key=lambda item: item[0], reverse=True)
        top = scored[: criteria.top_n]

        predicted_cluster = self._predict_cluster(criteria, top)
        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)

        return {
            "recommendations": [
                {**movie, "match_percent": round(score, 1)} for score, movie in top
            ],
            "predicted_cluster": predicted_cluster,
            "total_candidates": len(pool),
            "elapsed_ms": elapsed_ms,
        }

    # ------------------------------------------------------------- internal
    @staticmethod
    def _load_movies(path: Path) -> List[Dict[str, Any]]:
        if not path.exists():
            raise FileNotFoundError(f"File katalog film tidak ditemukan: {path}")
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    @staticmethod
    def _filter(
        movies: List[Dict[str, Any]], criteria: RecommendRequest
    ) -> List[Dict[str, Any]]:
        def passes(movie: Dict[str, Any]) -> bool:
            year = movie.get("year")
            runtime = movie.get("runtime")
            rating = movie.get("rating")
            genres = set(movie.get("genre", []))

            if criteria.genres and not (genres & set(criteria.genres)):
                return False
            if year is not None and not (criteria.year_start <= year <= criteria.year_end):
                return False
            if runtime is not None and not (
                criteria.runtime_min <= runtime <= criteria.runtime_max
            ):
                return False
            if rating is not None and rating < criteria.min_rating:
                return False
            return True

        return [movie for movie in movies if passes(movie)]

    @staticmethod
    def _score(movie: Dict[str, Any], criteria: RecommendRequest) -> float:
        """Skor kemiripan 0-100, deterministik (bukan ML asli)."""
        score = 0.0

        # Genre paling menentukan.
        if criteria.genres:
            overlap = len(set(movie.get("genre", [])) & set(criteria.genres))
            score += 55.0 * (overlap / len(criteria.genres))
        else:
            score += 55.0

        # Rating & popularitas.
        rating = movie.get("rating")
        if rating is not None:
            score += 18.0 * (rating / 10.0)
            if rating >= criteria.min_rating:
                score += 6.0

        # Durasi & tahun termasuk rentang.
        runtime = movie.get("runtime")
        if runtime is not None and criteria.runtime_min <= runtime <= criteria.runtime_max:
            score += 8.0

        year = movie.get("year")
        if year is not None and criteria.year_start <= year <= criteria.year_end:
            score += 7.0

        # Kata kunci muncul di judul atau sinopsis.
        if criteria.keyword:
            keyword = criteria.keyword.lower()
            name = str(movie.get("movie_name", "")).lower()
            description = str(movie.get("description", "")).lower()
            if keyword in name:
                score += 12.0
            elif keyword in description:
                score += 8.0

        return max(0.0, min(score, 100.0))

    @staticmethod
    def _predict_cluster(
        criteria: RecommendRequest, top: List[tuple]
    ) -> int:
        if criteria.genres:
            for genre in criteria.genres:
                if genre in GENRE_CLUSTER:
                    return GENRE_CLUSTER[genre]
        if top:
            for genre in top[0][1].get("genre", []):
                if genre in GENRE_CLUSTER:
                    return GENRE_CLUSTER[genre]
        return DEFAULT_CLUSTER
