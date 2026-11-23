import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/poster_service.dart';

/// Poster film: dimuat dari URL (IMDb) lalu di-cache. Kalau gagal / tidak ada,
/// fallback ke kartu gradien dengan inisial judul.
class MoviePoster extends StatefulWidget {
  final String movieId;
  final String title;
  final double width;
  final double height;
  final BorderRadius radius;

  const MoviePoster({
    super.key,
    required this.movieId,
    required this.title,
    required this.width,
    required this.height,
    this.radius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<MoviePoster> createState() => _MoviePosterState();
}

class _MoviePosterState extends State<MoviePoster> {
  String? _url;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MoviePoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) _load();
  }

  Future<void> _load() async {
    final service = context.read<PosterService>();
    final url = await service.resolve(widget.movieId);
    if (!mounted) return;
    setState(() {
      _url = url;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _PosterFallback(
      title: widget.title,
      width: widget.width,
      height: widget.height,
      radius: widget.radius,
    );

    if (!_loaded || _url == null) return fallback;

    return ClipRRect(
      borderRadius: widget.radius,
      child: Image.network(
        _url!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

/// Fallback poster: gradien aksen + inisial judul.
class _PosterFallback extends StatelessWidget {
  final String title;
  final double width;
  final double height;
  final BorderRadius radius;

  const _PosterFallback({
    required this.title,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: radius,
        border: Border.all(color: AppColors.glassBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? '?' : title.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
