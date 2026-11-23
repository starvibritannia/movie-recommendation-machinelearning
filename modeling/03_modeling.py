"""
Tahap 3 - Modeling: Komparasi K-Means, Agglomerative, DBSCAN
Sistem Rekomendasi Film - Kelompok 5

Input : data/processed/X_features.npy, movies_features.csv
Output: modeling/models/*.joblib
        modeling/figures/07_elbow.png, 08_dendrogram.png, 09_pca_clusters.png,
                  10_silhouette.png, 11_dbscan_tuning.png
        data/processed/modeling_results.json

Sesuai panduan (Fase B poin 6): data dibagi 80% training (pembentukan klaster)
dan 20% testing (uji stabilitas klaster pada data yang belum pernah dilihat).
Model menang dipilih berdasarkan silhouette di data test, lalu seluruh katalog
dilabeli untuk dipakai backend.

Evaluasi: Silhouette Score, Davies-Bouldin Index, Calinski-Harabasz,
          Elbow Method, dendrogram, visualisasi PCA.

Jalankan:
  python 03_modeling.py
"""

from __future__ import annotations

import json
import warnings
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import dendrogram, linkage
from sklearn.cluster import AgglomerativeClustering, DBSCAN, KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import (
    calinski_harabasz_score,
    davies_bouldin_score,
    silhouette_samples,
    silhouette_score,
)
from sklearn.model_selection import train_test_split

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parents[1]
PROC_DIR = ROOT / "data" / "processed"
MODEL_DIR = ROOT / "modeling" / "models"
FIG_DIR = ROOT / "modeling" / "figures"
for d in (MODEL_DIR, FIG_DIR):
    d.mkdir(parents=True, exist_ok=True)

RANDOM_STATE = 42
K_RANGE = range(2, 13)
DBSCAN_EPS_GRID = [0.8, 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.0]
TRAIN_FRACTION = 0.8          # panduan Fase B poin 6 (80/20)
EVAL_SIZE = 30000             # sub-sampel train buat evaluasi yang adil


# ---------------------------------------------------------------- util
def metrik(X: np.ndarray, labels: np.ndarray) -> dict:
    """Hitung metrik evaluasi klaster (diabaikan kalau cuma 1 klaster)."""
    n_klaster = len(set(labels)) - (1 if -1 in labels else 0)
    if n_klaster < 2:
        return {
            "n_clusters": int(n_klaster),
            "silhouette": None,
            "davies_bouldin": None,
            "calinski_harabasz": None,
        }
    mask = labels != -1
    if mask.sum() < 2:
        return {
            "n_clusters": int(n_klaster),
            "silhouette": None,
            "davies_bouldin": None,
            "calinski_harabasz": None,
        }
    Xv, lv = X[mask], labels[mask]
    if len(set(lv)) < 2 or len(set(lv)) >= len(lv):
        return {
            "n_clusters": int(n_klaster),
            "silhouette": None,
            "davies_bouldin": None,
            "calinski_harabasz": None,
        }
    try:
        sil = silhouette_score(
            Xv, lv, sample_size=min(5000, len(lv)), random_state=RANDOM_STATE
        )
    except ValueError:
        return {
            "n_clusters": int(n_klaster),
            "silhouette": None,
            "davies_bouldin": None,
            "calinski_harabasz": None,
        }
    return {
        "n_clusters": int(n_klaster),
        "noise_points": int((labels == -1).sum()),
        "silhouette": round(float(sil), 4),
        "davies_bouldin": round(float(davies_bouldin_score(Xv, lv)), 4),
        "calinski_harabasz": round(float(calinski_harabasz_score(Xv, lv)), 2),
    }


def simpan(labels: np.ndarray, path: Path) -> None:
    np.save(path, labels)


