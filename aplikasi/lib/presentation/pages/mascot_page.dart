import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_layout.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/movie.dart';
import '../providers/recommendation_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/watchlist_toggler.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/jelly_press.dart';
import '../widgets/jelly_sliders.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/wordmark.dart';
import '../widgets/marquee_panel.dart';
import '../widgets/mascot_stage.dart';
import '../widgets/movie_card.dart';
import '../widgets/tonton_engine.dart';
import 'results_page.dart';

/// Fase alur ngobrol sama TonTon.
enum _Phase {
  greeting,
  invite,
  genre,
  absorb,
  sliders,
  sliderExit,
  keyword,
  searching,
  done,
}

/// Halaman utama: TonTon di tengah, tombol-tombol mengapung di sekitarnya.
///
/// Semua nilai filter tetap di [RecommendationProvider], jadi kontrak API
/// backend tidak berubah. Yang dirombak cuma lapisan presentasi.
class MascotPage extends StatefulWidget {
  const MascotPage({super.key});

  @override
  State<MascotPage> createState() => _MascotPageState();
}

/// Ruang kosong di atas papan, dipakai tiket penjuru yang menjulang keluar
/// kotak papan. Tanpa ini klip gulungan bakal memotong tiketnya.
const double _badgeRoom = 34;

class _MascotPageState extends State<MascotPage> with TickerProviderStateMixin {
  _Phase _phase = _Phase.greeting;

  // ---------------- state maskot ----------------
  final MascotController _mascot = MascotController();
  int _explodeToken = 0;

  /// Animasi tangan setelah menyapa: 1 = melambai, 0 = turun ke sisi badan.
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  // ---------------- controller animasi ----------------
  late final AnimationController _chipEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _chipExit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final AnimationController _sliderEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _sliderExit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final AnimationController _keywordEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  /// Penerbangan gelembung kata ke mulut TonTon.
  late final AnimationController _keywordFly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  late final AnimationController _invitePop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  // ---------------- state panggung ----------------
  Size _stageSize = Size.zero;

  String? _keywordBubble;
  Offset _keywordFrom = Offset.zero;

  /// Label tiket yang lagi terbang + titik asalnya di panggung.
  String? _ticketLabel;
  Offset? _ticketHome;

  Timer? _greetingTimer;
  Timer? _pendingTimer;
  Timer? _slotTimer;
  Timer? _reactionTimer;
  Timer? _debounce;

  String? _reactionText;

  final TextEditingController _keywordCtrl = TextEditingController();

  /// Reaksi maskot tiap genre: ekspresi + kalimat lucu.
  static const Map<String, (MascotExpression, String)> _genreReactions = {
    'Action': (MascotExpression.excited, 'Gaskeun! Adrenaline dong.'),
    'Adventure': (MascotExpression.excited, 'Petualangan, siap berangkat!'),
    'Animation': (MascotExpression.excited, 'Animasi? Boleh banget!'),
    'Biography': (MascotExpression.thinking, 'Kisah nyata, biar makin paham.'),
    'Comedy': (MascotExpression.happy, 'Wkwk, aku bakal ketawa terus.'),
    'Crime': (MascotExpression.thinking, 'Mode detektif: ON.'),
    'Documentary': (MascotExpression.thinking, 'Biar makin paham dunia nyata.'),
    'Drama': (MascotExpression.sad, 'Siap-siap, bawa tisu ya.'),
    'Family': (MascotExpression.love, 'Nonton bareng keluarga, dong.'),
    'Film-Noir': (MascotExpression.thinking, 'Gelap dan misterius, seleraku.'),
    'Game-Show': (MascotExpression.excited, 'Acara game? Ikutan ya!'),
    'History': (MascotExpression.thinking, 'Belajar masa lalu, asik.'),
    'Horror': (MascotExpression.horrified, 'Hah?! Seram nih, aku suka...'),
    'Music': (MascotExpression.love, 'Lagunya bikin merinding nih.'),
    'Musical': (MascotExpression.love, 'Bernyanyi yuk bareng!'),
    'Mystery': (MascotExpression.thinking, 'Tebak-tebakan? Aku siap.'),
    'News': (MascotExpression.thinking, 'Berita terkini, siap.'),
    'Reality-TV': (MascotExpression.happy, 'Reality show, santuy.'),
    'Romance': (MascotExpression.love, 'Aww, caption-caption manis dong.'),
    'Sci-Fi': (MascotExpression.thinking, 'Menarik, kayak mimpi tapi nyata.'),
    'Short': (MascotExpression.happy, 'Film pendek, cepet tapi nikmat.'),
    'Sport': (MascotExpression.excited, 'Semangat! Aku dukung timmu.'),
    'Thriller': (MascotExpression.horrified, 'Deg-degan, lanjutkan!'),
    'War': (MascotExpression.sad, 'Berat nih, tapi penting dipahami.'),
    'Western': (MascotExpression.excited, 'Koboi? Gaskeun!'),
  };

