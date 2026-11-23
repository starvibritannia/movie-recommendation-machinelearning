import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ekspresi TonTon.
///
/// Diadopsi dari GoSpeak (18 ekspresi) plus `thinking` dan `talking` yang
/// dipakai alur aplikasi.
enum MascotExpression {
  neutral,
  happy,
  excited,
  love,
  surprised,
  skeptical,
  smug,
  sheepish,
  cheeky,
  thinking,
  talking,
  sad,
  devastated,
  wince,
  annoyed,
  angry,
  furious,
  horrified,
  unamused,
  asleep,
}

double _clamp(double v, double a, double b) => v < a ? a : (v > b ? b : v);

/// Preset "feel" tubuh: seberapa lentur TonTon bereaksi.
///
/// Port dari preset firm/soft/jelly milik GoSpeak.
class MascotFeel {
  final double k;
  final double c;
  final double ripple;
  final double dent;
  final double turb;

  const MascotFeel({
    required this.k,
    required this.c,
    required this.ripple,
    required this.dent,
    required this.turb,
  });

  static const firm = MascotFeel(k: 110, c: 17, ripple: 0, dent: .35, turb: .5);
  static const soft = MascotFeel(
    k: 130,
    c: 14,
    ripple: .08,
    dent: .7,
    turb: .8,
  );
  static const jelly = MascotFeel(k: 150, c: 11, ripple: 1, dent: 1, turb: 1);
}

class _Drag {
  final Offset off;
  final Offset start;
  bool moved = false;

  _Drag({required this.off, required this.start});
}

/// Mesin fisika + perilaku TonTon.
///
/// Port dari engine karakter "Preppy" di GoSpeak: squash & stretch berbasis
/// spring, lompat bermassa, pandangan mengikut pointer, perilaku otonom
/// (kedip, ngelirik, lompat, tidur), dan eskalasi ekspresi saat di-poke.
///
/// Semua posisi di sini dalam ruang kanvas 220x220 (sama seperti painter),
/// jadi pointer dari widget perlu dikonversi dulu.
class TontonEngine {
  TontonEngine({
    MascotExpression expression = MascotExpression.neutral,
    this.feel = MascotFeel.soft,
    Color color = const Color(0xFFFF7A18),
  }) : baseExpression = expression,
       color = color,
       _colorFrom = color,
       _colorTo = color;

  // ------------------------------------------------------------ konfigurasi
  MascotExpression baseExpression;
  MascotExpression? _overrideExpression;
  double _overrideUntil = 0;

  bool talking = false;
  double wave = 0;
  bool autonomy = true;
  bool interactive = true;
  bool followPointer = true;
  bool reducedMotion = false;
  MascotFeel feel;
  MascotFeel? _feelBefore;

  /// Batas tinggi lompat (dalam ruang 220) supaya lompatan tetap sebanding
  /// dengan ukuran TonTon, meski power yang diminta besar.
  double maxHopHeight = 90;

  /// Batas sejauh mana TonTon bisa diseret (ruang 220).
  double dragRange = 100;

  /// Offset mengambang halus (bukan pijakan, cuma gerak idle).
  double bobY = 0;

  Color color;
  Color _colorFrom;
  Color _colorTo;
  double _colorT0 = 0;

  /// Ekspresi efektif: override sementara (poke/idle) menang atas base.
  MascotExpression get expression => _overrideExpression ?? baseExpression;

  // ------------------------------------------------------------ waktu
  double time = 0;
  double _talkT0 = 0;

  // ------------------------------------------------------------ pose
  Offset home = Offset.zero;
  Offset pos = Offset.zero;
  Offset vel = Offset.zero;
  Offset target = Offset.zero;
  bool airborne = false;
  double _launchAt = 0;
  double _launchPower = 0;
  double? _launchToX;

  double sq = 0; // squash: positif = melebar/pendek, negatif = menjulang
  double sqv = 0;
  double? sqHold;

  double lean = 0;
  double leanTarget = 0;

  double gazeX = 0;
  double gazeY = 0;
  double _gazeTX = 0;
  double _gazeTY = 0;

  double blink = 1;
  double _nextBlink = 0;
  double _blinkUntil = 0;

  double mouthOpen = 0;
  double mouthRound = 0.5;

  /// Bukaan mulut paksa (nelan). 1 = lebar, lalu decay ke 0.
  double gulp = 0;

  /// Baris teks yang "masuk" ke layar TV (kata kunci).
  final List<String> screenLines = [];

