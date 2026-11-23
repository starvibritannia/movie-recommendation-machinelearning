"""
Artefak gabungan buat backend FastAPI.

Isi file .joblib:
  scaler        : StandardScaler (5 fitur numerik)
  mlb           : MultiLabelBinarizer (genre)
  model         : model clustering pemenang (punya .labels_ / .predict)
  labels        : array klaster untuk seluruh katalog
  movie_ids     : daftar movie_id sejajar dengan labels
  catalog       : list[dict] katalog film (bentuk API)

Backend tinggal load satu file ini lalu:
  1. ubah kriteria user -> vektor fitur -> scaler.transform -> model.predict
  2. ambil film di klaster tsb -> hitung cosine similarity -> Top-N

Jalankan:
  python 04_export_backend.py
"""

from __future__ import annotations

import ast
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
PROC_DIR = ROOT / "data" / "processed"
MODEL_DIR = ROOT / "modeling" / "models"
OUT_DIR = ROOT / "backend" / "app" / "data"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def _parse_genre_list(value) -> list:
    """Kembalikan string list genre dari CSV menjadi list Python."""
    if isinstance(value, list):
        return value
    if not isinstance(value, str) or not value.strip().startswith("["):
        return []
    try:
        parsed = ast.literal_eval(value)
    except (ValueError, SyntaxError):
        return []
    return parsed if isinstance(parsed, list) else []


def main() -> None:
    results = json.loads((PROC_DIR / "modeling_results.json").read_text(encoding="utf-8"))
    winner = results["winner"]
    print(f"model pemenang: {winner}")

    # nama file model (lihat 03_modeling.py)
    MODEL_FILE = {"K-Means": "kmeans", "Agglomerative": "agglomerative", "DBSCAN": "dbscan"}
    LABEL_FILE = {
        "K-Means": "labels_k_means.npy",
        "Agglomerative": "labels_agglomerative.npy",
        "DBSCAN": "labels_dbscan_subsample.npy",
    }

    df = pd.read_csv(PROC_DIR / "movies_features.csv")
    df["genre"] = df["genre"].apply(_parse_genre_list)

    scaler = joblib.load(PROC_DIR / "scaler.joblib")
    mlb = joblib.load(PROC_DIR / "mlb_genre.joblib")

    # labels pemenang
    labels = np.load(MODEL_DIR / LABEL_FILE[winner])
    assert len(labels) == len(df), f"labels {len(labels)} != data {len(df)}"

    # model pemenang (buat prediksi klaster dari kriteria baru)
    model = joblib.load(MODEL_DIR / f"{MODEL_FILE[winner]}.joblib")

    # katalog versi API
    def to_list(x: str) -> list:
        return [p.strip() for p in x.split(",") if p.strip()] if x else []

    catalog = []
    for _, r in df.iterrows():
        catalog.append({
            "movie_id": str(r["movie_id"]),
            "movie_name": str(r["movie_name"]),
            "year": int(r["year"]) if pd.notna(r["year"]) else None,
            "certificate": str(r["certificate"]) if pd.notna(r["certificate"]) else "Unrated",
            "runtime": int(r["runtime"]) if pd.notna(r["runtime"]) else None,
            "genre": list(r["genre"]),
            "rating": float(r["rating"]) if pd.notna(r["rating"]) else None,
            "votes": int(r["votes"]) if pd.notna(r["votes"]) else None,
            "description": str(r["description"]) if pd.notna(r["description"]) else "",
            "director": str(r["director"]) if pd.notna(r["director"]) else "-",
            "star": to_list(str(r["star"])) if pd.notna(r["star"]) else [],
            "gross": float(r["gross(in $)"]) if pd.notna(r["gross(in $)"]) else 0.0,
            "cluster_label": int(labels[_]),
        })

    bundle = {
        "scaler": scaler,
        "mlb": mlb,
        "model": model,
        "labels": labels,
        "movie_ids": df["movie_id"].astype(str).tolist(),
        "catalog": catalog,
        "winner": winner,
        "feature_names": json.loads((PROC_DIR / "feature_names.json").read_text(encoding="utf-8")),
    }

    # TF-IDF sinopsi (Fase B) kalau ada.
    tfidf_path = PROC_DIR / "tfidf_matrix.npy"
    vec_path = PROC_DIR / "tfidf.joblib"
    if tfidf_path.exists() and vec_path.exists():
        # float32 agar bundle tidak membengkak (200 fitur x 127k film).
        bundle["tfidf_matrix"] = np.load(tfidf_path).astype(np.float32)
        bundle["tfidf_vectorizer"] = joblib.load(vec_path)
        print(f"  TF-IDF: {bundle['tfidf_matrix'].shape[1]} fitur sinopsis (float32)")
    joblib.dump(bundle, OUT_DIR / "model_bundle.joblib")

    # katalog juga disimpan sebagai JSON for human-readable
    (OUT_DIR / "catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False), encoding="utf-8"
    )

    ukuran = (OUT_DIR / "model_bundle.joblib").stat().st_size
    print(f"film di katalog : {len(catalog)}")
    print(f"klaster         : {len(set(labels))}")
    print(f"bundle          : {ukuran / 1e6:.1f} MB -> {OUT_DIR / 'model_bundle.joblib'}")


if __name__ == "__main__":
    main()
