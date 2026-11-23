"""
Tahap 2 - Dataset & EDA
Sistem Rekomendasi Film - Kelompok 5

Alur:
  1. Gabung 16 CSV genre dari Kaggle -> satu DataFrame
  2. Deduplikasi berdasarkan movie_id
  3. EDA: statistik deskriptif, missing value, outlier, distribusi, korelasi
  4. Simpan data mentah gabungan ke parquet/csv

Jalankan:
  python 01_eda.py
Output:
  data/processed/movies_raw.csv        (gabungan sebelum dedup)
  data/processed/movies_dedup.csv      (setelah dedup)
  data/processed/eda_summary.json      (ringkasan EDA buat laporan)
  modeling/figures/*.png               (grafik EDA)
"""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # backend non-interaktif supaya bisa jalan di CLI

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ------------------------------------------------------------------ path
ROOT = Path(__file__).resolve().parents[1]          # C:\Projek Rekomendasi Film
RAW_DIR = ROOT / "data" / "raw"
PROC_DIR = ROOT / "data" / "processed"
FIG_DIR = ROOT / "modeling" / "figures"
for d in (PROC_DIR, FIG_DIR):
    d.mkdir(parents=True, exist_ok=True)

plt.rcParams.update({
    "figure.dpi": 120,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "grid.alpha": 0.25,
})


# ------------------------------------------------------------- 1. memuat
def load_all_csv(raw_dir: Path) -> pd.DataFrame:
    """Baca semua CSV genre, beri penanda asal file, lalu gabung."""
    frames = []
    for path in sorted(raw_dir.glob("*.csv")):
        df = pd.read_csv(path)
        df["_source_file"] = path.stem
        frames.append(df)
        print(f"  {path.name:<18} {len(df):>7} baris")
    merged = pd.concat(frames, ignore_index=True)
    print(f"  {'TOTAL':<18} {len(merged):>7} baris")
    return merged


