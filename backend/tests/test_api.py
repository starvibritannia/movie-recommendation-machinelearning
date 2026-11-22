"""Test endpoint API pakai FastAPI TestClient.

Jalankan:
    pip install pytest httpx
    python -m pytest tests -q
"""

from main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    # model_bundle.joblib ada -> model asli termuat
    assert body["model_loaded"] is True
    assert body["model_name"] in {"K-Means", "Agglomerative", "DBSCAN"}
    assert body["cluster_count"] >= 2


def test_recommend_default():
    response = client.post("/recommend", json={})
    assert response.status_code == 200

    body = response.json()
    assert len(body["recommendations"]) == 10
    assert body["predicted_cluster"] is not None
    assert body["total_candidates"] >= 10

    first = body["recommendations"][0]
    for field in (
        "movie_id",
        "movie_name",
        "year",
        "certificate",
        "runtime",
        "genre",
        "rating",
        "votes",
        "description",
        "director",
        "star",
        "match_percent",
        "cluster_label",
    ):
        assert field in first


def test_recommend_dengan_filter_genre():
    response = client.post(
        "/recommend",
        json={
            "genres": ["Sci-Fi"],
            "min_rating": 8.0,
            "runtime_min": 90,
            "runtime_max": 200,
            "year_start": 2000,
            "year_end": 2024,
            "keyword": None,
            "top_n": 5,
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body["recommendations"]) >= 1
    assert all("Sci-Fi" in movie["genre"] for movie in body["recommendations"])


def test_recommend_keyword():
    response = client.post("/recommend", json={"keyword": "dream", "top_n": 5})
    assert response.status_code == 200
    body = response.json()
    assert len(body["recommendations"]) > 0
    # keyword harus muncul di judul atau sinopsis
    for movie in body["recommendations"]:
        teks = (movie["movie_name"] + " " + movie["description"]).lower()
        assert "dream" in teks


def test_validasi_range_tahun_terbalik():
    response = client.post(
        "/recommend",
        json={"year_start": 2024, "year_end": 2000},
    )
    assert response.status_code == 422


def test_validasi_rating_di_luar_jangkauan():
    response = client.post("/recommend", json={"min_rating": 11})
    assert response.status_code == 422


def test_keyword_kosong_jadi_null():
    response = client.post("/recommend", json={"keyword": "   "})
    assert response.status_code == 200