  double armRaise = 0;
  double armAngle = -0.8;
  double _armG = 0;
  double _armGv = 0;
  Offset? pointTo;

  String? gestureKind;
  double _gestureUntil = 0;
  double _giggleNext = 0;
  int _giggles = 0;

  bool asleep = false;
  bool waking = false;

  double _nextIdle = 0;
  double _lastActivity = 0;
  double _glanceUntil = 0;
  Offset? pointer;

  int pokes = 0;
  double _lastPoke = 0;

  _Drag? _drag;

  double nodDip = 0;
  double _nodT0 = 0;
  double _nodDip = 0;
  double _nodDipMs = 0;

  double _tiltT0 = 0;
  double _tiltMs = 0;
  double _tiltAmt = 0;

  double _drowseT0 = 0;
  double _drowseMs = 0;
  final double _slump = 0;

  int _furyStep = 0;
  double _furyAt = 0;

  final math.Random _rng = math.Random();

  // ------------------------------------------------------------ siklus
  void tick(double dt) {
    if (dt <= 0) return;
    time += dt;
    _behave();
    _hear(dt);
    // substep fisika biar stabil di frame rate berapa pun
    const h = 1 / 240;
    var remaining = dt;
    while (remaining > 1e-6) {
      final s = math.min(h, remaining);
      _step(s);
      remaining -= s;
    }
  }

  void _step(double dt) {
    // peluncuran lompat
    if (_launchAt != 0 && time >= _launchAt && !airborne) {
      airborne = true;
      sqHold = null;
      sqv -= 9;
      var vx = vel.dx + (_rng.nextDouble() - .5) * 60;
      if (_launchToX != null) {
        final dx = _launchToX! - home.dx;
        home = Offset(_launchToX!, home.dy);
        target = home;
        vx = dx / (2 * _launchPower / 2600);
      }
      vel = Offset(vx, -_launchPower);
      _launchAt = 0;
      _launchToX = null;
    }

    if (airborne) {
      vel = Offset(vel.dx + (home.dx - pos.dx) * 4 * dt, vel.dy + 2600 * dt);
      pos += vel * dt;
      if (pos.dy >= home.dy && vel.dy > 0) {
        pos = Offset(pos.dx, home.dy);
        sqv += 0.008 * vel.dy;
        vel = Offset(vel.dx, 0);
        airborne = false;
      }
    } else {
      final k = _drag != null ? 420.0 : 110.0;
      final c = _drag != null ? 30.0 : 11.0;
      vel = Offset(
        vel.dx + (k * (target.dx - pos.dx) - c * vel.dx) * dt,
        vel.dy + (k * (target.dy - pos.dy) - c * vel.dy) * dt,
      );
      pos += vel * dt;
    }

    // squash & stretch
    final s = sqHold ?? _restSquash();
    sqv += (230 * (s - sq) - 13 * sqv) * dt;
    sq = _clamp(sq + sqv * dt, -0.28, 0.4);

    // mengambang: bob halus (menggantikan pijakan yang dulu tak terlihat)
    bobY = reducedMotion
        ? 0
        : math.sin(time * 1.6) * 3.0 + math.sin(time * 0.8) * 1.5;

    // bukaan mulut paksa (nelan) decay pelan
    gulp = math.max(0, gulp - 2.6 * dt);

    // lean
    lean += (leanTarget - lean) * math.min(1, 5 * dt);

    // lengan
    final mode = gestureKind != null;
    final lk = mode ? 200.0 : 110.0;
    final lc = mode ? 22.0 : 21.0;
    _armGv += (lk * (mode ? 1 : 0) - lc * _armGv) * dt;
    _armG = _clamp(_armG + _armGv * dt, 0, 1.15);
    armRaise = math.max(wave, _armG);
    final baseAngle = pointTo != null ? _angleTo(pointTo!) : -0.8;
    armAngle += _angleDelta(baseAngle, armAngle) * math.min(1, 10 * dt);

    // pandangan
    gazeX += (_gazeTX - gazeX) * math.min(1, 12 * dt);
    gazeY += (_gazeTY - gazeY) * math.min(1, 12 * dt);

    // transisi warna
    if (_colorTo != color) {
      final t = _clamp((time - _colorT0) / 0.4, 0.0, 1.0);
      color = Color.lerp(_colorFrom, _colorTo, t)!;
    }
  }

