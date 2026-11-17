/// Helper format angka/teks biar tampilan konsisten di semua halaman.
class Formatters {
  Formatters._();

  /// 161 -> "2h 41m", 45 -> "45m", 0/null -> "-"
  static String runtime(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  /// 1250000 -> "1.3M", 8400 -> "8.4K", 950 -> "950"
  static String votes(int? value) {
    if (value == null || value <= 0) return '-';
    if (value >= 1000000) return '${_trimZero(value / 1000000)}M';
    if (value >= 1000) return '${_trimZero(value / 1000)}K';
    return value.toString();
  }

  /// 96.42 -> "96.4%"
  static String matchPercent(double? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)}%';
  }

  static String _trimZero(double value) {
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}