# ------------------------------------------------------------- 2. dedup
def dedup(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Buang duplikat movie_id, simpan catatan duplikatnya."""
    dup_mask = df.duplicated(subset=["movie_id"], keep=False)
    dup_rows = df[dup_mask].sort_values("movie_id")
    clean = df.drop_duplicates(subset=["movie_id"], keep="first").copy()
    print(f"  duplikat ditemukan : {dup_mask.sum()} baris")
    print(f"  setelah dedup      : {len(clean)} baris")
    return clean, dup_rows


# ------------------------------------------------------------- 3. bersihkan mentah
def clean_raw(df: pd.DataFrame) -> pd.DataFrame:
    """Normalisasi tipe dasar yang bisa dilakukan tanpa mengubah makna data."""
    df = df.copy()
    # year: "2022" / "2022-2025" / "PG-13" (salah isi) -> numerik
    df["year"] = pd.to_numeric(df["year"], errors="coerce")
    # runtime: "161 min" -> 161
    df["runtime"] = (
        df["runtime"].astype(str).str.extract(r"(\d+)")[0].astype(float)
    )
    # genre: "Action, Adventure" -> ["Action", "Adventure"]
    df["genre"] = df["genre"].astype(str).str.split(r"\s*,\s*")
    # star/director: buang newline dan strip
    for col in ("star", "director"):
        df[col] = df[col].astype(str).str.replace(r"\s*\\n\s*", ", ", regex=True).str.strip()
    return df


# ------------------------------------------------------------- 4. EDA
def ringkasan(df: pd.DataFrame) -> dict:
    """Kumpulkan statistik ringkas buat laporan."""
    miss = df.isna().sum().sort_values(ascending=False)
    ringkas = {
        "n_baris": int(len(df)),
        "n_kolom": int(df.shape[1]),
        "n_genre_unik": int(len({g for gs in df["genre"] for g in gs})),
        "missing": {k: int(v) for k, v in miss.items() if v > 0},
        "persen_missing": {
            k: round(float(v) / len(df) * 100, 2)
            for k, v in miss.items()
            if v > 0
        },
        "rentang_tahun": [
            int(df["year"].min()) if not df["year"].isna().all() else None,
            int(df["year"].max()) if not df["year"].isna().all() else None,
        ],
        "statistik_numerik": json.loads(
            df[["year", "rating", "runtime", "votes", "gross(in $)"]]
            .describe()
            .round(3)
            .to_json(orient="index")
        ),
    }
    return ringkas


def plot_distribusi(df: pd.DataFrame, fig_dir: Path) -> None:
    """Histogram kolom numerik."""
    cols = ["year", "rating", "runtime", "votes", "gross(in $)"]
    fig, axes = plt.subplots(2, 3, figsize=(15, 8))
    for ax, col in zip(axes.flat, cols):
        s = df[col].dropna()
        if col in ("votes", "gross(in $)"):
            s = np.log1p(s)
            ax.set_xlabel(f"log1p({col})")
        s.hist(bins=40, ax=ax, color="#FF7A18", edgecolor="none")
        ax.set_title(col)
    axes.flat[-1].axis("off")
    fig.suptitle("Distribusi Kolom Numerik", fontsize=14)
    fig.tight_layout()
    fig.savefig(fig_dir / "01_distribusi.png", bbox_inches="tight")
    plt.close(fig)


def plot_genre(df: pd.DataFrame, fig_dir: Path) -> None:
    """Bar chart 20 genre paling umum (multi-label, bukan exclusive)."""
    counts = {}
    for gs in df["genre"]:
        for g in gs:
            counts[g] = counts.get(g, 0) + 1
    s = pd.Series(counts).sort_values(ascending=False)
    fig, ax = plt.subplots(figsize=(10, 6))
    s.head(20).sort_values().plot.barh(ax=ax, color="#FF7A18")
    ax.set_title("20 Genre Paling Sering Muncul")
    ax.set_xlabel("Jumlah film")
    fig.tight_layout()
    fig.savefig(fig_dir / "02_genre.png", bbox_inches="tight")
    plt.close(fig)
    return s


def plot_boxplot(df: pd.DataFrame, fig_dir: Path) -> None:
    """Boxplot buat deteksi outlier."""
    cols = ["rating", "runtime", "year"]
    fig, axes = plt.subplots(1, 3, figsize=(14, 4.5))
    for ax, col in zip(axes, cols):
        df[col].dropna().plot.box(ax=ax, color="#FF7A18")
        ax.set_title(col)
    fig.suptitle("Boxplot (deteksi outlier)")
    fig.tight_layout()
    fig.savefig(fig_dir / "03_boxplot.png", bbox_inches="tight")
    plt.close(fig)


def plot_heatmap(df: pd.DataFrame, fig_dir: Path) -> None:
    """Heatmap korelasi antar kolom numerik."""
    num = df[["year", "rating", "runtime", "votes", "gross(in $)"]].apply(
        pd.to_numeric, errors="coerce"
    )
    corr = num.corr(numeric_only=True)
    fig, ax = plt.subplots(figsize=(7, 6))
    im = ax.imshow(corr, cmap="coolwarm", vmin=-1, vmax=1)
    ax.set_xticks(range(len(corr.columns)), corr.columns, rotation=45, ha="right")
    ax.set_yticks(range(len(corr.columns)), corr.columns)
    for i in range(len(corr.columns)):
        for j in range(len(corr.columns)):
            ax.text(j, i, f"{corr.iloc[i, j]:.2f}", ha="center", va="center", fontsize=8)
    fig.colorbar(im, ax=ax, shrink=0.8)
    ax.set_title("Heatmap Korelasi Fitur Numerik")
    fig.tight_layout()
    fig.savefig(fig_dir / "04_heatmap.png", bbox_inches="tight")
    plt.close(fig)


def plot_rating_tahun(df: pd.DataFrame, fig_dir: Path) -> None:
    """Scatter rating vs tahun, diwarnai jumlah votes."""
    d = df.dropna(subset=["year", "rating"])
    fig, ax = plt.subplots(figsize=(10, 6))
    sc = ax.scatter(
        d["year"], d["rating"],
        s=np.clip(np.log1p(d["votes"].fillna(0)), 0, 8) * 3,
        alpha=0.35, c="#FF7A18", edgecolors="none",
    )
    ax.set_xlabel("Tahun")
    ax.set_ylabel("Rating")
    ax.set_title("Rating vs Tahun (ukuran = log votes)")
    fig.tight_layout()
    fig.savefig(fig_dir / "05_rating_vs_tahun.png", bbox_inches="tight")
    plt.close(fig)


def plot_missing(df: pd.DataFrame, fig_dir: Path) -> None:
    """Bar chart persentase missing value."""
    miss = (df.isna().mean() * 100).sort_values(ascending=False)
    miss = miss[miss > 0]
    if miss.empty:
        return
    fig, ax = plt.subplots(figsize=(9, 5))
    miss.sort_values().plot.barh(ax=ax, color="#FF4D2D")
    ax.set_xlabel("Missing (%)")
    ax.set_title("Persentase Missing Value per Kolom")
    fig.tight_layout()
    fig.savefig(fig_dir / "06_missing.png", bbox_inches="tight")
    plt.close(fig)


# ------------------------------------------------------------- main
def main() -> None:
    print("=" * 60)
    print("TAHAP 2 - DATASET & EDA")
    print("=" * 60)

    print("\n[1] Memuat 16 CSV genre...")
    merged = load_all_csv(RAW_DIR)
    merged.to_csv(PROC_DIR / "movies_raw.csv", index=False)

    print("\n[2] Deduplikasi berdasarkan movie_id...")
    clean, dup_rows = dedup(merged)
    dup_rows.to_csv(PROC_DIR / "movies_duplicates.csv", index=False)

    print("\n[3] Normalisasi tipe dasar...")
    clean = clean_raw(clean)
    clean.to_csv(PROC_DIR / "movies_dedup.csv", index=False)

    print("\n[4] Ringkasan EDA...")
    ringkas = ringkasan(clean)
    with (PROC_DIR / "eda_summary.json").open("w", encoding="utf-8") as f:
        json.dump(ringkas, f, ensure_ascii=False, indent=2)
    print(json.dumps(ringkas, ensure_ascii=False, indent=2))

    print("\n[5] Visualisasi...")
    plot_distribusi(clean, FIG_DIR)
    genre_counts = plot_genre(clean, FIG_DIR)
    plot_boxplot(clean, FIG_DIR)
    plot_heatmap(clean, FIG_DIR)
    plot_rating_tahun(clean, FIG_DIR)
    plot_missing(clean, FIG_DIR)
    genre_counts.to_csv(PROC_DIR / "genre_counts.csv", header=["count"])

    print(f"\nSelesai. Output di:\n  {PROC_DIR}\n  {FIG_DIR}")


if __name__ == "__main__":
    main()
