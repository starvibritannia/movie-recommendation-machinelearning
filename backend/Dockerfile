# Backend NeVie (FilmMatch API) — image produksi.
#
# Dipakai lewat deploy/docker-compose.yml. Ukuran image gede (~1 GB) karena
# bundle model 154 MB + katalog di dalamnya, jadi jangan lupa .dockerignore.

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /srv/app

# Dependency dipasang duluan supaya cache Docker kepakai saat kode berubah.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
COPY app ./app

EXPOSE 8000

# HEALTHCHECK sesuai endpoint /health yang sudah ada.
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD python -c "import sys,urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).status == 200 else 1)"

# --workers 1 itu sengaja: bundle model cuma dimuat sekali di memori,
# kalau lebih dari satu worker RAM-nya langsung berlipat.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
