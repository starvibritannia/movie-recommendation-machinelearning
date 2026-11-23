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
import '../widgets/mascot_bubble.dart';
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
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _sliderEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _sliderExit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _keywordEnter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  /// Penerbangan orb genre / gelembung kata ke mulut TonTon.
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 430),
  );
  late final AnimationController _keywordFly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  // ---------------- state panggung ----------------
  List<_OrbSpec> _orbs = const [];
  Size _stageSize = Size.zero;
  Offset _inviteCenter = Offset.zero;

  _Flight? _flying;
  String? _keywordBubble;
  Offset _keywordFrom = Offset.zero;

  Timer? _greetingTimer;
  Timer? _lookTimer;
  Timer? _pendingTimer;
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
    _lookTimer?.cancel();
    _pendingTimer?.cancel();
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
    _fly.dispose();
    _keywordFly.dispose();
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
    setState(() {
      _inviteCenter = _randomAround(
        _mascotCenter(_stageSize),
        _mascotSize(_stageSize),
      );
    });
    // Tangan turun halus, bukan hilang mendadak.
    _waveCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goGenre() {
    if (!mounted || _stageSize == Size.zero) return;
    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);

    _setPhase(_Phase.genre);
    setState(() {
      _orbs = _generateOrbs(_stageSize, center, mSize);
    });

    // Girang sekejap pas genre muncul, lalu tenang nunggu pilihan user.
    _mascot.hop(760);
    _mascot.squish(-6);
    _mascot.glance(8, -6);

    _pendingTimer?.cancel();
    _pendingTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _explodeToken++);
      _pendingTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted) _chipEnter.forward(from: 0);
      });
    });

    _startLook();
  }

  void _confirmGenre() {
    _lookTimer?.cancel();
    _setPhase(_Phase.absorb);
    _mascot.hop(620);
    _mascot.squish(-4);
    _mascot.swallow();
    _chipExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 180), _goSliders);
    });
  }

  void _goSliders() {
    if (!mounted) return;
    _setPhase(_Phase.sliders);
    _sliderEnter.forward(from: 0);
  }

  void _confirmSliders() {
    _setPhase(_Phase.sliderExit);
    _sliderExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 120), _goKeyword);
    });
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
    _lookTimer?.cancel();
    _chipEnter.reset();
    _chipExit.reset();
    _sliderEnter.reset();
    _sliderExit.reset();
    _keywordEnter.reset();
    setState(() {
      _orbs = const [];
    });
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

  void _toggleGenre(String genre, Offset orbCenter) {
    final provider = context.read<RecommendationProvider>();
    final willSelect = !provider.selectedGenres.contains(genre);
    if (_flying != null) return;
    _mascot.noteActivity();

    final center = _mascotCenter(_stageSize);
    final mSize = _mascotSize(_stageSize);
    final mouth = _mouthPos(center, mSize);

    if (willSelect) {
      _startFlight(
        _Flight(label: genre, from: orbCenter, to: mouth, select: true),
      );
    } else {
      _startFlight(
        _Flight(
          label: genre,
          from: _orbitPosOf(genre, center, mSize),
          to: orbCenter,
          select: false,
        ),
      );
    }
  }

  void _startFlight(_Flight flight) {
    setState(() => _flying = flight);
    _fly.forward(from: 0).then((_) {
      if (!mounted) return;
      final f = _flying;
      setState(() => _flying = null);
      if (f == null) return;
      context.read<RecommendationProvider>().toggleGenre(f.label);
      if (f.select) {
        _mascot.swallow();
        final reaction = _genreReactions[f.label];
        _reactNow(text: reaction?.$2, expression: reaction?.$1);
      } else {
        _mascot.squish(-4);
      }
    });
  }

  /// Posisi mulut TonTon di koordinat panggung (mulut ada di layar).
  Offset _mouthPos(Offset center, double mSize) =>
      center + Offset(0, 14 * mSize / 220);

  /// Posisi orbit orb yang lagi dipilih.
  Offset _orbitPosOf(String label, Offset center, double mSize) {
    final selected = context.read<RecommendationProvider>().selectedGenres;
    final list = AppStrings.availableGenres.where(selected.contains).toList();
    final i = list.indexOf(label);
    final angle =
        -math.pi / 2 +
        i * (2 * math.pi / math.max(1, list.length)) +
        _float.value * 0.8;
    final r = mSize * 0.78;
    return center + Offset(math.cos(angle) * r, math.sin(angle) * r * 0.55);
  }

  // ---------------------------------------------------------------- pandang
  void _startLook() {
    _lookTimer?.cancel();
    _lookTimer = Timer.periodic(const Duration(milliseconds: 1050), (_) {
      if (!mounted || _orbs.isEmpty) return;
      final target = _orbs[math.Random().nextInt(_orbs.length)].home;
      _lookAt(target);
    });
  }

  void _lookAt(Offset target) {
    final center = _mascotCenter(_stageSize);
    final d = target - center;
    final len = d.distance;
    if (len == 0) return;
    final dir = d / len;
    _mascot.lookDir(dir.dx.clamp(-1.0, 1.0), dir.dy.clamp(-1.0, 1.0) * 0.9);
  }

  // ---------------------------------------------------------------- geometri
  /// Di fase slider/keyword maskot naik & mengecil supaya panelnya muat.
  bool _compactMascot(_Phase phase) =>
      phase == _Phase.sliders ||
      phase == _Phase.sliderExit ||
      phase == _Phase.keyword;

  double _mascotSize(Size s) => _compactMascot(_phase)
      ? math.min(s.width * 0.34, 138)
      : math.min(s.width * 0.46, 184);

  Offset _mascotCenter(Size s) => _compactMascot(_phase)
      ? Offset(s.width / 2, s.height * 0.22)
      : Offset(s.width / 2, s.height * 0.40);

  Offset _randomAround(Offset center, double mascotSize) {
    final rng = math.Random();
    final angle = rng.nextDouble() * math.pi * 2;
    final radius = mascotSize * 0.78 + rng.nextDouble() * 24;
    final p =
        center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.78);
    return Offset(
      p.dx.clamp(84, _stageSize.width - 84),
      p.dy.clamp(128, _stageSize.height - 148),
    );
  }

  List<_OrbSpec> _generateOrbs(Size stage, Offset center, double mSize) {
    final rng = math.Random();
    final orbs = <_OrbSpec>[];

    final bubbleRect = Rect.fromLTWH(0, 0, stage.width, 108);
    // Area tombol "Lanjut" yang compact di bawah TonTon.
    final confirmRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + mSize / 2 + 26),
      width: 210,
      height: 82,
    );
    final mascotRect = Rect.fromCircle(center: center, radius: mSize * 0.60);

    for (final label in AppStrings.availableGenres) {
      final r = (15 + label.length * 1.35).clamp(22.0, 34.0);
      var placed = false;
      var pos = Offset.zero;

      for (var attempt = 0; attempt < 90 && !placed; attempt++) {
        final x = r + 10 + rng.nextDouble() * (stage.width - 2 * r - 20);
        final y =
            116 + r + rng.nextDouble() * (stage.height - 116 - 2 * r - 96);
        final rect = Rect.fromCircle(center: Offset(x, y), radius: r + 6);

        if (rect.overlaps(bubbleRect) || rect.overlaps(confirmRect)) continue;
        if (mascotRect.overlaps(rect)) continue;

        var overlap = false;
        for (final o in orbs) {
          if ((o.home - Offset(x, y)).distance < o.radius + r + 10) {
            overlap = true;
            break;
          }
        }
        if (overlap) continue;

        pos = Offset(x, y);
        placed = true;
      }

      if (!placed) {
        // Fallback: susun rapi kalau acak gagal (layar sempit).
        final idx = orbs.length;
        final col = idx % 5;
        final row = idx ~/ 5;
        pos = Offset(20 + col * (stage.width - 40) / 4, 124 + row * 52);
      }

      orbs.add(
        _OrbSpec(
          label: label,
          home: pos,
          radius: r,
          phase: rng.nextDouble() * math.pi * 2,
        ),
      );
    }
    return orbs;
  }

  // ---------------------------------------------------------------- tampil
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    final bubbleText = _reactionText ?? _bubbleText(provider);

    return AppScaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo/header_logo.png',
          height: 42,
          fit: BoxFit.contain,
        ),
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
                _fly,
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
                        child: MascotBubble(
                          text: bubbleText,
                          tail: BubbleTail.top,
                        ),
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

                    // Genre-genre mengapung (orb).
                    if (_phase == _Phase.genre || _phase == _Phase.absorb)
                      ..._buildOrbs(center, mSize),

                    // Gelembung kata kunci yang ditelan TonTon.
                    if (_keywordBubble != null)
                      _buildKeywordBubble(center, mSize),

                    // Tombol ajakan pertama.
                    if (_phase == _Phase.invite) _buildInvite(),

                    // Tombol konfirmasi genre.
                    if (_phase == _Phase.genre &&
                        provider.selectedGenres.isNotEmpty)
                      _buildConfirmGenre(center, mSize),

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

  // ---------------------------------------------------------------- chip
  List<Widget> _buildOrbs(Offset center, double mSize) {
    final selected = context.watch<RecommendationProvider>().selectedGenres;
    final selectedList = AppStrings.availableGenres
        .where(selected.contains)
        .toList();
    return [
      for (var i = 0; i < _orbs.length; i++)
        _buildOrb(_orbs[i], i, center, mSize, selected, selectedList),
    ];
  }

  double _orbProgress(double value, int index) {
    final start = (index * 0.02).clamp(0.0, 0.7);
    final end = (start + 0.24).clamp(0.0, 1.0);
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  Widget _buildOrb(
    _OrbSpec orb,
    int index,
    Offset center,
    double mSize,
    Set<String> selected,
    List<String> selectedList,
  ) {
    final isSelected = selected.contains(orb.label);
    final flight = _flying;

    final enterT = _orbProgress(_chipEnter.value, index);
    final exitT = _chipExit.value;
    final floatT = _float.value * math.pi * 2;

    final enterScale = Curves.easeOutBack.transform(enterT);
    final enterOpacity = enterT.clamp(0.0, 1.0);
    final from = (center - orb.home) * (1 - enterT) * 0.4;
    final floatDy = math.sin(floatT + orb.phase) * 5.0 * enterT;
    final floatDx = math.cos(floatT * 0.6 + orb.phase) * 3.0 * enterT;

    var pos = orb.home + from + Offset(floatDx, floatDy);
    var radius = orb.radius;
    var scale = enterScale;
    var opacity = enterOpacity;

    if (isSelected) {
      // Orb terpilih mengorbit TonTon.
      final i = selectedList.indexOf(orb.label);
      final angle =
          -math.pi / 2 +
          i * (2 * math.pi / math.max(1, selectedList.length)) +
          _float.value * 0.8;
      final r = mSize * 0.78;
      pos = center + Offset(math.cos(angle) * r, math.sin(angle) * r * 0.55);
      radius = 15;
    }

    if (flight != null && flight.label == orb.label) {
      final t = Curves.easeInCubic.transform(_fly.value);
      pos = Offset.lerp(flight.from, flight.to, t)!;
      scale = 1 - t * 0.82;
      opacity = 1 - t * 0.25;
      radius = radius * (1 - t * 0.4);
    }

    if (exitT > 0) {
      if (isSelected) {
        // Orb pilihan ditelan TonTon.
        pos = Offset.lerp(
          pos,
          _mouthPos(center, mSize),
          Curves.easeInCubic.transform(exitT),
        )!;
        scale = scale * (1 - exitT * 0.92);
        opacity = opacity * (1 - exitT);
      } else {
        // Orb yang nggak dipilih lenyap.
        pos = pos + Offset(0, -exitT * 26);
        scale = scale * (1 + exitT * 0.4);
        opacity = opacity * (1 - exitT);
      }
    }

    return Positioned(
      left: pos.dx - radius,
      top: pos.dy - radius,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: _GenreOrb(
            label: orb.label,
            radius: radius,
            selected: isSelected,
            onTap: () => _toggleGenre(orb.label, orb.home),
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
  Widget _buildInvite() {
    final floatT = _float.value * math.pi * 2;
    final dy = math.sin(floatT) * 6;
    return Positioned(
      left: _inviteCenter.dx - 86,
      top: _inviteCenter.dy - 26 + dy,
      child: _PopIn(
        child: _BouncyButton(label: AppStrings.mascotInvite, onTap: _goGenre),
      ),
    );
  }

  Widget _buildConfirmGenre(Offset center, double mSize) {
    // Tombol "Lanjut" compact yang nempel di bawah TonTon (bukan bar penuh),
    // supaya nggak menghalangi orb-orb genre.
    final floatT = _float.value * math.pi * 2;
    final dy = math.sin(floatT) * 4;
    return Positioned(
      left: center.dx - 82,
      top: center.dy + mSize / 2 + 2 + dy,
      child: _PopIn(
        child: _BouncyButton(
          label: AppStrings.mascotGenreConfirm,
          onTap: _confirmGenre,
          height: 46,
        ),
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
    final exitT = Curves.easeInCubic.transform(_sliderExit.value);
    final panelTop = center.dy + mSize / 2 + 8;

    final scale = enterT * (1 - exitT * 0.55);
    final opacity = enterT.clamp(0.0, 1.0) * (1 - exitT);
    // Saat keluar, panel "diserap" ke arah maskot (ke atas).
    final dy = (center.dy - panelTop) * exitT * 0.9;

    return Positioned(
      left: 16,
      right: 16,
      top: panelTop,
      bottom: AppLayout.navSpacer,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: _buildSliderPanel(),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderPanel() {
    final provider = context.watch<RecommendationProvider>();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingRow(provider),
                  _buildRangeRow(
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
                  _buildRangeRow(
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
                  _buildTopNRow(provider),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _BouncyButton(
              label: AppStrings.mascotSliderConfirm,
              onTap: _confirmSliders,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(RecommendationProvider provider) {
    return _SquishySlider(
      label: AppStrings.labelMinRating,
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
    required String value,
    required RangeValues values,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: (max - min).round(),
          labels: RangeLabels(
            values.start.round().toString(),
            values.end.round().toString(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTopNRow(RecommendationProvider provider) {
    return _SquishySlider(
      label: AppStrings.labelTopN,
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
      top: center.dy + mSize / 2 + 12,
      child: Opacity(
        opacity: enterT.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: enterT,
          alignment: Alignment.topCenter,
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.mascotKeywordAsk,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keywordCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitKeyword(),
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
                  decoration: const InputDecoration(
                    labelText: AppStrings.labelKeyword,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: _BouncyButton(
                    label: AppStrings.mascotSearch,
                    onTap: _submitKeyword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spesifikasi satu orb genre yang mengapung.
class _OrbSpec {
  final String label;
  final Offset home;
  final double radius;
  final double phase;

  const _OrbSpec({
    required this.label,
    required this.home,
    required this.radius,
    required this.phase,
  });
}

/// Penerbangan orb genre ke/dari mulut TonTon.
class _Flight {
  final String label;
  final Offset from;
  final Offset to;
  final bool select;

  const _Flight({
    required this.label,
    required this.from,
    required this.to,
    required this.select,
  });
}

/// Orb genre mengapung: bulat kenyal, berlabel, bisa di-tap buat ditelan.
class _GenreOrb extends StatelessWidget {
  final String label;
  final double radius;
  final bool selected;
  final VoidCallback onTap;

  const _GenreOrb({
    required this.label,
    required this.radius,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final bg = selected
        ? AppColors.accent.withValues(alpha: 0.32)
        : AppColors.glass;
    final border = selected ? AppColors.accent : AppColors.glassBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: border, width: selected ? 2 : 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slider kenyal: thumb bulat yang membesar saat ditarik.
class _SquishySlider extends StatefulWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SquishySlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<_SquishySlider> createState() => _SquishySliderState();
}

class _SquishySliderState extends State<_SquishySlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _update(double localX, double width) {
    final t = (localX / width).clamp(0.0, 1.0);
    final step = (widget.max - widget.min) / widget.divisions;
    final raw = widget.min + t * (widget.max - widget.min);
    widget.onChanged((raw / step).round() * step);
  }

  @override
  Widget build(BuildContext context) {
    final t = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 13)),
            Text(
              widget.valueText,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                _press.forward();
                _update(d.localPosition.dx, w);
              },
              onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, w),
              onHorizontalDragEnd: (_) => _press.reverse(),
              onTapDown: (d) {
                _press.forward();
                _update(d.localPosition.dx, w);
              },
              onTapUp: (_) => _press.reverse(),
              onTapCancel: () => _press.reverse(),
              child: AnimatedBuilder(
                animation: _press,
                builder: (context, _) {
                  final s = 1 + _press.value * 0.35;
                  return SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: t,
                            child: Container(
                              height: 8,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        Positioned(
                          left: (w - 30) * t,
                          child: Transform.scale(
                            scale: s,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Tombol pil utama dengan gradien oranye.
class _BouncyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;

  const _BouncyButton({
    required this.label,
    required this.onTap,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.accent.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
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

/// Popup daftar rekomendasi.
class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet();

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
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: movies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return MovieCard(
                      movie: movie,
                      rank: index + 1,
                      isSaved: watchlist.isSaved(movie.movieId),
                      onToggleBookmark: () => toggleWatchlist(context, movie),
                      onTap: () => _openDetail(context, movie),
                    );
                  },
                ),
              ),
            ],
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
