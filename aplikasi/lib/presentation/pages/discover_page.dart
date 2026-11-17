import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_layout.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_search_field.dart';
import '../widgets/server_status_badge.dart';
import 'results_page.dart';

/// Tab 2 (Discover): form kriteria rekomendasi.
///
/// Ini tempat model machine learning dipakai: kriteria user dikirim ke backend
/// FastAPI, lalu hasilnya ditampilkan di halaman ResultsPage.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cek health server sekali saat halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecommendationProvider>().checkServerHealth();
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();

    return AppScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabDiscover),
        actions: [ServerStatusBadge(isOnline: provider.isServerOnline)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            8,
            AppLayout.screenPadding,
            AppLayout.navSpacer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.discoverSubtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ---------------- kata kunci ----------------
              GlassSearchField(
                controller: _keywordController,
                onChanged: provider.setKeyword,
                hintText: AppStrings.labelKeyword,
              ),
              const SizedBox(height: 28),

              // ---------------- genre ----------------
              _SectionLabel(label: AppStrings.labelGenre),
              const SizedBox(height: 4),
              const Text(
                AppStrings.labelGenreHint,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppStrings.availableGenres
                    .map(
                      (genre) => FilterChip(
                        label: Text(genre),
                        selected: provider.selectedGenres.contains(genre),
                        onSelected: (_) => provider.toggleGenre(genre),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),

              // ---------------- rating ----------------
              _SectionLabel(
                label:
                    '${AppStrings.labelMinRating}: ${provider.minRating.toStringAsFixed(1)}',
              ),
              Slider(
                value: provider.minRating,
                min: 0,
                max: 10,
                divisions: 20,
                label: provider.minRating.toStringAsFixed(1),
                onChanged: provider.setMinRating,
              ),
              const SizedBox(height: 20),

              // ---------------- durasi ----------------
              _SectionLabel(
                label:
                    '${AppStrings.labelRuntime}: ${provider.runtimeRange.start.round()} - ${provider.runtimeRange.end.round()} menit',
              ),
              RangeSlider(
                values: provider.runtimeRange,
                min: 0,
                max: 300,
                divisions: 30,
                labels: RangeLabels(
                  provider.runtimeRange.start.round().toString(),
                  provider.runtimeRange.end.round().toString(),
                ),
                onChanged: provider.setRuntimeRange,
              ),
              const SizedBox(height: 20),

              // ---------------- tahun ----------------
              _SectionLabel(
                label:
                    '${AppStrings.labelYear}: ${provider.yearRange.start.round()} - ${provider.yearRange.end.round()}',
              ),
              RangeSlider(
                values: provider.yearRange,
                min: 1950,
                max: 2024,
                divisions: 74,
                labels: RangeLabels(
                  provider.yearRange.start.round().toString(),
                  provider.yearRange.end.round().toString(),
                ),
                onChanged: provider.setYearRange,
              ),
              const SizedBox(height: 20),

              // ---------------- jumlah ----------------
              _SectionLabel(
                label: '${AppStrings.labelTopN}: ${provider.topN} film',
              ),
              Slider(
                value: provider.topN.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: provider.topN.toString(),
                onChanged: provider.setTopN,
              ),
              const SizedBox(height: 32),

              // ---------------- tombol ----------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(AppLayout.buttonRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      provider.search();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ResultsPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      AppStrings.actionSearch,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _keywordController.clear();
                  provider.resetFilters();
                },
                child: const Text(
                  AppStrings.actionReset,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label section kecil yang dipakai berulang di halaman input.
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
