/// Kumpulan string & daftar statis yang dipakai di banyak halaman.
class AppStrings {
  AppStrings._();

  static const String appName = 'FilmMatch';
  static const String tagline =
      'Temukan film yang paling cocok dengan selera kamu';

  // ----------------------------------------------------------------------------
  // 25 genre yang tersedia di dataset Kaggle "IMDb Movies by Genre".
  // Daftar ini yang dirender jadi chip filter di halaman input.
  // ----------------------------------------------------------------------------
  static const List<String> availableGenres = [
    'Action',
    'Adventure',
    'Animation',
    'Biography',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Film-Noir',
    'Game-Show',
    'History',
    'Horror',
    'Music',
    'Musical',
    'Mystery',
    'News',
    'Reality-TV',
    'Romance',
    'Sci-Fi',
    'Short',
    'Sport',
    'Thriller',
    'War',
    'Western',
  ];

  // Label bottom navigation
  static const String tabTrending = 'Trending';
  static const String tabDiscover = 'Discover';
  static const String tabWatchlist = 'Watchlist';

  // Label halaman trending
  static const String trendingTitle = 'Trending Sekarang';
  static const String trendingSubtitle =
      'Film yang paling banyak dicari musim ini';
  static const String trendingEmpty = 'Daftar trending belum tersedia.';

  // Label halaman discover
  static const String discoverSubtitle =
      'Atur selera kamu, biar model ML yang nyari';

  // Label halaman watchlist
  static const String watchlistEmpty =
      'Watchlist kamu masih kosong. Tandai film yang mau kamu tonton nanti.';
  static const String watchlistSaved = 'Ditambahkan ke watchlist';
  static const String watchlistRemoved = 'Dihapus dari watchlist';

  // Label halaman input
  static const String labelGenre = 'Genre';
  static const String labelGenreHint = 'Pilih satu atau lebih genre';
  static const String labelMinRating = 'Rating minimum';
  static const String labelRuntime = 'Durasi tayang (menit)';
  static const String labelYear = 'Tahun rilis';
  static const String labelKeyword = 'Kata kunci tema atau judul (opsional)';
  static const String labelTopN = 'Jumlah rekomendasi';
  static const String actionSearch = 'Cari Rekomendasi';
  static const String actionReset = 'Reset';

  // Label halaman hasil
  static const String resultsTitle = 'Hasil Rekomendasi';
  static const String resultsEmpty =
      'Belum ada rekomendasi. Isi kriterianya dulu ya.';
  static const String resultsLoading = 'Lagi nyari film yang cocok...';
  static const String resultsErrorTitle = 'Gagal memuat rekomendasi';
  static const String clusterBadge = 'Cluster';
  static const String matchBadge = 'Match';
  static const String usingMockData =
      'Mode dummy: backend FastAPI belum terhubung';
}
