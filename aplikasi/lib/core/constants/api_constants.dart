/// Konfigurasi endpoint backend FastAPI.
///
/// Base URL sengaja dipusatkan di satu tempat supaya gampang diganti saat
/// backend pindah-pindah (laptop kamu, VPS, atau mode emulator).
class ApiConstants {
  ApiConstants._();

  // ----------------------------------------------------------------------------
  // Base URL backend.
  //
  // Dioverride saat build, jadi nggak perlu edit kode saat pindah server:
  //
  //   flutter build apk --dart-define=API_BASE_URL=https://api.domain-kamu.com
  //   flutter run      --dart-define=API_BASE_URL=http://10.0.2.2:8000
  //
  // Catatan: bawaan di bawah itu alamat lokal, jadi build release buat publik
  // WAJIB dibarengi --dart-define=API_BASE_URL=... (lihat docs/DEPLOYMENT.md).
  // ----------------------------------------------------------------------------
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.7:8000',
  );

  /// Endpoint health check, dipakai buat tahu server FastAPI hidup atau tidak.
  static const String healthEndpoint = '/health';

  /// Endpoint utama: kirim kriteria film, balik daftar rekomendasi.
  static const String recommendEndpoint = '/recommend';

  /// Batas waktu nunggu koneksi awal (detik).
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Batas waktu nunggu server selesai memproses (detik).
  static const Duration receiveTimeout = Duration(seconds: 20);
}
