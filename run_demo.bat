@echo off
title NeVie - Backend Demo
cd /d "%~dp0backend"

echo ============================================
echo   NeVie - Menyalakan Backend FastAPI
echo ============================================
echo.

if not exist ".venv\Scripts\python.exe" (
  echo [ERROR] Folder .venv tidak ditemukan.
  echo Jalankan setup dulu: uv venv --python 3.11 ^&^& uv pip install -r requirements.txt
  echo.
  pause
  exit /b 1
)

echo IP laptop kamu (yang dipakai HP, pilih yang Wi-Fi 192.168.x.x):
ipconfig | findstr /C:"IPv4"
echo.
echo HP harus satu Wi-Fi dengan laptop ini.
echo Base URL aplikasi sekarang: http://192.168.1.7:8000
echo Kalau IP di atas beda, ganti baseUrl di aplikasi/lib/core/constants/api_constants.dart
echo lalu build ulang APK.
echo.
echo Nyalain server... tunggu sampai "Application startup complete".
echo.

".venv\Scripts\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000

echo.
echo Server berhenti. Tekan tombol apa saja untuk menutup.
pause > nul