  void _behave() {
    // pandangan
    if (time > _glanceUntil) {
      if (pointer != null && !asleep && followPointer) {
        const face = Offset(110, 104);
        _gazeTX = _clamp((pointer!.dx - face.dx - pos.dx) * 0.06, -13, 13);
        _gazeTY = _clamp((pointer!.dy - face.dy - pos.dy) * 0.06, -8, 10);
      } else {
        _gazeTX = 0;
        _gazeTY = 0;
      }
    }

    // lean: ngikut pointer, atau ayunan halus saat melayang
    leanTarget = (pointer != null && !asleep && _drag == null && followPointer)
        ? _clamp((pointer!.dx - 110 - pos.dx) / 900, -0.25, 0.25)
        : 0.16 * math.sin(time * math.pi * 2 / 3.4);

    // tilt sementara (mis. saat di-poke)
    final ts = (time - _tiltT0) / (_tiltMs > 0 ? _tiltMs : 1);
    if (ts >= 0 && ts < 1 && !asleep) {
      leanTarget += _tiltAmt * math.sin(math.pi * ts);
    }

    // gesture
    if (gestureKind != null) {
      if (time >= _gestureUntil) {
        _stopGesture();
      } else if (gestureKind == 'giggle' && time >= _giggleNext) {
        _giggleNext = time + 0.13;
        squish(_giggles++ % 2 == 0 ? 2.6 : -2.6);
      }
    }

    // kedip
    if (!reducedMotion && !asleep && time > _nextBlink) {
      _blinkUntil = time + 0.09;
      _nextBlink =
          time +
          (_rng.nextDouble() < 0.18 ? 0.22 : 2.2 + 3.4 * _rng.nextDouble());
    }
    blink = (!reducedMotion && time < _blinkUntil) ? 0.1 : 1.0;

    // ngantuk
    final ds = (time - _drowseT0) / (_drowseMs > 0 ? _drowseMs : 1);
    if (!reducedMotion && !asleep && ds >= 0 && ds < 1) {
      blink = math.min(blink, 1 - 0.88 * math.pow(math.sin(math.pi * ds), 0.7));
    }

    // habisnya override ekspresi
    if (_overrideExpression != null &&
        _overrideUntil.isFinite &&
        time >= _overrideUntil) {
      _overrideExpression = null;
    }

    // anggukan (nod): badan tertekan sebentar
    final ns = (time - _nodT0) / (_nodDipMs > 0 ? _nodDipMs : 1);
    nodDip = (ns >= 0 && ns < 1) ? _nodDip * math.sin(math.pi * ns) : 0;

    _tickFury();

    // otonomi
    if (!autonomy || _drag != null) return;
    if (!asleep && time - _lastActivity > 22) {
      _sleep();
      return;
    }
    if (asleep || time < _nextIdle) return;
    _nextIdle = time + 2.6 + 3.8 * _rng.nextDouble();
    final h = _rng.nextDouble();
    if (h < 0.30) {
      final a = _rng.nextDouble() * math.pi * 2;
      _gazeTX = 12 * math.cos(a);
      _gazeTY = 7 * math.sin(a);
      _glanceUntil = time + 0.7 + 0.7 * _rng.nextDouble();
    } else if (h < 0.48) {
      hop(420 + 220 * _rng.nextDouble());
    } else if (h < 0.62) {
      squish(-7);
    } else if (h < 0.76) {
      _setOverride(
        _rng.nextBool() ? MascotExpression.smug : MascotExpression.sheepish,
        1.1,
      );
    } else {
      gesture('wave', 1400);
    }
  }

  void _hear(double dt) {
    if (talking) {
      final s = _synthetic(time - _talkT0);
      mouthOpen = _clamp(s.$1 * 1.4, 0.0, 1.0);
      mouthRound = s.$2;
    } else {
      mouthOpen = math.max(0.0, mouthOpen - 6 * dt);
      mouthRound = 0.5;
    }
  }

  /// Suara sintetis: pola buka/bulat mulut yang berubah-ubah seperti orang
  /// ngomong. Port dari `syntheticSpeech` milik GoSpeak.
  (double, double) _synthetic(double t) {
    final e = t;
    final open =
        _clamp((math.sin(1.3 * e + .7) + .55) * 3, 0.0, 1.0) *
        math.pow(math.sin(e * math.pi * 4.2).abs(), 1.4).toDouble() *
        (.5 + .35 * math.sin(2.1 * e));
    final round = .4 + .35 * math.sin(2.9 * e + 1);
    return (open, round);
  }

  double _restSquash() {
    if (reducedMotion) return (asleep ? 0.07 : 0.0) + _slump;
    final base = asleep
        ? 0.07 + 0.05 * math.sin(time / 4.6)
        : 0.02 * math.sin(time / 3.2);
    return base + _slump - (talking ? 0.06 * mouthOpen : 0.0);
  }

