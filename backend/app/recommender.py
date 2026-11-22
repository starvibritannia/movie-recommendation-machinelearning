"""Mesin rekomendasi (versi model asli).

Dua tahap sesuai rancangan:
  1. Makro : kriteria user -> vektor fitur -> scaler -> model clustering
             -> predicted_cluster.
  2. Mikro : di dalam pool (filter + klaster), hitung cosine similarity
             vektor fitur film terhadap vektor kriteria -> Top-N.

Kalau `model_bundle.joblib` belum ada, fallback ke katalog dummy + skor
deterministik supaya app tetap bisa ditest dari ujung ke ujung.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from .schemas import HealthResponse, RecommendRequest

# Pemetaan genre -> klaster (dipakai hanya saat fallback dummy).
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

# Bawaan kriteria -> dipakai buat mengisi fitur yang tidak diberi user.
DEFAULTS = {
    "year": 2000.0,
    "rating": 7.0,
    "runtime": 100.0,
    "votes": 500.0,
    "gross": 1_000_000.0,
}


class Recommender:
    """Ambil katalog film, hitung kemiripan, kembalikan Top-N."""

    def __init__(self, movies_path: str, bundle_path: Optional[str] = None) -> None:
        self.movies: List[Dict[str, Any]] = self._load_movies(Path(movies_path))
        self.model_loaded = False
        self.model_name: Optional[str] = None
        self.cluster_count = 0
        self._bundle: Optional[Dict[str, Any]] = None
        # TF-IDF sinopsis (Fase B) kalau ada di bundle.
        self._tfidf_matrix = None
        self._tfidf_vec = None

        if bundle_path:
            self.load_model(bundle_path)

    # ---------------------------------------------------------------- model
    def load_model(self, model_path: str) -> None:
        """Pasang bundle model (scaler, mlb, model clustering, katalog)."""
        path = Path(model_path)
        if not path.exists():
            raise FileNotFoundError(f"Model tidak ditemukan: {path}")

        import joblib  # noqa: PLC0415

        bundle = joblib.load(path)
        self._bundle = bundle
        self.model_loaded = True
        self.model_name = bundle.get("winner", "unknown")
        self.cluster_count = int(len(set(bundle["labels"].tolist())))

        if bundle.get("catalog"):
            self.movies = bundle["catalog"]

        self._tfidf_matrix = bundle.get("tfidf_matrix")
        self._tfidf_vec = bundle.get("tfidf_vectorizer")

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
        if self.model_loaded:
            return self._recommend_ml(criteria, start)
        return self._recommend_stub(criteria, start)

    # ------------------------------------------------------------- ML asli
    def _recommend_ml(self, criteria: RecommendRequest, start: float) -> Dict[str, Any]:
        import numpy as np
        from sklearn.metrics.pairwise import cosine_similarity

        b = self._bundle
        labels = np.asarray(b["labels"])
        movie_ids = list(b["movie_ids"])
        scaler = b["scaler"]
        mlb = b["mlb"]
        model = b["model"]

        # 1. Filter katalog berdasarkan kriteria eksplisit
        pool = self._filter(self.movies, criteria)
        if not pool:
            pool = self.movies

        # petakan movie_id -> indeks labels (sekali, O(n))
        id_to_idx = {mid: i for i, mid in enumerate(movie_ids)}
        # buang film yang tidak ada di katalog model supaya array sejajar
        pool = [m for m in pool if m["movie_id"] in id_to_idx]

        # 1b. Kata kunci: saring di judul/deskripsi. Kalau terlalu ketat dan
        # hasilnya kosong, kembali ke pool sebelumnya supaya UI tetap ada isi.
        if criteria.keyword:
            kw = criteria.keyword.lower()
            ketemu = [
                m for m in pool
                if kw in str(m.get("movie_name", "")).lower()
                or kw in str(m.get("description", "")).lower()
            ]
            if ketemu:
                pool = ketemu

        # 2. Vektor kriteria user -> prediksi klaster
        q_vec = self._criteria_vector(criteria, mlb)
        q_scaled = self._scale_matrix(q_vec, scaler)
        try:
            predicted = int(model.predict(q_scaled)[0])
        except Exception:
            predicted = int(np.bincount(labels).argmax())

        # 2b. Tahap 2 (mikro): pencarian kemiripan dilakukan DI DALAM klaster
        #     yang diprediksi (sesuai konsep 2-tahap), bukan di seluruh katalog.
        #     Kalau klaster itu kosong untuk filter user, kembali ke pool.
        pool_klaster = [
            m for m in pool if labels[id_to_idx[m["movie_id"]]] == predicted
        ]
        if pool_klaster:
            pool = pool_klaster

        # 3. Cosine similarity antara vektor film dan vektor kriteria
        X_pool, pool = self._matrix_for_movies(pool, mlb, id_to_idx)
        X_pool = self._scale_matrix(X_pool, scaler)
        sims = cosine_similarity(X_pool, q_scaled).ravel()

        # 4. Skor gabungan. Similaritas kosong/tak informatif kalau user tidak
        #    memberi genre, maka popularitas & rating diberi porsi lebih besar.
        cluster_bonus = np.array([
            1.0 if labels[id_to_idx[m["movie_id"]]] == predicted else 0.0
            for m in pool
        ])
        ratings = np.array([(m.get("rating") or 0.0) / 10.0 for m in pool])
        votes_log = np.log1p(np.array([m.get("votes") or 0.0 for m in pool]))
        votes_norm = votes_log / votes_log.max() if votes_log.max() > 0 else votes_log

        score = (
            0.40 * sims
            + 0.20 * cluster_bonus
            + 0.20 * ratings
            + 0.20 * votes_norm
        )
        if score.max() > 0:
            score = 100.0 * (score / score.max())

        urut = np.argsort(-score)[: criteria.top_n]
        top = [pool[i] for i in urut]
        top_score = score[urut]

        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
        return {
            "recommendations": [
                {**movie, "match_percent": round(float(s), 1)}
                for movie, s in zip(top, top_score)
            ],
            "predicted_cluster": predicted,
            "total_candidates": len(pool),
            "elapsed_ms": elapsed_ms,
        }

    # ------------------------------------------------------------- stub
    def _recommend_stub(self, criteria: RecommendRequest, start: float) -> Dict[str, Any]:
        pool = self._filter(self.movies, criteria)
        if not pool:
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

    # ------------------------------------------------------------- fitur
    @staticmethod
    def _scale_matrix(X: np.ndarray, scaler) -> np.ndarray:
        """Scalisasi hanya 5 kolom numerik; sisanya (genre biner) dibiarkan."""
        import numpy as np

        num = scaler.transform(X[:, :5])
        return np.hstack([num, X[:, 5:]])

    def _criteria_vector(self, criteria: RecommendRequest, mlb):
        """Vektor kriteria mentah: 5 numerik + genre biner + TF-IDF (bila ada).

        TF-IDF kriteria memakai kata kunci user sebagai "tema cerita", sejalan
        dengan panduan Fase B (TF-IDF sinopsis).
        """
        import numpy as np

        genre_vec = mlb.transform([criteria.genres or []])[0].reshape(1, -1)
        num = np.array([[
            float(DEFAULTS["year"]),
            float(criteria.min_rating),
            float((criteria.runtime_min + criteria.runtime_max) / 2),
            float(np.log1p(DEFAULTS["votes"])),
            float(np.log1p(DEFAULTS["gross"])),
        ]])

        if self._tfidf_vec is not None:
            kata = criteria.keyword or ""
            tf = self._tfidf_vec.transform([kata]).toarray()
            return np.hstack([num, genre_vec, tf])

        return np.hstack([num, genre_vec])

    def _matrix_for_movies(self, pool: List[Dict[str, Any]], mlb, id_to_idx):
        """Bangun matriks fitur mentah untuk pool film (+ TF-IDF bila ada)."""
        import numpy as np

        rows, valid = [], []
        for movie in pool:
            genre_vec = mlb.transform([movie.get("genre", [])])[0]
            row = np.concatenate([
                [[
                    float(movie.get("year") or DEFAULTS["year"]),
                    float(movie.get("rating") or DEFAULTS["rating"]),
                    float(movie.get("runtime") or DEFAULTS["runtime"]),
                    float(np.log1p(movie.get("votes") or 0.0)),
                    float(np.log1p(movie.get("gross") or 0.0)),
                ]],
                genre_vec.reshape(1, -1),
            ], axis=1)
            rows.append(row)
            valid.append(movie)

        if not rows:
            return np.zeros((0, 5 + len(mlb.classes_))), []

        X = np.vstack(rows)
        if self._tfidf_matrix is not None:
            idx = [id_to_idx[m["movie_id"]] for m in valid]
            X = np.hstack([X, self._tfidf_matrix[idx]])
        return X, valid

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
        """Skor kemiripan 0-100 (fallback dummy)."""
        score = 0.0

        if criteria.genres:
            overlap = len(set(movie.get("genre", [])) & set(criteria.genres))
            score += 55.0 * (overlap / len(criteria.genres))
        else:
            score += 55.0

        rating = movie.get("rating")
        if rating is not None:
            score += 18.0 * (rating / 10.0)
            if rating >= criteria.min_rating:
                score += 6.0

        runtime = movie.get("runtime")
        if runtime is not None and criteria.runtime_min <= runtime <= criteria.runtime_max:
            score += 8.0

        year = movie.get("year")
        if year is not None and criteria.year_start <= year <= criteria.year_end:
            score += 7.0

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
    def _predict_cluster(criteria: RecommendRequest, top: List[tuple]) -> int:
        if criteria.genres:
            for genre in criteria.genres:
                if genre in GENRE_CLUSTER:
                    return GENRE_CLUSTER[genre]
        if top:
            for genre in top[0][1].get("genre", []):
                if genre in GENRE_CLUSTER:
                    return GENRE_CLUSTER[genre]
        return DEFAULT_CLUSTER
