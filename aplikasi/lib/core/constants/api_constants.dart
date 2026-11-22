/// Konfigurasi endpoint backend FastAPI.
///
/// Base URL sengaja dipusatkan di satu tempat supaya gampang diganti saat
/// backend pindah-pindah (laptop kamu, VPS, atau mode emulator).
class ApiConstants {
  ApiConstants._();

  // ----------------------------------------------------------------------------
  // HP fisik (uji coba sekarang): satu Wi-Fi dengan komputer ini.
  // Android emulator : 10.0.2.2 = localhost di mesin host.
  // iOS simulator    : localhost
  // Kalau IP komputer berubah, ganti di sini lalu build ulang.
  // ----------------------------------------------------------------------------
  static const String baseUrl = 'http://192.168.1.7:8000';

  /// Endpoint health check, dipakai buat tahu server FastAPI hidup atau tidak.
  static const String healthEndpoint = '/health';

  /// Endpoint utama: kirim kriteria film, balik daftar rekomendasi.
  static const String recommendEndpoint = '/recommend';

  /// Batas waktu nunggu koneksi awal (detik).
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Batas waktu nunggu server selesai memproses (detik).
  static const Duration receiveTimeout = Duration(seconds: 20);
}
