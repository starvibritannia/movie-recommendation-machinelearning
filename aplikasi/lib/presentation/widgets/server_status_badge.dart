import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'glass_card.dart';

/// Pill kecil yang menunjukkan status koneksi ke backend FastAPI.
///
/// [isOnline] null  = masih mengecek
/// [isOnline] true  = server hidup
/// [isOnline] false = server mati, aplikasi pakai data dummy
class ServerStatusBadge extends StatelessWidget {
  final bool? isOnline;

  const ServerStatusBadge({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (isOnline) {
      null => ('Mengecek...', AppColors.textSecondary),
      true => ('Server Online', AppColors.success),
      false => ('Mode Dummy', AppColors.danger),
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