  // ------------------------------------------------------------ API publik
  void setExpression(MascotExpression e) {
    baseExpression = e;
    _overrideExpression = null;
    _furyStep = 0;
  }

  void setTalking(bool v) {
    if (v == talking) return;
    talking = v;
    _talkT0 = time;
  }

  void setWave(double v) => wave = _clamp(v, 0.0, 1.0);

  void setColor(Color c) {
    if (c == _colorTo) return;
    _colorFrom = color;
    _colorTo = c;
    _colorT0 = time;
  }

  void lookDir(double dx, double dy) {
    _gazeTX = _clamp(dx * 13, -13, 13);
    _gazeTY = _clamp(dy * 8, -8, 10);
    _glanceUntil = time + 0.9;
  }

  void noteActivity() {
    _lastActivity = time;
    if (asleep && autonomy) wake();
  }

  void glance(double x, double y, [double ms = 900]) {
    if (reducedMotion || asleep) return;
    _gazeTX = _clamp(x, -13, 13);
    _gazeTY = _clamp(y, -8, 10);
    _glanceUntil = time + ms / 1000.0;
  }

  void hop([double power = 620]) {
    if (reducedMotion || airborne || _launchAt != 0) return;
    sqHold = 0.22;
    _launchAt = time + 0.12;
    _launchPower = _clampPower(power);
    _launchToX = null;
    _lastActivity = time;
  }

  void hopTo(double x, [double power = 620]) {
    if (reducedMotion || airborne || _launchAt != 0) return;
    sqHold = 0.22;
    _launchAt = time + 0.12;
    _launchPower = _clampPower(power);
    _launchToX = x;
    _lastActivity = time;
  }

  double _clampPower(double power) =>
      math.min(power, math.sqrt(2 * 2600 * maxHopHeight));

  void squish([double amount = 6]) => sqv += amount;

  /// Buka mulut lebar sebentar (efek nelan).
  void swallow([double amount = 1]) {
    gulp = math.max(gulp, amount);
    squish(7);
  }

  /// Tambah baris teks ke layar TV (maksimal 3 baris).
  void pushScreenLine(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    screenLines.add(t);
    if (screenLines.length > 3) screenLines.removeAt(0);
  }

  void clearScreen() {
    screenLines.clear();
    gulp = 0;
  }

  void nod([bool big = false]) {
    if (reducedMotion || asleep) return;
    _nodDip = big ? 8.5 : 5.0;
    _nodDipMs = big ? 0.52 : 0.32;
    _nodT0 = time;
    squish(big ? 3.8 : 2.4);
  }

  void gesture(String kind, [double ms = 1200]) {
    _stopGesture();
    if (reducedMotion) return;
    gestureKind = kind;
    _gestureUntil = time + ms / 1000.0;
    if (kind == 'giggle') {
      _giggles = 0;
      _giggleNext = time;
      _feelBefore = feel;
      feel = MascotFeel.jelly;
    }
  }

  void _stopGesture() {
    gestureKind = null;
    pointTo = null;
    if (_feelBefore != null) {
      feel = _feelBefore!;
      _feelBefore = null;
    }
  }

  void tilt(double amount, [double ms = 300]) {
    if (reducedMotion || asleep) return;
    _tiltT0 = time;
    _tiltMs = ms / 1000.0;
    _tiltAmt = amount;
  }

  void drowse([double ms = 1200]) {
    if (reducedMotion || asleep) return;
    _drowseT0 = time;
    _drowseMs = ms / 1000.0;
    squish(2.5);
  }

  // ------------------------------------------------------------ sentuhan
  void pointerDown(Offset local) {
    if (!interactive) return;
    if (!_hit(local)) return;
    _lastActivity = time;
    if (asleep && autonomy) wake();
    _drag = _Drag(off: local - pos, start: local);
    airborne = false;
    sqHold = 0.08;
  }

  void pointerMove(Offset local) {
    pointer = local;
    _lastActivity = time;
    if (asleep && autonomy) wake();
    final d = _drag;
    if (d != null) {
      if ((local - d.start).distance > 6) d.moved = true;
      target = Offset(
        _clamp(local.dx - d.off.dx, -dragRange, dragRange),
        _clamp(local.dy - d.off.dy, -dragRange, dragRange),
      );
    }
  }

