"""Schema request/response API.

Nama field di sini HARUS sama persis dengan yang dikirim Flutter
(lihat docs/api_contract.md). Kalau ada perubahan, ubah dua pihak sekalian.
"""

from typing import List, Optional

from pydantic import BaseModel, Field, field_validator, model_validator


class RecommendRequest(BaseModel):
    """Body POST /recommend."""

    genres: List[str] = Field(default_factory=list, description="Daftar genre yang diinginkan")
    min_rating: float = Field(default=7.0, ge=0.0, le=10.0)
    runtime_min: int = Field(default=60, ge=0)
    runtime_max: int = Field(default=210, ge=0)
    year_start: int = Field(default=1980, ge=1888)
    year_end: int = Field(default=2024, ge=1888)
    keyword: Optional[str] = Field(default=None, description="Kata kunci tema/judul, boleh kosong")
    top_n: int = Field(default=10, ge=1, le=50)

    @field_validator("genres")
    @classmethod
    def clean_genres(cls, value: List[str]) -> List[str]:
        return [g.strip() for g in value if g and g.strip()]

    @field_validator("keyword")
    @classmethod
    def clean_keyword(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        value = value.strip()
        return value or None

    @model_validator(mode="after")
    def check_ranges(self) -> "RecommendRequest":
        if self.runtime_min > self.runtime_max:
            raise ValueError("runtime_min tidak boleh lebih besar dari runtime_max")
        if self.year_start > self.year_end:
            raise ValueError("year_start tidak boleh lebih besar dari year_end")
        return self


class MovieOut(BaseModel):
    """Satu film hasil rekomendasi."""

    movie_id: str
    movie_name: str
    year: Optional[int] = None
    certificate: str = "Unrated"
    runtime: Optional[int] = None
    genre: List[str] = Field(default_factory=list)
    rating: Optional[float] = None
    votes: Optional[int] = None
    description: str = ""
    director: str = "-"
    star: List[str] = Field(default_factory=list)
    match_percent: Optional[float] = None
    cluster_label: Optional[int] = None


class RecommendResponse(BaseModel):
    """Response POST /recommend."""

    recommendations: List[MovieOut] = Field(default_factory=list)
    predicted_cluster: Optional[int] = None
    total_candidates: Optional[int] = None
    elapsed_ms: Optional[float] = None


class HealthResponse(BaseModel):
    """Response GET /health."""

    status: str = "ok"
    model_loaded: bool = False
    model_name: Optional[str] = None
    cluster_count: int = 0
