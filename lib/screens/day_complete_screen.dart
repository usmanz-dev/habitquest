import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

/// Day Complete celebration (HabitQuest_PRD.md §3, §7 screen 13) — shown
/// once every habit due today is checked off. Fires the interstitial ad
/// (§10: only at this exact moment, never mid-task) as soon as it opens.
class DayCompleteScreen extends ConsumerStatefulWidget {
  const DayCompleteScreen({super.key});

  @override
  ConsumerState<DayCompleteScreen> createState() => _DayCompleteScreenState();
}

class _DayCompleteScreenState extends ConsumerState<DayCompleteScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    AdService.instance.showInterstitialOnDayComplete();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(userProgressProvider);

    return Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130,
                height: 130,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.successStart.withValues(alpha: 0.5), blurRadius: 44),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 64),
              ).animate().scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 28),
              Text('Day Complete!', style: AppTypography.displayLarge, textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Every habit checked off today. Nicely done.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatPill(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.dangerEnd,
                    label: '${progress.currentStreak} day streak',
                  ),
                  const SizedBox(width: 12),
                  _StatPill(
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.amberStart,
                    label: '${progress.totalGold} gold',
                  ),
                ],
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleStart,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
