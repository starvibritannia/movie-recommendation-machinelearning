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
import '../widgets/tv_mascot.dart';
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
  bool _jumping = true;
  int _shakeToken = 0;
  int _explodeToken = 0;

  /// Animasi tangan setelah menyapa: 1 = melambai, 0 = turun ke sisi badan.
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  final Tween<Offset> _lookTween = Tween<Offset>(
    begin: Offset.zero,
    end: Offset.zero,
  );
  late final AnimationController _lookCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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

  // ---------------- state panggung ----------------
  List<_ChipSpec> _chips = const [];
  Size _stageSize = Size.zero;
  Offset _inviteCenter = Offset.zero;

  Timer? _greetingTimer;
  Timer? _lookTimer;
  Timer? _pendingTimer;
  Timer? _reactionTimer;
  Timer? _debounce;
  Timer? _jumpTimer;

  MascotMood? _reactionMood;
  String? _reactionText;

  final TextEditingController _keywordCtrl = TextEditingController();

  /// Reaksi maskot tiap genre: mood + kalimat lucu.
  static const Map<String, (MascotMood, String)> _genreReactions = {
    'Action': (MascotMood.excited, 'Gaskeun! Adrenaline dong.'),
    'Adventure': (MascotMood.excited, 'Petualangan, siap berangkat!'),
    'Animation': (MascotMood.excited, 'Animasi? Boleh banget!'),
    'Biography': (MascotMood.thinking, 'Kisah nyata, biar makin paham.'),
    'Comedy': (MascotMood.happy, 'Wkwk, aku bakal ketawa terus.'),
    'Crime': (MascotMood.thinking, 'Mode detektif: ON.'),
    'Documentary': (MascotMood.thinking, 'Biar makin paham dunia nyata.'),
    'Drama': (MascotMood.sad, 'Siap-siap, bawa tisu ya.'),
    'Family': (MascotMood.love, 'Nonton bareng keluarga, dong.'),
    'Film-Noir': (MascotMood.thinking, 'Gelap dan misterius, seleraku.'),
    'Game-Show': (MascotMood.excited, 'Acara game? Ikutan ya!'),
    'History': (MascotMood.thinking, 'Belajar masa lalu, asik.'),
    'Horror': (MascotMood.scared, 'Hah?! Seram nih, aku suka...'),
    'Music': (MascotMood.love, 'Lagunya bikin merinding nih.'),
    'Musical': (MascotMood.love, 'Bernyanyi yuk bareng!'),
    'Mystery': (MascotMood.thinking, 'Tebak-tebakan? Aku siap.'),
    'News': (MascotMood.thinking, 'Berita terkini, siap.'),
    'Reality-TV': (MascotMood.happy, 'Reality show, santuy.'),
    'Romance': (MascotMood.love, 'Aww, caption-caption manis dong.'),
    'Sci-Fi': (MascotMood.thinking, 'Menarik, kayak mimpi tapi nyata.'),
    'Short': (MascotMood.happy, 'Film pendek, cepet tapi nikmat.'),
    'Sport': (MascotMood.excited, 'Semangat! Aku dukung timmu.'),
    'Thriller': (MascotMood.scared, 'Deg-degan, lanjutkan!'),
    'War': (MascotMood.sad, 'Berat nih, tapi penting dipahami.'),
    'Western': (MascotMood.excited, 'Koboi? Gaskeun!'),
  };

  // ---------------------------------------------------------------- siklus
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecommendationProvider>().checkServerHealth();
    });
    _scheduleGreeting();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _lookTimer?.cancel();
    _pendingTimer?.cancel();
    _reactionTimer?.cancel();
    _debounce?.cancel();
    _jumpTimer?.cancel();
    _keywordCtrl.dispose();
    _lookCtrl.dispose();
    _waveCtrl.dispose();
    _chipEnter.dispose();
    _chipExit.dispose();
    _sliderEnter.dispose();
    _sliderExit.dispose();
    _keywordEnter.dispose();
    _float.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- alur
  void _scheduleGreeting() {
    _greetingTimer?.cancel();
    _greetingTimer = Timer(const Duration(milliseconds: 2600), _goInvite);
  }

  void _goInvite() {
    if (!mounted || _stageSize == Size.zero) return;
    setState(() {
      _phase = _Phase.invite;
      _jumping = false;
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

    setState(() {
      _phase = _Phase.genre;
      _chips = _generateChips(_stageSize, center, mSize);
      _shakeToken++;
      _jumping = true;
    });

    // Girang sekejap pas genre muncul, lalu tenang nunggu pilihan user.
    _jumpTimer?.cancel();
    _jumpTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _jumping = false);
    });

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
    setState(() {
      _phase = _Phase.absorb;
      _jumping = true;
    });
    _jumpTimer?.cancel();
    _jumpTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _jumping = false);
    });
    _chipExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 180), _goSliders);
    });
  }

  void _goSliders() {
    if (!mounted) return;
    setState(() => _phase = _Phase.sliders);
    _sliderEnter.forward(from: 0);
  }

  void _confirmSliders() {
    setState(() => _phase = _Phase.sliderExit);
    _sliderExit.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _pendingTimer = Timer(const Duration(milliseconds: 120), _goKeyword);
    });
  }

  void _goKeyword() {
    if (!mounted) return;
    setState(() => _phase = _Phase.keyword);
    _keywordEnter.forward(from: 0);
  }

  Future<void> _search() async {
    final provider = context.read<RecommendationProvider>();
    setState(() {
      _phase = _Phase.searching;
      _jumping = true;
    });
    await provider.search();
    if (!mounted) return;
    setState(() => _jumping = false);
    if (provider.results.isEmpty) {
      setState(() => _phase = _Phase.done);
      return;
    }
    _openResults();
  }

  void _openResults() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ResultsSheet(),
    ).whenComplete(() {
      if (mounted) setState(() => _phase = _Phase.done);
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
      _phase = _Phase.greeting;
      _chips = const [];
      _jumping = true;
    });
    _waveCtrl.animateTo(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
    );
    _scheduleGreeting();
  }

  // ---------------------------------------------------------------- reaksi
  void _reactNow({String? text, MascotMood? mood}) {
    _reactionTimer?.cancel();
    setState(() {
      _reactionText = text;
      _reactionMood = mood;
    });
    _reactionTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(_resetReaction);
    });
  }

  void _reactInput(String text, MascotMood mood) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), () {
      if (mounted) _reactNow(text: text, mood: mood);
    });
  }

  void _resetReaction() {
    _reactionText = null;
    _reactionMood = null;
  }

  void _toggleGenre(String genre) {
    final provider = context.read<RecommendationProvider>();
    final willSelect = !provider.selectedGenres.contains(genre);
    provider.toggleGenre(genre);

    // Batalkan pilihan: maskot diam, nggak reaksi.
    if (!willSelect) return;

    final reaction = _genreReactions[genre];
    _reactNow(text: reaction?.$2, mood: reaction?.$1);

    // Bouncy singkat tiap interaksi (bukan getar).
    _jumpTimer?.cancel();
    setState(() => _jumping = true);
    _jumpTimer = Timer(const Duration(milliseconds: 480), () {
      if (mounted) setState(() => _jumping = false);
    });
  }

  // ---------------------------------------------------------------- pandang
  void _startLook() {
    _lookTimer?.cancel();
    _lookTimer = Timer.periodic(const Duration(milliseconds: 1050), (_) {
      if (!mounted || _chips.isEmpty) return;
      final target = _chips[math.Random().nextInt(_chips.length)].center;
      _lookAt(target);
    });
  }

  void _lookAt(Offset target) {
    final center = _mascotCenter(_stageSize);
    final d = target - center;
    final len = d.distance;
    if (len == 0) return;
    final dir = d / len;
    final clamped = Offset(
      dir.dx.clamp(-1.0, 1.0),
      dir.dy.clamp(-1.0, 1.0) * 0.9,
    );
    _lookTween.begin = _lookTween.transform(_lookCtrl.value);
    _lookTween.end = clamped;
    _lookCtrl.forward(from: 0);
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

  List<_ChipSpec> _generateChips(Size stage, Offset center, double mSize) {
    final rng = math.Random();
    final chips = <_ChipSpec>[];

    final bubbleRect = Rect.fromLTWH(0, 0, stage.width, 108);
    final confirmRect = Rect.fromLTWH(
      0,
      center.dy + mSize / 2 + 4,
      stage.width,
      62,
    );

    for (final label in AppStrings.availableGenres) {
      final w = 22 + label.length * 6.6;
      final h = 30.0;
      var placed = false;
      var pos = Offset.zero;

      for (var attempt = 0; attempt < 90 && !placed; attempt++) {
        final x = 8 + rng.nextDouble() * (stage.width - w - 16);
        final y = 112 + rng.nextDouble() * (stage.height - 112 - h - 10);
        final rect = Rect.fromLTWH(x, y, w, h);

        if (rect.overlaps(bubbleRect) || rect.overlaps(confirmRect)) continue;
        if ((rect.center - center).distance < mSize * 0.60) continue;

        var overlap = false;
        for (final c in chips) {
          final other = Rect.fromCenter(
            center: c.center,
            width: c.width,
            height: c.height,
          );
          if (rect.inflate(6).overlaps(other)) {
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
        final idx = chips.length;
        final col = idx % 5;
        final row = idx ~/ 5;
        pos = Offset(10 + col * (stage.width - 20) / 4, 116 + row * 38);
      }

      chips.add(
        _ChipSpec(
          label: label,
          center: pos + Offset(w / 2, h / 2),
          width: w,
          height: h,
          phase: rng.nextDouble() * math.pi * 2,
          rotation: (rng.nextDouble() - 0.5) * 0.10,
        ),
      );
    }
    return chips;
  }

  // ---------------------------------------------------------------- tampil
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    final bubbleText = _reactionText ?? _bubbleText(provider);
    final mood = _reactionMood ?? _moodFor(provider);

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
                _lookCtrl,
                _waveCtrl,
              ]),
              builder: (context, _) {
                final mSize = _mascotSize(_stageSize);
                final center = _mascotCenter(_stageSize);
                final look = _lookTween.transform(_lookCtrl.value);

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
                        mood: mood,
                        size: mSize,
                        wave: _waveCtrl.value,
                        standing: true,
                        lookAt: look,
                        jumping: _jumping,
                        shakeToken: _shakeToken,
                        explodeToken: _explodeToken,
                      ),
                    ),

                    // Genre-genre mengapung.
                    if (_phase == _Phase.genre || _phase == _Phase.absorb)
                      ..._buildChips(center),

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

  MascotMood _moodFor(RecommendationProvider provider) {
    if (_phase == _Phase.done && provider.errorMessage != null) {
      return MascotMood.sad;
    }
    return switch (_phase) {
      _Phase.greeting => MascotMood.excited,
      _Phase.invite => MascotMood.happy,
      _Phase.genre => MascotMood.talking,
      _Phase.absorb => MascotMood.excited,
      _Phase.sliders || _Phase.sliderExit => MascotMood.talking,
      _Phase.keyword || _Phase.searching => MascotMood.thinking,
      _Phase.done => MascotMood.happy,
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
  List<Widget> _buildChips(Offset mascotCenter) {
    return [
      for (var i = 0; i < _chips.length; i++)
        _buildChip(_chips[i], i, mascotCenter),
    ];
  }

  double _chipProgress(double value, int index) {
    final start = (index * 0.018).clamp(0.0, 0.72);
    final end = (start + 0.26).clamp(0.0, 1.0);
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  Widget _buildChip(_ChipSpec spec, int index, Offset mascotCenter) {
    final selected = context
        .watch<RecommendationProvider>()
        .selectedGenres
        .contains(spec.label);

    final enterT = _chipProgress(_chipEnter.value, index);
    final exitT = _chipExit.value;
    final floatT = _float.value * math.pi * 2;

    final enterScale = Curves.easeOutBack.transform(enterT);
    final enterOpacity = enterT.clamp(0.0, 1.0);
    final from = (mascotCenter - spec.center) * (1 - enterT) * 0.45;
    final floatDy = math.sin(floatT + spec.phase) * 4.5 * enterT;
    final rot =
        spec.rotation + math.sin(floatT * 0.7 + spec.phase) * 0.04 * enterT;

    var pos = spec.center + from + Offset(0, floatDy);
    var scale = enterScale;
    var opacity = enterOpacity;
    Color? burnColor;

    if (exitT > 0) {
      if (selected) {
        // Genre pilihan diserap maskot: terbang ke tengah lalu mengecil.
        pos = Offset.lerp(
          spec.center,
          mascotCenter,
          Curves.easeInCubic.transform(exitT),
        )!;
        scale = enterScale * (1 - exitT * 0.92);
        opacity = enterOpacity * (1 - exitT);
      } else {
        // Genre yang nggak dipilih "hangus": membesar lalu memudar.
        pos = spec.center + Offset(0, -exitT * 30);
        scale = enterScale * (1 + exitT * 0.5);
        opacity = enterOpacity * (1 - exitT);
        burnColor = const Color(0xFFFF4D2D);
      }
    }

    return Positioned(
      left: pos.dx - spec.width / 2,
      top: pos.dy - spec.height / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: AnimatedScale(
              scale: selected ? 1.22 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: _FloatingChip(
                label: spec.label,
                width: spec.width,
                height: spec.height,
                selected: selected,
                burnColor: burnColor,
                onTap: () => _toggleGenre(spec.label),
              ),
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
    return Positioned(
      left: 24,
      right: 24,
      top: center.dy + mSize / 2 + 12,
      child: _PopIn(
        child: _BouncyButton(
          label: AppStrings.mascotGenreConfirm,
          onTap: _confirmGenre,
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
                        MascotMood.thinking,
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
                        MascotMood.thinking,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.labelMinRating,
              style: TextStyle(fontSize: 13),
            ),
            Text(
              provider.minRating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: provider.minRating.clamp(0, 10),
          min: 0,
          max: 10,
          divisions: 20,
          label: provider.minRating.toStringAsFixed(1),
          onChanged: (v) {
            provider.setMinRating(v);
            _reactInput(
              'rating minimal ${v.toStringAsFixed(1)}',
              MascotMood.thinking,
            );
          },
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.labelTopN, style: TextStyle(fontSize: 13)),
            Text(
              '${provider.topN} film',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: provider.topN.toDouble().clamp(5, 30),
          min: 5,
          max: 30,
          divisions: 25,
          label: '${provider.topN}',
          onChanged: (v) {
            provider.setTopN(v);
            _reactInput('cariin ${v.round()} film', MascotMood.excited);
          },
        ),
      ],
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
                  onSubmitted: (_) => _search(),
                  onChanged: (value) {
                    context.read<RecommendationProvider>().setKeyword(value);
                    final teks = value.trim();
                    _reactInput(
                      teks.isEmpty
                          ? 'Kosongin kata kunci, oke.'
                          : 'Cari yang berbau "$teks"...',
                      MascotMood.thinking,
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
                    onTap: _search,
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

/// Spesifikasi satu chip genre yang mengapung.
class _ChipSpec {
  final String label;
  final Offset center;
  final double width;
  final double height;
  final double phase;
  final double rotation;

  const _ChipSpec({
    required this.label,
    required this.center,
    required this.width,
    required this.height,
    required this.phase,
    required this.rotation,
  });
}

/// Chip genre mengapung.
class _FloatingChip extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final bool selected;
  final Color? burnColor;
  final VoidCallback onTap;

  const _FloatingChip({
    required this.label,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
    this.burnColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.accent.withValues(alpha: 0.30)
        : burnColor?.withValues(alpha: 0.35) ?? AppColors.glass;
    final border = selected
        ? AppColors.accent
        : (burnColor ?? AppColors.glassBorder);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2.4),
          border: Border.all(color: border, width: selected ? 1.6 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
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

/// Tombol pil utama dengan gradien oranye.
class _BouncyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BouncyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