  void pointerUp() {
    final d = _drag;
    if (d == null) return;
    _drag = null;
    sqHold = null;
    target = home;
    if (d.moved) {
      final speed = vel.distance;
      _setOverride(
        speed > 900 ? MascotExpression.horrified : MascotExpression.excited,
        1.1,
      );
    } else {
      poke(d.start);
    }
  }

  void poke(Offset local) {
    sqv += 2 * feel.dent;
    _tiltAmt = (local.dx - pos.dx) >= 0 ? 0.18 : -0.18;
    _tiltT0 = time;
    _tiltMs = 0.28;
    pokes = (time - _lastPoke < 2.2) ? pokes + 1 : 1;
    _lastPoke = time;
    const seq = [
      MascotExpression.happy,
      MascotExpression.excited,
      MascotExpression.surprised,
      MascotExpression.wince,
      MascotExpression.annoyed,
      MascotExpression.angry,
      MascotExpression.angry,
    ];
    if (pokes >= 8) {
      _startFury();
    } else {
      _setOverride(seq[math.min(pokes - 1, seq.length - 1)], 1.8);
    }
  }

  bool _hit(Offset local) {
    const body = Rect.fromLTWH(42, 44, 136, 128);
    return body.shift(pos).contains(local);
  }

  void _setOverride(MascotExpression e, double seconds) {
    _overrideExpression = e;
    _overrideUntil = time + seconds;
  }

  void _startFury() {
    pokes = 0;
    _furyStep = 1;
    _furyAt = time;
    _overrideExpression = MascotExpression.furious;
    _overrideUntil = time + 1.6;
    hop(700);
  }

  void _tickFury() {
    if (_furyStep == 0) return;
    if (_furyStep == 1 && time >= _furyAt + 1.6) {
      _furyStep = 2;
      _furyAt = time;
      _overrideExpression = MascotExpression.unamused;
      _overrideUntil = time + 0.9;
      squish(-4);
    } else if (_furyStep == 2 && time >= _furyAt + 0.9) {
      _furyStep = 0;
      _overrideExpression = null;
    }
  }

  // ------------------------------------------------------------ tidur
  void _sleep() {
    if (asleep) return;
    asleep = true;
    _overrideExpression = MascotExpression.asleep;
    _overrideUntil = double.infinity;
    setColor(const Color(0xFF8E949E));
  }

  void wake() {
    if (!asleep) return;
    asleep = false;
    waking = true;
    _lastActivity = time;
    setColor(const Color(0xFFFF7A18));
    _overrideExpression = MascotExpression.surprised;
    _overrideUntil = time + 0.7;
    hop(700);
  }

  // ------------------------------------------------------------ util
  double _angleTo(Offset p) {
    const anchor = Offset(176, 124);
    return math.atan2(p.dy - anchor.dy, p.dx - anchor.dx);
  }

  double _angleDelta(double target, double current) {
    var d = target - current;
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d < -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }
}

/// Pemegang engine + sumber notifikasi untuk widget TonTon.
class MascotController extends ChangeNotifier {
  final TontonEngine engine;

  MascotController({TontonEngine? engine}) : engine = engine ?? TontonEngine();

  void tick(double dt) {
    engine.tick(dt);
    notifyListeners();
  }

  void setExpression(MascotExpression e) => engine.setExpression(e);
  void setTalking(bool v) => engine.setTalking(v);
  void setWave(double v) => engine.setWave(v);
  void setColor(Color c) => engine.setColor(c);
  void hop([double power = 620]) => engine.hop(power);
  void hopTo(double x, [double power = 620]) => engine.hopTo(x, power);
  void squish([double amount = 6]) => engine.squish(amount);
  void swallow([double amount = 1]) => engine.swallow(amount);
  void pushScreenLine(String text) => engine.pushScreenLine(text);
  void clearScreen() => engine.clearScreen();
  void lookDir(double dx, double dy) => engine.lookDir(dx, dy);
  void noteActivity() => engine.noteActivity();
  void glance(double x, double y, [double ms = 900]) => engine.glance(x, y, ms);
  void nod([bool big = false]) => engine.nod(big);
  void gesture(String kind, [double ms = 1200]) => engine.gesture(kind, ms);
  void tilt(double amount, [double ms = 300]) => engine.tilt(amount, ms);
  void drowse([double ms = 1200]) => engine.drowse(ms);
  void poke(Offset local) => engine.poke(local);
  void pointerDown(Offset local) => engine.pointerDown(local);
  void pointerMove(Offset local) => engine.pointerMove(local);
  void pointerUp() => engine.pointerUp();
  void wake() => engine.wake();
}
