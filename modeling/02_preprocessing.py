"""
Tahap 2 (lanjutan) - Preprocessing & Feature Engineering
Sistem Rekomendasi Film - Kelompok 5

Input : data/processed/movies_dedup.csv  (hasil 01_eda.py)
Output: data/processed/movies_features.csv  (siap modeling)
        data/processed/preprocess_summary.json

Langkah:
  1. Filter baris yang layak dipakai (punya year, rating, votes, runtime)
  2. Imputasi certificate (modus) & director/star (string kosong)
  3. Transformasi votes -> log1p (skewed)
  4. Feature engineering:
       - MultiLabelBinarizer genre  -> 27 kolom biner
       - TF-IDF sinopsis (opsional, dimatikan default: mahal & jarang dipakai
         di kriteria API; nyalakan pakai --tfidf)
       - Scaling: StandardScaler buat numerik
  5. Simpan matriks fitur + metadata kolom

Jalankan:
  python 02_preprocessing.py
  python 02_preprocessing.py --tfidf          # kalau mau TF-IDF sinopsis
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import MultiLabelBinarizer, StandardScaler

ROOT = Path(__file__).resolve().parents[1]
PROC_DIR = ROOT / "data" / "processed"

# Kolom yang dipakai API Flutter -> harus konsisten dengan app/schemas.py
NUMERIC_FEATURES = ["year", "rating", "runtime", "votes_log", "gross_log"]


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


def load_clean() -> pd.DataFrame:
    df = pd.read_csv(PROC_DIR / "movies_dedup.csv")
    # genre di simpan sebagai string list -> kembalikan ke list asli
    df["genre"] = df["genre"].apply(_parse_genre_list)
    return df


def filter_layak(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Buang baris yang nggak bisa dipakai model."""
    n0 = len(df)
    mask = (
        df["year"].notna()
        & df["rating"].notna()
        & df["votes"].notna()
        & df["runtime"].notna()
        & (df["runtime"] > 0)
        & (df["year"] >= 1900)          # buang tahun ngaco di bawah 1900
        & (df["year"] <= 2026)          # buang tahun di masa depan
    )
    clean = df[mask].copy().reset_index(drop=True)
    stat = {"sebelum": int(n0), "sesudah": int(len(clean)), "dibuang": int(n0 - len(clean))}
    print(f"  filter layak: {n0} -> {len(clean)} (buang {n0 - len(clean)})")
    return clean, stat


def imputasi(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    modus_cert = df["certificate"].mode().iloc[0] if not df["certificate"].mode().empty else "Unrated"
    df["certificate"] = df["certificate"].fillna(modus_cert)
    for col in ("director", "star", "description"):
        df[col] = df[col].fillna("").replace("nan", "")
    return df


def transformasi_numerik(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["votes_log"] = np.log1p(df["votes"])
    df["gross_log"] = np.log1p(df["gross(in $)"].fillna(0))
    return df


def genre_binary(df: pd.DataFrame) -> tuple[np.ndarray, list[str], MultiLabelBinarizer]:
    mlb = MultiLabelBinarizer()
    matrix = mlb.fit_transform(df["genre"])
    print(f"  genre binary: {matrix.shape[1]} kolom -> {mlb.classes_.tolist()}")
    return matrix, list(mlb.classes_), mlb


def scaling(df: pd.DataFrame) -> tuple[np.ndarray, StandardScaler]:
    scaler = StandardScaler()
    matrix = scaler.fit_transform(df[NUMERIC_FEATURES].to_numpy(dtype=float))
    return matrix, scaler


def tfidf_matrix(
    df: pd.DataFrame, max_features: int = 200
) -> tuple[np.ndarray, TfidfVectorizer]:
    """TF-IDF pada sinopsis, dipakai untuk kemiripan tema cerita (Fase B)."""
    vec = TfidfVectorizer(max_features=max_features, stop_words="english", min_df=5)
    matrix = vec.fit_transform(df["description"].fillna("")).toarray()
    print(f"  TF-IDF: {matrix.shape[1]} fitur")
    return matrix, vec


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--no-tfidf",
        action="store_true",
        help="matikan TF-IDF sinopsis (default: aktif, sesuai panduan Fase B)",
    )
    args = ap.parse_args()

    print("=" * 60)
    print("TAHAP 2 - PREPROCESSING & FEATURE ENGINEERING")
    print("=" * 60)

    print("\n[1] Muat data dedup...")
    df = load_clean()
    print(f"  {len(df)} baris")

    print("\n[2] Filter baris layak...")
    df, stat_filter = filter_layak(df)

    print("\n[3] Imputasi...")
    df = imputasi(df)

    print("\n[4] Transformasi numerik (log1p)...")
    df = transformasi_numerik(df)

    print("\n[5] Feature engineering...")
    g_matrix, genre_cols, mlb = genre_binary(df)
    n_matrix, scaler = scaling(df)

    parts = [n_matrix, g_matrix]
    feature_names = NUMERIC_FEATURES + [f"genre_{g}" for g in genre_cols]
    tfidf_info = {"aktif": False, "n_fitur": 0}

    if not args.no_tfidf:
        t_matrix, vec = tfidf_matrix(df)
        parts.append(t_matrix)
        feature_names += [f"tfidf_{w}" for w in vec.get_feature_names_out().tolist()]
        tfidf_info = {
            "aktif": True,
            "n_fitur": int(t_matrix.shape[1]),
            "max_features": 200,
            "sumber": "description (sinopsis film)",
        }
        np.save(PROC_DIR / "tfidf_matrix.npy", t_matrix)

    X = np.hstack(parts)
    print(f"  matriks fitur final: {X.shape}")

    # simpan matriks + nama kolom
    np.save(PROC_DIR / "X_features.npy", X)
    df.to_csv(PROC_DIR / "movies_features.csv", index=False)
    (PROC_DIR / "feature_names.json").write_text(
        json.dumps(feature_names, ensure_ascii=False), encoding="utf-8"
    )

    # simpan artefak preprocessing buat backend nanti
    import joblib

    joblib.dump(mlb, PROC_DIR / "mlb_genre.joblib")
    joblib.dump(scaler, PROC_DIR / "scaler.joblib")
    if not args.no_tfidf:
        joblib.dump(vec, PROC_DIR / "tfidf.joblib")

    ringkas = {
        "filter": stat_filter,
        "n_fitur": int(X.shape[1]),
        "feature_names": feature_names,
        "genre_columns": genre_cols,
        "numeric_features": NUMERIC_FEATURES,
        "tfidf": tfidf_info,
        "genre_value_counts": {
            g: int(sum(g in gs for gs in df["genre"])) for g in genre_cols
        },
    }
    (PROC_DIR / "preprocess_summary.json").write_text(
        json.dumps(ringkas, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"\nRingkas: {json.dumps(stat_filter)}")
    print(f"Output: {PROC_DIR}")


if __name__ == "__main__":
    main()