# ------------------------------------------------------------- K-Means
def latih_kmeans(X_train: np.ndarray) -> tuple[KMeans, dict]:
    print("\n[K-Means] Elbow + Silhouette di data training...")
    rows = []
    for k in K_RANGE:
        km = KMeans(n_clusters=k, random_state=RANDOM_STATE, n_init=10)
        labels = km.fit_predict(X_train)
        sil = silhouette_score(
            X_train, labels, sample_size=8000, random_state=RANDOM_STATE
        )
        rows.append({"k": k, "inertia": km.inertia_, "silhouette": round(float(sil), 4)})
        print(f"  k={k:<2} inertia={km.inertia_:>12.0f}  silhouette={sil:.4f}")

    tabel = pd.DataFrame(rows)
    best_k = int(tabel.loc[tabel["silhouette"].idxmax(), "k"])
    final = KMeans(n_clusters=best_k, random_state=RANDOM_STATE, n_init=10)
    final.fit(X_train)

    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    axes[0].plot(tabel["k"], tabel["inertia"], marker="o", color="#FF7A18")
    axes[0].set_title("Elbow Method (train)")
    axes[0].set_xlabel("k")
    axes[0].set_ylabel("Inertia")
    axes[0].axvline(best_k, ls="--", c="grey", alpha=0.6)
    axes[1].plot(tabel["k"], tabel["silhouette"], marker="o", color="#FF4D2D")
    axes[1].set_title("Silhouette per k (train)")
    axes[1].set_xlabel("k")
    axes[1].axvline(best_k, ls="--", c="grey", alpha=0.6)
    fig.tight_layout()
    fig.savefig(FIG_DIR / "07_elbow.png", bbox_inches="tight")
    plt.close(fig)

    return final, {"k": best_k, "labels": final.labels_.copy(), "tuning": tabel.to_dict("records")}


# ------------------------------------------------------------- Agglomerative
def latih_agglomerative(X_train: np.ndarray) -> tuple[KMeans, dict]:
    print("\n[Agglomerative] dendrogram + evaluasi per k...")
    # Ward penuh O(n^2) butuh ~60 GB untuk 100k data, jadi dendrogram &
    # penentuan k dijalankan di sampel training.
    rng = np.random.RandomState(RANDOM_STATE)
    sample_idx = rng.choice(len(X_train), size=8000, replace=False)
    Xs = X_train[sample_idx]

    Z = linkage(Xs, method="ward")
    fig, ax = plt.subplots(figsize=(12, 5))
    dendrogram(Z, ax=ax, truncate_mode="lastp", p=20, show_leaf_counts=True)
    ax.set_title("Dendrogram (sampel training 8000, method=ward)")
    ax.set_xlabel("Klaster")
    ax.set_ylabel("Jarak")
    fig.tight_layout()
    fig.savefig(FIG_DIR / "08_dendrogram.png", bbox_inches="tight")
    plt.close(fig)

    rows = []
    best_k = 2
    best_sil = -1.0
    for k in K_RANGE:
        agg = AgglomerativeClustering(n_clusters=k, linkage="ward")
        labels = agg.fit_predict(Xs)
        sil = silhouette_score(
            Xs, labels, sample_size=min(5000, len(Xs)), random_state=RANDOM_STATE
        )
        rows.append({"k": k, "silhouette": round(float(sil), 4)})
        print(f"  k={k:<2} silhouette(sampel)={sil:.4f}")
        if sil > best_sil:
            best_sil, best_k = sil, k

    ward_s = AgglomerativeClustering(n_clusters=best_k, linkage="ward").fit(Xs)
    centroids = np.vstack([Xs[ward_s.labels_ == i].mean(axis=0) for i in range(best_k)])
    final = KMeans(n_clusters=best_k, init=centroids, n_init=1, random_state=RANDOM_STATE)
    final.fit(X_train)

    info = {
        "k": best_k,
        "labels": final.labels_.copy(),
        "tuning": rows,
        "metode": "ward(sampel train) -> centroid -> kmeans",
    }
    return final, info


# ------------------------------------------------------------- DBSCAN
def latih_dbscan(X_train: np.ndarray, idx: np.ndarray) -> tuple[DBSCAN, dict]:
    print("\n[DBSCAN] tuning eps (sub-sampel training)...")
    Xd = X_train[idx]

    rows = []
    best = None
    best_labels = None
    for eps in DBSCAN_EPS_GRID:
        db = DBSCAN(eps=eps, min_samples=10)
        labels = db.fit_predict(Xd)
        m = metrik(Xd, labels)
        rows.append({"eps": eps, **m})
        print(
            f"  eps={eps:<4} klaster={m['n_clusters']}  noise={m.get('noise_points')}  sil={m['silhouette']}"
        )
        if m["silhouette"] is not None and (
            best is None or m["silhouette"] > best[1]["silhouette"]
        ):
            best = (eps, m)
            best_labels = labels

    if best is None:
        best = (DBSCAN_EPS_GRID[0], {"n_clusters": 0, "silhouette": None})

    eps = best[0]
    final = DBSCAN(eps=eps, min_samples=10)
    labels = final.fit_predict(Xd) if best_labels is None else best_labels

    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    axes[0].plot(
        [r["eps"] for r in rows], [r["n_clusters"] for r in rows],
        marker="o", color="#FF7A18",
    )
    axes[0].set_title("DBSCAN: jumlah klaster vs eps")
    axes[0].set_xlabel("eps")
    axes[1].plot(
        [r["eps"] for r in rows], [r["silhouette"] or 0 for r in rows],
        marker="o", color="#FF4D2D",
    )
    axes[1].set_title("DBSCAN: silhouette vs eps")
    axes[1].set_xlabel("eps")
    fig.tight_layout()
    fig.savefig(FIG_DIR / "11_dbscan_tuning.png", bbox_inches="tight")
    plt.close(fig)

    info = {
        "eps": eps,
        "min_samples": 10,
        "labels": labels,
        "tuning": rows,
        "metode": "sub-sampel training (O(n^2) tidak feasible)",
        "subsample_idx": idx,
    }
    return final, info


