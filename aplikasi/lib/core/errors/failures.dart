/// Kelas error yang dipakai lintas lapisan (data -> domain -> presentation).
///
/// Tujuan membedakan tipe error: halaman bisa ngambil keputusan beda, misal
/// NetworkFailure ditampilkan sebagai "mode dummy aktif", sedangkan
/// ValidationFailure ditampilkan sebagai pesan merah di form.
sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Server FastAPI merespons, tapi statusnya bukan 200.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Nggak bisa nyambung ke server (server mati, IP salah, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Gagal baca cache / data dummy lokal.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Input user tidak valid (misal: yearStart > yearEnd).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
