import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

/// Streak Freeze modal (HabitQuest_PRD.md §7 screen 12) — offered when a
/// day was missed while the user had an active streak. Watching the ad
/// keeps the streak as-is; declining resets it, so the choice is real.
class StreakFreezeModal extends ConsumerStatefulWidget {
  const StreakFreezeModal({super.key});

  @override
  ConsumerState<StreakFreezeModal> createState() => _StreakFreezeModalState();
}

class _StreakFreezeModalState extends ConsumerState<StreakFreezeModal> {
  bool _working = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  Future<void> _watchAd() async {
    setState(() => _working = true);
    final earned = await AdService.instance.showRewardedAdForStreakFreeze();
    if (!mounted) return;

    if (earned) {
      HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ad didn't complete — streak wasn't frozen.")),
    );
  }

  Future<void> _letItReset() async {
    HapticFeedback.heavyImpact();
    await ref.read(userProgressProvider.notifier).resetStreak();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(userProgressProvider).currentStreak;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.danger,
                boxShadow: [
                  BoxShadow(color: AppColors.dangerStart.withValues(alpha: 0.4), blurRadius: 24),
                ],
              ),
              child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Streak at Risk!', style: AppTypography.headingLarge),
            const SizedBox(height: 8),
            Text(
              'You missed yesterday. Watch a quick ad to freeze your $streak-day streak, '
              'or let it reset.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _working ? null : _watchAd,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(_working ? 'Loading ad…' : 'Watch Ad to Freeze Streak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _working ? null : _letItReset,
              child: Text('Let it reset', style: AppTypography.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