# ------------------------------------------------------------- visualisasi
def _eval_view(X: np.ndarray, info: dict, idx: np.ndarray):
    labels = info["labels"]
    if len(labels) == len(X):
        return X[idx], labels[idx]
    return X[idx], labels


def plot_pca(X: np.ndarray, results: dict, idx: np.ndarray) -> None:
    print("\n[PCA] visualisasi klaster...")
    Xs = X[idx]
    pca = PCA(n_components=2, random_state=RANDOM_STATE)
    coords = pca.fit_transform(Xs)

    fig, axes = plt.subplots(1, 3, figsize=(18, 5.5))
    for ax, (nama, info) in zip(axes, results.items()):
        _, labels = _eval_view(X, info, idx)
        for lab in sorted(set(labels)):
            mask = labels == lab
            ax.scatter(
                coords[mask, 0], coords[mask, 1], s=4, alpha=0.5,
                label=f"C{lab}" if lab != -1 else "noise",
            )
        ax.set_title(f"{nama}\n(n_clusters={len(set(labels) - {-1})})")
        ax.set_xlabel("PC1")
        ax.set_ylabel("PC2")
    fig.suptitle(
        f"PCA (explained var: {pca.explained_variance_ratio_.round(3).tolist()})"
    )
    fig.tight_layout()
    fig.savefig(FIG_DIR / "09_pca_clusters.png", bbox_inches="tight")
    plt.close(fig)


def plot_silhouette(X: np.ndarray, results: dict, idx: np.ndarray) -> None:
    fig, axes = plt.subplots(1, 3, figsize=(18, 5.5))
    for ax, (nama, info) in zip(axes, results.items()):
        Xu, labels = _eval_view(X, info, idx)
        mask = labels != -1
        Xu, lu = Xu[mask], labels[mask]
        if len(set(lu)) < 2:
            ax.set_title(f"{nama} (n/a)")
            continue
        samp = silhouette_samples(Xu, lu)
        if len(Xu) > 8000:
            sub = np.random.RandomState(RANDOM_STATE).choice(
                len(Xu), size=8000, replace=False
            )
            samp = samp[sub]
            lu = lu[sub]
        y_lower = 0
        for lab in sorted(set(lu)):
            vals = samp[lu == lab]
            vals.sort()
            y_upper = y_lower + len(vals)
            ax.fill_betweenx(np.arange(y_lower, y_upper), 0, vals, alpha=0.7)
            y_lower = y_upper + 2
        ax.set_title(f"{nama} (rata-rata: {samp.mean():.3f})")
        ax.set_xlabel("Koefisien silhouette")
        ax.axvline(samp.mean(), ls="--", c="red", alpha=0.6)
    fig.tight_layout()
    fig.savefig(FIG_DIR / "10_silhouette.png", bbox_inches="tight")
    plt.close(fig)


