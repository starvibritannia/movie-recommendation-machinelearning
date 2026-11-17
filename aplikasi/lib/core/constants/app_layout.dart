/// Ukuran & spacing yang dipakai bareng di semua halaman.
class AppLayout {
  AppLayout._();

  /// Padding kiri-kanan konten.
  static const double screenPadding = 20;

  /// Radius sudut kartu & panel.
  static const double cardRadius = 22;

  /// Radius sudut tombol.
  static const double buttonRadius = 16;

  /// Tinggi bar navigasi bawah.
  static const double navHeight = 74;

  /// Jarak bar navigasi dari tepi bawah layar.
  static const double navBottomGap = 14;

  /// Ruang kosong tambahan di bawah konten supaya nggak ketutup nav melayang.
  static const double navSpacer = navHeight + 34;
}
