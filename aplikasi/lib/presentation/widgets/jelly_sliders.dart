import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Chip nilai kecil di samping label slider.
class _ValueChip extends StatelessWidget {
  final String text;

  const _ValueChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accentLight,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Slider satu nilai bergaya jelly: track kaca, isian gradien, dan thumb
/// bulat mengkilap yang membesar saat ditarik.
class JellySlider extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const JellySlider({
    super.key,
    required this.label,
    this.icon,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<JellySlider> createState() => _JellySliderState();
}

class _JellySliderState extends State<JellySlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  double _toValue(double localX, double width) {
    final t = (localX / width).clamp(0.0, 1.0);
    final step = (widget.max - widget.min) / widget.divisions;
    final raw = widget.min + t * (widget.max - widget.min);
    return (raw / step).round() * step;
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
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 17, color: AppColors.accentLight),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ValueChip(text: widget.valueText),
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final thumb = 28.0 + _press.value * 9;
            final cx = (t * w).clamp(thumb / 2, w - thumb / 2);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                _press.forward();
                widget.onChanged(_toValue(d.localPosition.dx, w));
              },
              onHorizontalDragUpdate: (d) =>
                  widget.onChanged(_toValue(d.localPosition.dx, w)),
              onHorizontalDragEnd: (_) => _press.reverse(),
              onTapDown: (d) {
                _press.forward();
                widget.onChanged(_toValue(d.localPosition.dx, w));
              },
              onTapUp: (_) => _press.reverse(),
              onTapCancel: () => _press.reverse(),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Track kaca.
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                    ),
                    // Isian gradien sampai thumb.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (cx / w).clamp(0.0, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // Thumb jelly.
                    Positioned(
                      left: cx - thumb / 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        width: thumb,
                        height: thumb,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            colors: [Colors.white, AppColors.accentLight],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Slider rentang dua thumb dengan pita gradien di antaranya.
class JellyRangeSlider extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String valueText;
  final RangeValues values;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  const JellyRangeSlider({
    super.key,
    required this.label,
    this.icon,
    required this.valueText,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<JellyRangeSlider> createState() => _JellyRangeSliderState();
}

class _JellyRangeSliderState extends State<JellyRangeSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  int _active = -1;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  double _toValue(double localX, double width) {
    final t = (localX / width).clamp(0.0, 1.0);
    return widget.min + t * (widget.max - widget.min);
  }

  @override
  Widget build(BuildContext context) {
    final span = widget.max - widget.min;
    final t0 = ((widget.values.start - widget.min) / span).clamp(0.0, 1.0);
    final t1 = ((widget.values.end - widget.min) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 17, color: AppColors.accentLight),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ValueChip(text: widget.valueText),
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final thumb = 26.0 + _press.value * 7;
            final x0 = (t0 * w).clamp(thumb / 2, w - thumb / 2);
            final x1 = (t1 * w).clamp(thumb / 2, w - thumb / 2);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                final v = _toValue(d.localPosition.dx, w);
                _active =
                    (v - widget.values.start).abs() <=
                        (v - widget.values.end).abs()
                    ? 0
                    : 1;
                _press.forward();
                _emit(v);
              },
              onHorizontalDragUpdate: (d) =>
                  _emit(_toValue(d.localPosition.dx, w)),
              onHorizontalDragEnd: (_) => _press.reverse(),
              onTapDown: (d) {
                final v = _toValue(d.localPosition.dx, w);
                _active =
                    (v - widget.values.start).abs() <=
                        (v - widget.values.end).abs()
                    ? 0
                    : 1;
                _press.forward();
                _emit(v);
              },
              onTapUp: (_) => _press.reverse(),
              onTapCancel: () => _press.reverse(),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                    ),
                    // Pita gradien di antara dua thumb.
                    Positioned(
                      left: x0,
                      width: (x1 - x0).clamp(0.0, w),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    _thumb(x0, thumb, active: _active == 0),
                    _thumb(x1, thumb, active: _active == 1),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _emit(double v) {
    final minGap = (widget.max - widget.min) / 40;
    var start = widget.values.start;
    var end = widget.values.end;
    if (_active == 0) {
      start = math.min(v, end - minGap);
    } else if (_active == 1) {
      end = math.max(v, start + minGap);
    } else {
      return;
    }
    widget.onChanged(
      RangeValues(
        start.clamp(widget.min, widget.max),
        end.clamp(widget.min, widget.max),
      ),
    );
  }

  Widget _thumb(double cx, double thumb, {required bool active}) {
    return Positioned(
      left: cx - thumb / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        width: thumb * (active ? 1.06 : 1),
        height: thumb * (active ? 1.06 : 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Colors.white, AppColors.accentLight],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: active ? 0.65 : 0.4),
              blurRadius: active ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