  // ---------------------------------------------------------------- siklus
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecommendationProvider>().checkServerHealth();
    });
    _waveCtrl.addListener(() => _mascot.setWave(_waveCtrl.value));
    _mascot.setWave(_waveCtrl.value);
    _scheduleGreeting();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _pendingTimer?.cancel();
    _slotTimer?.cancel();
    _reactionTimer?.cancel();
    _debounce?.cancel();
    _keywordCtrl.dispose();
    _waveCtrl.dispose();
    _chipEnter.dispose();
    _chipExit.dispose();
    _sliderEnter.dispose();
    _sliderExit.dispose();
    _keywordEnter.dispose();
    _float.dispose();
    _keywordFly.dispose();
    _invitePop.dispose();
    _mascot.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- alur
  /// Ganti fase sekaligus terapkan ekspresi TonTon yang cocok.
  void _setPhase(_Phase phase) {
    setState(() => _phase = phase);
    final expr = _expressionFor(context.read<RecommendationProvider>());
    _mascot.setExpression(expr);
    _mascot.setTalking(expr == MascotExpression.talking);
  }

  void _scheduleGreeting() {
    _greetingTimer?.cancel();
    _greetingTimer = Timer(const Duration(milliseconds: 2600), _goInvite);
  }

  void _goInvite() {
    if (!mounted || _stageSize == Size.zero) return;
    _setPhase(_Phase.invite);
    // Tombol "diberikan" TonTon: muncul dari tubuhnya, bukan di tempat acak.
    _invitePop.forward(from: 0);
    _mascot.hop(420);
    _mascot.squish(-5);
    _mascot.glance(0.7, 0.5);
    _waveCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goGenre() {
    if (!mounted || _stageSize == Size.zero) return;

    _setPhase(_Phase.genre);

    // Girang sekejap pas papan genre muncul, lalu tenang nunggu pilihan user.
    _mascot.hop(760);
    _mascot.squish(-6);
    _mascot.glance(8, -6);

    _pendingTimer?.cancel();
    _pendingTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _explodeToken++);
      _pendingTimer = Timer(const Duration(milliseconds: 140), () {
        if (mounted) _chipEnter.forward(from: 0);
      });
    });
  }

  void _confirmGenre() {
    // Papan digulung jadi tiket, tiket diterbangkan ke slot tape TonTon.
    _setPhase(_Phase.absorb);
    _mascot.hop(620);
    _mascot.squish(-4);
    setState(() {
      _ticketLabel = AppStrings.ticketGenre;
      _ticketHome = _ticketHomePoint();
    });
    _chipExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 180), _goSliders);
    });
    _scheduleSwallow(470);
  }

  /// TonTon nelen pas tiketnya nyampe di slot tape.
  void _scheduleSwallow(int millis) {
    _slotTimer?.cancel();
    _slotTimer = Timer(Duration(milliseconds: millis), () {
      if (mounted) _mascot.swallow();
    });
  }

  void _goSliders() {
    if (!mounted) return;
    _setPhase(_Phase.sliders);
    _sliderEnter.forward(from: 0);
  }

  void _confirmSliders() {
    _setPhase(_Phase.sliderExit);
    _mascot.squish(-3);
    setState(() {
      _ticketLabel = AppStrings.ticketSlider;
      _ticketHome = _ticketHomePoint();
    });
    _sliderExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 120), _goKeyword);
    });
    _scheduleSwallow(470);
  }

  void _goKeyword() {
    if (!mounted) return;
    _setPhase(_Phase.keyword);
    _keywordEnter.forward(from: 0);
  }

  Future<void> _search() async {
    final provider = context.read<RecommendationProvider>();
    _setPhase(_Phase.searching);
    _mascot.hop(520);
    await provider.search();
    if (!mounted) return;
    if (provider.results.isEmpty) {
      _setPhase(_Phase.done);
      return;
    }
    _openResults();
  }

  /// Kata kunci dimasukan ke TonTon dulu (gelembung ditelan), baru dicari.
  void _submitKeyword() {
    final text = _keywordCtrl.text.trim();
    if (text.isEmpty) {
      _search();
      return;
    }
    if (_keywordFly.isAnimating) return;

    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);
    setState(() {
      _keywordBubble = text;
      _keywordFrom = Offset(center.dx, center.dy + mSize / 2 + 78);
    });
    _keywordFly.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _keywordBubble = null);
      _mascot.pushScreenLine(text);
      _mascot.swallow();
      _search();
    });
  }

  void _openResults() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ResultsSheet(),
    ).whenComplete(() {
      if (mounted) _setPhase(_Phase.done);
    });
  }

  void _restart() {
    context.read<RecommendationProvider>().resetFilters();
    _keywordCtrl.clear();
    _chipEnter.reset();
    _slotTimer?.cancel();
    setState(() => _ticketHome = null);
    _chipExit.reset();
    _sliderEnter.reset();
    _sliderExit.reset();
    _keywordEnter.reset();
    _mascot.clearScreen();
    _setPhase(_Phase.greeting);
    _waveCtrl.animateTo(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
    );
    _mascot.hop(620);
    _scheduleGreeting();
  }

  // ---------------------------------------------------------------- reaksi
  void _reactNow({String? text, MascotExpression? expression}) {
    _reactionTimer?.cancel();
    _mascot.noteActivity();
    setState(() {
      _reactionText = text;
    });
    if (expression != null) _mascot.setExpression(expression);
    _reactionTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(_resetReaction);
      _mascot.setExpression(
        _expressionFor(context.read<RecommendationProvider>()),
      );
    });
  }

  void _reactInput(String text, MascotExpression expression) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), () {
      if (mounted) _reactNow(text: text, expression: expression);
    });
  }

  void _resetReaction() {
    _reactionText = null;
  }

  void _toggleGenre(String genre) {
    final provider = context.read<RecommendationProvider>();
    final willSelect = !provider.selectedGenres.contains(genre);
    _mascot.noteActivity();
    provider.toggleGenre(genre);

    if (willSelect) {
      _mascot.swallow();
      final reaction = _genreReactions[genre];
      _reactNow(text: reaction?.$2, expression: reaction?.$1);
    } else {
      _mascot.squish(-4);
    }
  }

  /// Posisi mulut TonTon di koordinat panggung (mulut ada di layar).
  Offset _mouthPos(Offset center, double mSize) =>
      center + Offset(0, 14 * mSize / 220);

  /// Titik asal tiket: bawah-tengah papan yang lagi menggulung.
  Offset _ticketHomePoint() {
    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);
    final panelTop = center.dy + mSize / 2 + 8;
    final panelBottom = _stageSize.height - AppLayout.navSpacer;
    return Offset(center.dx, math.max(panelTop + 150, panelBottom - 26));
  }

  /// Posisi slot tape di badan TonTon (viewBox 220).
  Offset _slotPos(Offset center, double mSize) =>
      center + Offset(0, 52.5 * mSize / 220);

  /// True saat papan sedang keluar dan tiketnya terbang ke slot.
  bool get _ticketActive =>
      _phase == _Phase.absorb || _phase == _Phase.sliderExit;

  /// Progres keluar papan (0..1) untuk fase absorb / sliderExit.
  /// Kurva easeInOutQuart (cubic-bezier(.76,0,.24,1)) ini referensi standar
  /// buat tirai/shutter: akselerasi & deselerasi simetris, jadi gulungannya
  /// terasa kayak kain, bukan kejutan.
  double get _exitT => _phase == _Phase.absorb
      ? Curves.easeInOutQuart.transform(_chipExit.value)
      : Curves.easeInOutQuart.transform(_sliderExit.value);

  // ---------------------------------------------------------------- geometri
  /// Di fase slider/keyword maskot naik & mengecil supaya panelnya muat.
  bool _compactMascot(_Phase phase) =>
      phase == _Phase.genre ||
      phase == _Phase.absorb ||
      phase == _Phase.sliders ||
      phase == _Phase.sliderExit ||
      phase == _Phase.keyword;

  double _mascotSize(Size s) => _compactMascot(_phase)
      ? math.min(s.width * 0.30, 118)
      : math.min(s.width * 0.46, 184);

  Offset _mascotCenter(Size s) => _compactMascot(_phase)
      ? Offset(s.width / 2, s.height * 0.20)
      : Offset(s.width / 2, s.height * 0.40);

  // ---------------------------------------------------------------- tampil
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    final bubbleText = _reactionText ?? _bubbleText(provider);

    return AppScaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Wordmark(fontSize: 20),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _stageSize = Size(constraints.maxWidth, constraints.maxHeight);

            // Semua controller animasi halaman digabung di sini supaya
            // chip/slider ikut rebuild tiap frame.
            return AnimatedBuilder(
              animation: Listenable.merge([
                _chipEnter,
                _chipExit,
                _sliderEnter,
                _sliderExit,
                _keywordEnter,
                _float,
                _waveCtrl,
                _keywordFly,
              ]),
              builder: (context, _) {
                final mSize = _mascotSize(_stageSize);
                final center = _mascotCenter(_stageSize);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bubble di atas maskot, ekornya menunjuk ke bawah.
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 2,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: MascotBubble(text: bubbleText),
                      ),
                    ),

                    // TonTon di tengah panggung (naik saat panel muncul).
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: center.dx - mSize / 2,
                      top: center.dy - mSize / 2,
                      width: mSize,
                      height: mSize,
                      child: MascotStage(
                        controller: _mascot,
                        size: mSize,
                        explodeToken: _explodeToken,
                        reducedMotion: MediaQuery.of(context).disableAnimations,
                      ),
                    ),

                    // Papan marquee pemilih genre.
                    if (_phase == _Phase.genre || _phase == _Phase.absorb)
                      _buildGenrePanel(center, mSize),

                    // Gelembung kata kunci yang ditelan TonTon.
                    if (_keywordBubble != null)
                      _buildKeywordBubble(center, mSize),

                    // Papan menggulung jadi tiket + cahaya slot tape TonTon.
                    if (_ticketActive) ...[
                      _buildSlotGlow(center, mSize),
                      _buildFlyingTicket(center, mSize),
                    ],

                    // Tombol ajakan pertama.
                    if (_phase == _Phase.invite) _buildInvite(),

                    // Panel slider.
                    if (_phase == _Phase.sliders || _phase == _Phase.sliderExit)
                      _buildSliders(center, mSize),

                    // Panel kata kunci.
                    if (_phase == _Phase.keyword) _buildKeyword(center, mSize),

                    // Tombol cari lagi.
                    if (_phase == _Phase.done)
                      _buildRestartButton(center, mSize),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  MascotExpression _expressionFor(RecommendationProvider provider) {
    if (_phase == _Phase.done && provider.errorMessage != null) {
      return MascotExpression.sad;
    }
    return switch (_phase) {
      _Phase.greeting => MascotExpression.excited,
      _Phase.invite => MascotExpression.happy,
      _Phase.genre => MascotExpression.talking,
      _Phase.absorb => MascotExpression.excited,
      _Phase.sliders || _Phase.sliderExit => MascotExpression.talking,
      _Phase.keyword || _Phase.searching => MascotExpression.thinking,
      _Phase.done => MascotExpression.happy,
    };
  }

  String _bubbleText(RecommendationProvider provider) {
    return switch (_phase) {
      _Phase.greeting => AppStrings.mascotGreeting,
      _Phase.invite => AppStrings.mascotTapInvite,
      _Phase.genre => AppStrings.mascotAskGenre,
      _Phase.absorb => AppStrings.mascotAbsorb,
      _Phase.sliders || _Phase.sliderExit => AppStrings.mascotSlidersTitle,
      _Phase.keyword => AppStrings.mascotKeywordAsk,
      _Phase.searching => AppStrings.mascotThinking,
      _Phase.done => provider.errorMessage ?? AppStrings.mascotDone,
    };
  }

  // ---------------------------------------------------------------- genre
  Widget _buildGenrePanel(Offset center, double mSize) {
    final enterT = Curves.easeOutBack.transform(_chipEnter.value);
    final exitT = Curves.easeInOutQuart.transform(_chipExit.value);
    final panelTop = center.dy + mSize / 2 + 8;

    // Papan "digulung" tanpa meremas kontennya: cukup proporsi yang kelihatan.
    final roll = (enterT * (1 - exitT)).clamp(0.0, 1.0);
    final opacity = (enterT * (1 - exitT * 0.7)).clamp(0.0, 1.0);

    return Positioned(
      left: 16,
      right: 16,
      top: panelTop,
      bottom: AppLayout.navSpacer,
      child: Opacity(
        opacity: opacity,
        // Ruang ekstra di atas klip supaya tiket penjuru nggak kepotong.
        child: _RollClip(
          t: roll,
          room: _badgeRoom,
          child: _buildGenrePanelBody(),
        ),
      ),
    );
  }

  Widget _buildGenrePanelBody() {
    final provider = context.watch<RecommendationProvider>();
    final selected = provider.selectedGenres;

    // Isi papan muncul bertahap supaya terasa hidup.
    final t = Interval(
      0.02,
      0.5,
      curve: Curves.easeOutBack,
    ).transform(_chipEnter.value.clamp(0.0, 1.0));

    return MarqueePanel(
      title: AppStrings.marqueeGenreTitle,
      subtitle: AppStrings.marqueeGenreSubtitle,
      // Tiket papan disembunyikan pas papan digulung; tiket aslinya yang terbang.
      cornerBadge: _ticketActive
          ? null
          : const _TicketStub(label: AppStrings.ticketGenre),
      animateIn: true,
      footer: Row(
        children: [
          Expanded(
            child: Text(
              '${selected.length} ${AppStrings.marqueeSelectedSuffix}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _BouncyButton(
            label: AppStrings.mascotGenreConfirm,
            onTap: selected.isEmpty ? null : _confirmGenre,
            height: 44,
            radius: 14,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
      scrollable: true,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 5,
            crossAxisSpacing: 6,
            childAspectRatio: 3.6,
            children: [
              for (final genre in AppStrings.availableGenres)
                _GenreLight(
                  label: genre,
                  selected: selected.contains(genre),
                  onTap: () => _toggleGenre(genre),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Papan yang menggulung berubah jadi tiket, lalu tiket meluncur ke slot tape.
  Widget _buildFlyingTicket(Offset center, double mSize) {
    final home = _ticketHome;
    final label = _ticketLabel;
    if (home == null || label == null) return const SizedBox.shrink();

    final t = _exitT.clamp(0.0, 1.0);
    // Fase 1: papan menggulung, tiket terbentuk di tempatnya.
    final formT = (t / 0.40).clamp(0.0, 1.0);
    // Fase 2: tiket meluncur ke slot tape TonTon.
    final flyRaw = ((t - 0.42) / 0.58).clamp(0.0, 1.0);
    // Dicepet pas mendekat, jadi rasanya kena "tarikan" slotnya.
    final flyT = Curves.easeInCubic.transform(flyRaw);
    final slot = _slotPos(center, mSize);

    // Bukan garis lurus: ada busuran ke atas biar ototnya kerasa lemparan.
    final ctrl = Offset.lerp(home, slot, 0.5)! + const Offset(0, -30);
    final pos = _quadBezier(home, ctrl, slot, flyT);

    // Mengecil mengikuti jarak tempuh, bukan waktu.
    final total = (slot - home).distance;
    final travel = total == 0
        ? 1.0
        : ((pos - home).distance / total).clamp(0.0, 1.0);
    final scale =
        (0.35 + 0.65 * Curves.easeOutBack.transform(formT)) *
        (1 - travel * 0.42);

    // Miring pas lepas, lurus pas nyamplung, plus sedikit seliweran.
    final tilt = -0.12 + flyT * 0.14 + math.sin(flyT * math.pi) * 0.06;

    return Positioned(
      left: pos.dx - 59,
      top: pos.dy - 13,
      child: Opacity(
        opacity: formT * (1 - flyRaw * 0.25),
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: tilt,
            child: _TicketStub(label: label),
          ),
        ),
      ),
    );
  }

  /// Titik tengah kurva kuadratik (buat lintasan lemparan tiket).
  Offset _quadBezier(Offset a, Offset b, Offset c, double t) {
    final ab = Offset.lerp(a, b, t)!;
    final bc = Offset.lerp(b, c, t)!;
    return Offset.lerp(ab, bc, t)!;
  }

  /// Cahaya slot tape TonTon pas tiket masuk.
  Widget _buildSlotGlow(Offset center, double mSize, {double opacity = 1}) {
    final t = _exitT.clamp(0.0, 1.0);
    // Baru menyala pas tiket nyaris nyampe.
    final glow = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    final slot = _slotPos(center, mSize);
    final w = 62 * mSize / 220;

    return Positioned(
      left: slot.dx - w / 2,
      top: slot.dy - w * 0.17,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: w,
            height: w * 0.34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(w * 0.17),
              border: Border.all(
                color: AppColors.accentLight.withValues(
                  alpha: 0.2 + glow * 0.8,
                ),
                width: 1.6 + glow,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentLight.withValues(alpha: 0.4 * glow),
                  blurRadius: 14 + glow * 16,
                  spreadRadius: glow * 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordBubble(Offset center, double mSize) {
    final t = Curves.easeInCubic.transform(_keywordFly.value);
    final pos = Offset.lerp(_keywordFrom, _mouthPos(center, mSize), t)!;
    final scale = 1 - t * 0.7;
    return Positioned(
      left: pos.dx - 85,
      top: pos.dy - 20,
      child: Transform.scale(
        scale: scale,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              _keywordBubble!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- tombol
  /// Posisi tombol "diberikan" TonTon: tepat di bawah badannya, seolah jatuh
  /// di dalam kolam cahaya proyektor.
  Offset _inviteTarget() {
    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);
    return Offset(
      center.dx,
      (center.dy + mSize / 2 + 116).clamp(170, _stageSize.height - 148),
    );
  }

  Widget _buildInvite() {
    final floatT = _float.value * math.pi * 2;
    final bob = math.sin(floatT) * 6;
    final v = _invitePop.value;

    // 1) slot tape nyala, 2) tiket terdorong keluar dari slotnya, 3) tiket
    // mengembang jadi tombol ajakan.
    final slotT = Curves.easeOut.transform((v / 0.22).clamp(0.0, 1.0));
    final emergeRaw = ((v - 0.28) / 0.34).clamp(0.0, 1.0);
    final emerge = Curves.easeInOutCubic.transform(emergeRaw);
    final stubFade = 1 - ((v - 0.60) / 0.22).clamp(0.0, 1.0);
    final ctaRaw = ((v - 0.56) / 0.44).clamp(0.0, 1.0);
    final ctaT = Curves.easeOutBack.transform(ctaRaw);

    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);
    final slot = _slotPos(center, mSize);
    final target = _inviteTarget();

    // Stub bergerak dari slot ke posisi tombol.
    final stub = Offset.lerp(slot, target, emerge)!;

    // Ukuran tombol tiket, disesuaiin sama lebar panggung.
    final ctaW = math.min(240.0, _stageSize.width - 56);
    final ctaH = ctaW * 0.334;

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Slot tape TonTon menyala pas dibuka.
          _buildSlotGlow(center, mSize, opacity: slotT),

          // Stub tiket yang terdorong keluar dari dalam slot.
          Positioned(
            left: stub.dx - 59,
            top: stub.dy - 13,
            child: IgnorePointer(
              child: Opacity(
                opacity: (emergeRaw * 4).clamp(0.0, 1.0) * stubFade,
                child: Transform.scale(
                  scale: 0.32 + 0.68 * Curves.easeOutBack.transform(emergeRaw),
                  alignment: Alignment.topCenter,
                  child: _TicketStub(label: AppStrings.ticketEntry),
                ),
              ),
            ),
          ),

          // Stub mengembang jadi tombol ajakan.
          Positioned(
            left: target.dx - ctaW / 2,
            top: target.dy - ctaH / 2 + bob,
            child: Opacity(
              opacity: ctaRaw.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.45 + 0.55 * ctaT,
                alignment: Alignment.topCenter,
                child: _TicketCta(onTap: _goGenre, width: ctaW),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestartButton(Offset center, double mSize) {
    return Positioned(
      left: 24,
      right: 24,
      top: center.dy + mSize / 2 + 16,
      child: _PopIn(
        child: _BouncyButton(label: AppStrings.mascotAgain, onTap: _restart),
      ),
    );
  }

  // ---------------------------------------------------------------- slider
  Widget _buildSliders(Offset center, double mSize) {
    final enterT = Curves.easeOutBack.transform(_sliderEnter.value);
    final exitT = Curves.easeInOutQuart.transform(_sliderExit.value);
    final panelTop = center.dy + mSize / 2 + 8;

    final roll = (enterT * (1 - exitT)).clamp(0.0, 1.0);
    final opacity = (enterT * (1 - exitT * 0.7)).clamp(0.0, 1.0);

    return Positioned(
      left: 16,
      right: 16,
      top: panelTop,
      bottom: AppLayout.navSpacer,
      child: Opacity(
        opacity: opacity,
        child: _RollClip(t: roll, child: _buildSliderPanel()),
      ),
    );
  }

  Widget _buildSliderPanel() {
    final provider = context.watch<RecommendationProvider>();

    // Setiap baris muncul bertahap (stagger) supaya panelnya terasa hidup.
    Widget staged(Widget child, int i) {
      final t = Interval(
        (i * 0.14).clamp(0.0, 0.55),
        ((i * 0.14) + 0.42).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ).transform(_sliderEnter.value.clamp(0.0, 1.0));
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      );
    }

    return MarqueePanel(
      title: AppStrings.marqueeSliderTitle,
      subtitle: AppStrings.marqueeSliderSubtitle,
      animateIn: true,
      footer: staged(
        SizedBox(
          width: double.infinity,
          child: _BouncyButton(
            label: AppStrings.mascotSliderConfirm,
            onTap: _confirmSliders,
            height: 48,
          ),
        ),
        4,
      ),
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          staged(_buildRatingRow(provider), 0),
          const SizedBox(height: 14),
          staged(
            _buildRangeRow(
              icon: Icons.schedule_rounded,
              label: AppStrings.labelRuntime,
              value:
                  '${provider.runtimeRange.start.round()} - '
                  '${provider.runtimeRange.end.round()} menit',
              values: provider.runtimeRange,
              min: 0,
              max: 300,
              onChanged: (v) {
                provider.setRuntimeRange(v);
                _reactInput(
                  'durasi ${v.start.round()}-${v.end.round()} menit',
                  MascotExpression.thinking,
                );
              },
            ),
            1,
          ),
          const SizedBox(height: 14),
          staged(
            _buildRangeRow(
              icon: Icons.calendar_month_rounded,
              label: AppStrings.labelYear,
              value:
                  '${provider.yearRange.start.round()} - '
                  '${provider.yearRange.end.round()}',
              values: provider.yearRange,
              min: 1900,
              max: 2025,
              onChanged: (v) {
                provider.setYearRange(v);
                _reactInput(
                  'tahun ${v.start.round()}-${v.end.round()}',
                  MascotExpression.thinking,
                );
              },
            ),
            2,
          ),
          const SizedBox(height: 14),
          staged(_buildTopNRow(provider), 3),
        ],
      ),
    );
  }

  Widget _buildRatingRow(RecommendationProvider provider) {
    return JellySlider(
      label: AppStrings.labelMinRating,
      icon: Icons.star_rounded,
      valueText: provider.minRating.toStringAsFixed(1),
      value: provider.minRating.clamp(0, 10),
      min: 0,
      max: 10,
      divisions: 20,
      onChanged: (v) {
        provider.setMinRating(v);
        _reactInput(
          'rating minimal ${v.toStringAsFixed(1)}',
          MascotExpression.thinking,
        );
      },
    );
  }

  Widget _buildRangeRow({
    required String label,
    IconData? icon,
    required String value,
    required RangeValues values,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return JellyRangeSlider(
      label: label,
      icon: icon,
      valueText: value,
      values: values,
      min: min,
      max: max,
      onChanged: onChanged,
    );
  }

  Widget _buildTopNRow(RecommendationProvider provider) {
    return JellySlider(
      label: AppStrings.labelTopN,
      icon: Icons.movie_filter_rounded,
      valueText: '${provider.topN} film',
      value: provider.topN.toDouble().clamp(5, 30),
      min: 5,
      max: 30,
      divisions: 25,
      onChanged: (v) {
        provider.setTopN(v);
        _reactInput('cariin ${v.round()} film', MascotExpression.excited);
        _mascot.squish(-3);
      },
    );
  }

  // ---------------------------------------------------------------- keyword
  Widget _buildKeyword(Offset center, double mSize) {
    final enterT = Curves.easeOutBack.transform(_keywordEnter.value);
    return Positioned(
      left: 16,
      right: 16,
      top: center.dy + mSize / 2 + 10,
      child: Opacity(
        opacity: enterT.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: enterT,
          alignment: Alignment.topCenter,
          child: MarqueePanel(
            title: AppStrings.marqueeKeywordTitle,
            subtitle: AppStrings.marqueeKeywordSubtitle,
            animateIn: true,
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ChatField(
                    controller: _keywordCtrl,
                    onChanged: (value) {
                      context.read<RecommendationProvider>().setKeyword(value);
                      final teks = value.trim();
                      _reactInput(
                        teks.isEmpty
                            ? 'Kosongin kata kunci, oke.'
                            : 'Cari yang berbau "$teks"...',
                        MascotExpression.thinking,
                      );
                    },
                    onSubmitted: (_) => _submitKeyword(),
                  ),
                ),
                const SizedBox(width: 10),
                _SwallowButton(onTap: _submitKeyword),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kolom kata kunci di dalam papan marquee.
class _ChatField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _ChatField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.accentLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'mis. dream / mimpi, space / luar angkasa...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol "beri ke TonTon": bulat jelly dengan panah menuju mulut.
class _SwallowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SwallowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return JellyPress(
      onTap: onTap,
      pressedScale: 0.14,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_double_arrow_up_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Stub tiket bergaya marquee: dipakai di pojok papan dan saat transisi.
class _TicketStub extends StatelessWidget {
  final String label;

  const _TicketStub({required this.label});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE7C4), AppColors.accentLight],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_rounded,
                  size: 12,
                  color: Color(0xFF3A1B05),
                ),
                SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: Color(0xFF3A1B05),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          // Lubang tiket di sisi kiri-kanan.
          const Positioned(
            left: -3,
            top: 0,
            bottom: 0,
            child: Center(child: _TicketNotch()),
          ),
          const Positioned(
            right: -3,
            top: 0,
            bottom: 0,
            child: Center(child: _TicketNotch()),
          ),
        ],
      ),
    );
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Sel genre di papan marquee: kotak "lampu" yang menyala kalau dipilih.
class _GenreLight extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreLight({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JellyPress(
      onTap: onTap,
      pressedScale: 0.12,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.accentGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.glassBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol pil utama dengan gradien oranye. Kalau [onTap] null, tombol tampak
/// redup dan nggak merespons (dipakai saat syarat belum terpenuhi).
class _BouncyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;

  /// Kalau diisi, sudutnya membulat sebesar ini (bukan pil penuh). Dipakai
  /// biar tombolnya match gaya tombol di papan marquee.
  final double? radius;

  /// Ikon kecil di depan label (misal panah "lanjut").
  final IconData? icon;

  const _BouncyButton({
    required this.label,
    required this.onTap,
    this.height = 52,
    this.radius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return JellyPress(
      onTap: onTap,
      pressedScale: 0.06,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: icon == null ? 0 : 16),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(radius ?? height / 2),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animasi muncul "pop" sederhana (dipakai tombol yang muncul sekali).
///
/// Pakai controller manual (bukan TweenAnimationBuilder) supaya animasinya
/// nggak restart tiap parent rebuild bingkai.
class _PopIn extends StatefulWidget {
  final Widget child;

  const _PopIn({required this.child});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: t, child: widget.child),
        );
      },
    );
  }
}

/// Efek "gulung": panel dipotong dari tepi atas dan menciut ke bawahnya, jadi
/// kontennya nggak pernah teremas (beda sama Transform.scale).
///
/// [t] = proporsi panel yang masih kelihatan (1 = penuh, 0 = hilang).
class _RollClip extends StatelessWidget {
  final double t;

  /// Ruang tambahan di atas kotak yang ikut dipakai klip (mis. buat tiket
  /// penjuru yang menjulang keluar papan).
  final double room;
  final Widget child;

  const _RollClip({required this.t, required this.child, this.room = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.maxHeight * (1 - t) - room;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRect(
              clipper: _RollClipper(t, room: room),
              child: child,
            ),
            // Bayangan tipis di tepi gulungan biar dapat ketebalan fisik.
            if (t > 0 && t < 1)
              Positioned(
                left: 0,
                right: 0,
                top: edge - 8,
                height: 16,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RollClipper extends CustomClipper<Rect> {
  final double t;
  final double room;

  const _RollClipper(this.t, {this.room = 0});

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (1 - t) - room, size.width, size.height);

  @override
  bool shouldReclip(covariant _RollClipper oldDelegate) =>
      oldDelegate.t != t || oldDelegate.room != room;
}

/// Popup daftar rekomendasi: layar bioskop yang nyala dari berkas proyektor.
class _ResultsSheet extends StatefulWidget {
  const _ResultsSheet();

  @override
  State<_ResultsSheet> createState() => _ResultsSheetState();
}

class _ResultsSheetState extends State<_ResultsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _proj = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980),
  );

  @override
  void initState() {
    super.initState();
    _proj.forward();
  }

  @override
  void dispose() {
    _proj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    final watchlist = context.watch<WatchlistProvider>();
    final movies = provider.results;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          // AnimatedBuilder wajib ada: kalau nggak, nggak ada yang nungguin
          // controller jadi layarnya cuma gerak pas ada rebuild lain.
          child: AnimatedBuilder(
            animation: _proj,
            builder: (context, _) {
              final t = _proj.value;
              // 1) berkas proyektor nyala, 2) layar membesar, 3) isinya muncul.
              final growRaw = ((t - 0.30) / 0.70).clamp(0.0, 1.0);
              var beam = Curves.easeOutCubic.transform(
                ((t - 0.04) / 0.34).clamp(0.0, 1.0),
              );
              // Proyektor lagi "pemanasan": berkasnya kedap kedip dulu.
              if (beam > 0 && beam < 1) {
                beam *= 0.84 + 0.16 * math.sin(t * 52);
              }
              final grow = Curves.easeOutCubic.transform(growRaw);
              final reveal = Curves.easeOut.transform(
                ((t - 0.55) / 0.45).clamp(0.0, 1.0),
              );
              // Layar mengembung sedikit pas besar, biar ada tendangan halus.
              final pop = 1 + 0.035 * math.sin(growRaw * math.pi);

              return LayoutBuilder(
                builder: (context, c) {
                  final fullW = (c.maxWidth - 24).clamp(0.0, 520.0);
                  final fullH = (c.maxHeight - 30).clamp(0.0, 900.0);
                  final w = fullW * (0.30 + 0.70 * grow) * pop;
                  final h = fullH * (0.30 + 0.70 * grow) * pop;

                  return Stack(
                    children: [
                      // Handle geser di bibir atas panggung.
                      Positioned(
                        top: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Opacity(
                            opacity: 0.25 + 0.75 * reveal,
                            child: Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.glassBorder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Berkas cahaya proyektor.
                      Positioned(
                        top: 26,
                        left: 0,
                        right: 0,
                        height: 360,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: beam,
                            child: ClipPath(
                              clipper: _BeamClipper(halfBottom: w / 2 + 46),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0, 0.55, 1],
                                    colors: [
                                      const Color(
                                        0xFFFFF3DA,
                                      ).withValues(alpha: 0.42),
                                      const Color(
                                        0xFFFFE2B4,
                                      ).withValues(alpha: 0.13),
                                      const Color(
                                        0xFFFFE2B4,
                                      ).withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Layar yang membesar dari titik cahaya.
                      Center(
                        child: SizedBox(
                          key: const ValueKey('layarProyektor'),
                          width: w,
                          height: h,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                // Kain layar + cahaya pinggirnya.
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0E13),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFD9A0,
                                      ).withValues(alpha: 0.25 + 0.6 * grow),
                                      width: 1.2 + grow,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFC98A,
                                        ).withValues(alpha: 0.35 * grow),
                                        blurRadius: 24 + 24 * grow,
                                        spreadRadius: 2 * grow,
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, 12 * (1 - reveal)),
                                  child: Opacity(
                                    opacity: reveal,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            14,
                                            14,
                                            8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  AppStrings.mascotDone,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${movies.length} film',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.separated(
                                            controller: scrollController,
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              4,
                                              14,
                                              20,
                                            ),
                                            itemCount: movies.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final movie = movies[index];
                                              return MovieCard(
                                                movie: movie,
                                                rank: index + 1,
                                                isSaved: watchlist.isSaved(
                                                  movie.movieId,
                                                ),
                                                onToggleBookmark: () =>
                                                    toggleWatchlist(
                                                      context,
                                                      movie,
                                                    ),
                                                onTap: () =>
                                                    _openDetail(context, movie),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bola lampu proyektor, selalu di atas layar.
                      Positioned(
                        top: 8,
                        left: c.maxWidth / 2 - 11,
                        child: IgnorePointer(child: _ProjectorLamp(beam: beam)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, Movie movie) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailPage(movie: movie)));
  }
}

/// Klip berkas proyektor: meruncing dari titik lampu ke lebar layar.
class _BeamClipper extends CustomClipper<Path> {
  final double halfBottom;

  const _BeamClipper({required this.halfBottom});

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    return Path()
      ..moveTo(cx - 7, 0)
      ..lineTo(cx + 7, 0)
      ..lineTo(cx + halfBottom, size.height)
      ..lineTo(cx - halfBottom, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BeamClipper oldDelegate) =>
      oldDelegate.halfBottom != halfBottom;
}

/// Bola lampu proyektor yang nyala saat berkasnya keluar.
class _ProjectorLamp extends StatelessWidget {
  final double beam;

  const _ProjectorLamp({required this.beam});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xFF1A2129),
        border: Border.all(
          color: const Color(0xFFFFD9A0).withValues(alpha: 0.25 + 0.65 * beam),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE6C0).withValues(alpha: 0.85 * beam),
            blurRadius: 14 + 18 * beam,
            spreadRadius: 2 * beam,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF6E2).withValues(alpha: 0.3 + 0.7 * beam),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE9C4).withValues(alpha: 0.8 * beam),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol ajakan berbentuk tiket masuk: ada gigiran (notch) di kiri-kanan,
/// garis robek, dan label "TIKET MASUK".
class _TicketCta extends StatelessWidget {
  final VoidCallback onTap;
  final double width;

  const _TicketCta({required this.onTap, this.width = 240});

  @override
  Widget build(BuildContext context) {
    final h = width * 0.334;
    final stub = width * 0.26;

    return JellyPress(
      key: const ValueKey('ctaTiket'),
      onTap: onTap,
      pressedScale: 0.05,
      child: SizedBox(
        width: width,
        height: h,
        child: CustomPaint(
          painter: _TicketBodyPainter(stubX: stub),
          child: Row(
            children: [
              SizedBox(
                width: stub,
                child: Center(
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    size: width * 0.1,
                    color: const Color(0xFF6B3410),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.ticketEntry,
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF3A1B05),
                      fontSize: width * 0.067,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badan tiket: sudut membulat + gigiran di sisi kiri-kanan + garis robek.
class _TicketBodyPainter extends CustomPainter {
  final double stubX;

  const _TicketBodyPainter({required this.stubX});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _ticketPath(size);

    // Bayangan lembut di bawah tiket.
    canvas.drawPath(
      path.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE7C4), Color(0xFFFFB765)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF8A4A12).withValues(alpha: 0.35),
    );

    // Garis robek vertikal di antara stub dan badan tiket.
    final dash = Paint()
      ..color = const Color(0xFF8A4A12).withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    for (var y = size.height * 0.18; y < size.height * 0.82; y += 7) {
      canvas.drawLine(Offset(stubX, y), Offset(stubX, y + 3.6), dash);
    }
  }

  Path _ticketPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = 12.0;
    final nr = math.min(9.0, h * 0.16);
    final cy = h / 2;
    final k = nr * 0.5523;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, cy - nr)
      // Gigiran kanan, cekung ke dalam.
      ..cubicTo(w - k, cy - nr, w - nr, cy - k, w - nr, cy)
      ..cubicTo(w - nr, cy + k, w - k, cy + nr, w, cy + nr)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, cy + nr)
      // Gigiran kiri.
      ..cubicTo(k, cy + nr, nr, cy + k, nr, cy)
      ..cubicTo(nr, cy - k, k, cy - nr, 0, cy - nr)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldRepaint(covariant _TicketBodyPainter oldDelegate) =>
      oldDelegate.stubX != stubX;
}
