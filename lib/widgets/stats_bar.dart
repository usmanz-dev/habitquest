import 'package:flutter/material.dart';

import '../services/leveling_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// XP progress bar, gold counter, and streak counter for the Home Screen
/// (HabitQuest_PRD.md §5.1). Styled with the gold gradient per spec.
class StatsBar extends StatelessWidget {
  const StatsBar({
    super.key,
    required this.levelInfo,
    required this.totalGold,
    required this.currentStreak,
  });

  final LevelInfo levelInfo;
  final int totalGold;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP', style: AppTypography.bodyMedium),
              Text(
                '${levelInfo.xpIntoLevel} / ${levelInfo.xpForNextLevel} XP',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: levelInfo.progress.clamp(0.02, 1.0),
                    child: Container(
                      decoration: AppGradients.progressBarDecoration(AppGradients.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.monetization_on_rounded,
                  iconColor: AppColors.amberStart,
                  label: 'Gold',
                  value: '$totalGold',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.dangerEnd,
                  label: 'Streak',
                  value: '$currentStreak',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.headingMedium),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ],
    );
  }
}