# ------------------------------------------------------------- main
def main() -> None:
    print("=" * 60)
    print("TAHAP 3 - MODELING 3 ALGORITMA CLUSTERING")
    print("=" * 60)

    X = np.load(PROC_DIR / "X_features.npy")
    print(f"  matriks fitur: {X.shape}")

    # --- Split 80/20 sesuai panduan Fase B poin 6 ---
    all_idx = np.arange(len(X))
    train_idx, test_idx = train_test_split(
        all_idx, test_size=1.0 - TRAIN_FRACTION, random_state=RANDOM_STATE, shuffle=True
    )
    X_train, X_test = X[train_idx], X[test_idx]
    np.save(MODEL_DIR / "train_idx.npy", train_idx)
    np.save(MODEL_DIR / "test_idx.npy", test_idx)
    print(
        f"  split 80/20: train={len(train_idx)} ({len(train_idx)/len(X)*100:.1f}%) "
        f"test={len(test_idx)} ({len(test_idx)/len(X)*100:.1f}%)"
    )

    eval_idx = np.random.RandomState(RANDOM_STATE).choice(
        len(X_train), size=min(EVAL_SIZE, len(X_train)), replace=False
    )
    np.save(MODEL_DIR / "eval_idx.npy", eval_idx)
    print(f"  sub-sampel evaluasi (dari train): {len(eval_idx)}")

    km, km_info = latih_kmeans(X_train)
    agg, agg_info = latih_agglomerative(X_train)
    db, db_info = latih_dbscan(X_train, eval_idx)

    results = {"K-Means": km_info, "Agglomerative": agg_info, "DBSCAN": db_info}
    models = {"K-Means": km, "Agglomerative": agg, "DBSCAN": db}

    # --- Evaluasi train vs test (uji stabilitas klaster) ---
    print("\n[Evaluasi train vs test]...")
    ringkas = {}
    labels_full = {}
    for nama, info in results.items():
        if nama == "DBSCAN":
            m_train = metrik(X_train[eval_idx], info["labels"])
            m_test = None  # DBSCAN tidak punya mekanisme predict
            labels_full[nama] = None
            print(f"  DBSCAN        train={m_train}")
            ringkas[nama] = {"train": m_train, "test": m_test}
            continue

        model = models[nama]
        m_train = metrik(X_train, info["labels"])
        m_test = metrik(X_test, model.predict(X_test))
        labels_full[nama] = model.predict(X)
        info["labels"] = labels_full[nama]
        ringkas[nama] = {"train": m_train, "test": m_test}
        print(
            f"  {nama:<14} train={m_train}\n"
            f"  {'':<14} test ={m_test}"
        )

    # Pemenang: silhouette di data test (yang belum pernah dilihat) + model
    # yang bisa melabeli seluruh katalog.
    eligible = {
        k: v["test"]
        for k, v in ringkas.items()
        if v["test"] is not None and v["test"].get("silhouette") is not None
    }
    winner = max(eligible, key=lambda k: eligible[k]["silhouette"])
    print(f"\n  -> pemenang (berdasarkan silhouette test): {winner}")

    import joblib

    joblib.dump(km, MODEL_DIR / "kmeans.joblib")
    joblib.dump(agg, MODEL_DIR / "agglomerative.joblib")
    joblib.dump(db, MODEL_DIR / "dbscan.joblib")

    for nama, info in results.items():
        label_name = f"labels_{nama.lower().replace('-', '_')}.npy"
        if len(info["labels"]) != len(X):
            label_name = f"labels_{nama.lower().replace('-', '_')}_subsample.npy"
        simpan(info["labels"], MODEL_DIR / label_name)

    winner_labels = labels_full[winner]
    if winner_labels is None or len(winner_labels) != len(X):
        raise RuntimeError(f"pemenang {winner} tidak punya label full-data")
    joblib.dump(winner_labels, MODEL_DIR / "best_labels.joblib")

    joblib.dump(
        PCA(n_components=2, random_state=RANDOM_STATE).fit(X_train[:8000]),
        MODEL_DIR / "pca.joblib",
    )

    # Laporan stabilitas klaster train vs test.
    stabilitas = {
        "train_size": int(len(train_idx)),
        "test_size": int(len(test_idx)),
        "rasio": f"{TRAIN_FRACTION:.0%}/{1 - TRAIN_FRACTION:.0%}",
        "per_algoritma": {
            nama: {
                "train_silhouette": ringkas[nama]["train"].get("silhouette"),
                "test_silhouette": (
                    ringkas[nama]["test"].get("silhouette")
                    if ringkas[nama]["test"]
                    else None
                ),
                "selisih_silhouette": (
                    round(
                        ringkas[nama]["train"]["silhouette"]
                        - ringkas[nama]["test"]["silhouette"],
                        4,
                    )
                    if ringkas[nama]["test"]
                    and ringkas[nama]["test"].get("silhouette") is not None
                    else None
                ),
            }
            for nama in results
        },
    }

    out = {
        "winner": winner,
        "split": stabilitas,
        "metrics": ringkas,
        "detail": {
            k: {kk: vv for kk, vv in v.items() if kk != "labels"}
            for k, v in results.items()
        },
    }
    (PROC_DIR / "modeling_results.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=2, default=str), encoding="utf-8"
    )

    plot_pca(X, results, eval_idx)
    plot_silhouette(X, results, eval_idx)

    print(f"\nModel tersimpan di {MODEL_DIR}")
    print(f"Hasil evaluasi di {PROC_DIR / 'modeling_results.json'}")


if __name__ == "__main__":
    main()
