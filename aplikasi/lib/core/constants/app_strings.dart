/// Kumpulan string & daftar statis yang dipakai di banyak halaman.
class AppStrings {
  AppStrings._();

  static const String appName = 'NeVie';
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
  static const String tabMascot = 'Maskot';
  static const String tabWatchlist = 'Watchlist';

  // ----------------------------------------------------------------------------
  // Teks percakapan maskot (halaman utama).
  // ----------------------------------------------------------------------------
  static const String mascotGreeting =
      'Hai! Aku TonTon, maskot NeVie. Hari ini mau nonton apa nih?';
  static const String mascotInvite = 'Cariin Film dong!';
  static const String mascotTapInvite = 'Ketik tombolnya, yuk!';
  static const String mascotAskGenre =
      'Pilih genre yang kamu suka, boleh lebih dari satu ya.';
  static const String mascotGenreConfirm = 'Oke, lanjut!';
  // Judul papan marquee (genre, slider, kata kunci).
  static const String marqueeGenreTitle = 'PILIH GENRE';
  static const String marqueeGenreSubtitle = 'SILAHKAN PILIH SATU ATAU LEBIH';
  static const String marqueeSliderTitle = 'ATUR SELERA';
  static const String marqueeSliderSubtitle =
      'GESER SLIDER-NYA, TONTON BAKAL NYARI YANG PAS';
  static const String marqueeKeywordTitle = 'KATA KUNCI';
  static const String marqueeKeywordSubtitle = 'SEMUA KATA BISA JADI PETUNJUK';
  static const String marqueeSelectedSuffix = 'dipilih';
  static const String mascotAbsorb = 'Aku serap yang kamu pilih ya...';
  static const String mascotSlidersTitle = 'Atur selera kamu';
  static const String mascotSliderConfirm = 'Siap, lanjut!';
  static const String mascotKeywordAsk =
      'Terakhir, ketik tema atau kata kunci filmnya...';
  static const String mascotAskRating =
      'Oke. Nah, rating minimal berapa yang kamu mau?';
  static const String mascotAskRuntime =
      'Berapa lama durasi film yang pas buat kamu?';
  static const String mascotAskYear =
      'Film dari rentang tahun berapa yang kamu cari?';
  static const String mascotAskExtra =
      'Terakhir, mau berapa rekomendasi dan ada kata kunci khusus?';
  static const String mascotThinking =
      'Hmm, biar aku mikir dan cariin yang paling cocok...';
  static const String mascotDone = 'Nih hasilnya! Pilih yang paling kabari.';
  static const String mascotEmpty =
      'Aduh, nggak ada yang cocok. Coba longgarkan filter kamu ya.';
  static const String mascotNext = 'Lanjut';
  static const String mascotBack = 'Kembali';
  static const String mascotSearch = 'Cariin dong';
  static const String mascotAgain = 'Cari lagi';
  static const String mascotCredit = 'Maskot TV orisinal NeVie';

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
