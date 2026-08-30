import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/leveling_service.dart';
import '../services/providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/habit_card.dart';
import '../widgets/level_up_celebration.dart';
import '../widgets/stats_bar.dart';
import '../widgets/streak_freeze_modal.dart';
import 'add_edit_habit_screen.dart';
import 'avatar_profile_screen.dart';
import 'day_complete_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// Main dashboard (HabitQuest_PRD.md §7 screen 5): avatar, XP/gold/streak,
/// and the "All Habits" checklist (habits due today, per [todayHabitsProvider])
/// pulled live from Isar (§3 core daily loop). Each card opens
/// [HabitDetailScreen] for that habit's full day-by-day plan.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final todayHabits = ref.watch(todayHabitsProvider);
    final levelInfo = LevelingService.levelInfoForXp(
      progress.totalXP,
      premiumUnlocked: progress.premiumAvatarUnlocked,
    );

    // Fires only on a genuine in-session level-up (see pendingCelebrationProvider),
    // never when a user's already-leveled-up progress is first loaded from Isar.
    ref.listen<AvatarStage?>(pendingCelebrationProvider, (previous, stage) {
      if (stage == null) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => LevelUpCelebration(stage: stage),
      ).then((_) => ref.read(pendingCelebrationProvider.notifier).state = null);
    });

    // Fires once every habit due today is checked off (§3, §7 screen 13).
    ref.listen<bool>(pendingDayCompleteProvider, (previous, isComplete) {
      if (!isComplete) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => const DayCompleteScreen(),
      ).then(
        (_) => ref.read(pendingDayCompleteProvider.notifier).state = false,
      );
    });

    // Fires once when a missed day puts the streak at risk (§7 screen 12).
    ref.listen<bool>(streakAtRiskProvider, (previous, atRisk) {
      if (!atRisk || previous == true) return;
      SoundService.instance.play(AppSound.habitMissed);
      showDialog<void>(
        context: context,
        builder: (_) => const StreakFreezeModal(),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('HabitQuest', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            tooltip: 'Shop',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
          IconButton(
            tooltip: 'Progress',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddEditHabitScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
      ),
      // BannerAdWidget lives in bottomNavigationBar, not body — that's the
      // Scaffold slot the FloatingActionButton's default position already
      // reserves space above, so the "Add Habit" button can never end up
      // sitting on top of the ad strip.
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdWidget()),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(todayHabitsProvider.notifier).refresh();
            await ref.read(userProgressProvider.notifier).refresh();
          },
          child: ListView(
            // Extra bottom padding (beyond the usual 24) so the last habit
            // card always scrolls clear of the floating "Add Habit" button
            // instead of ending up underneath it — the FAB floats over
            // scrollable content by default and doesn't reserve space on
            // its own.
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AvatarProfileScreen(),
                  ),
                ),
                child: AvatarDisplay(
                  level: levelInfo.level,
                  stage: levelInfo.stage,
                  ownedCosmetics: progress.ownedCosmeticIds.toSet(),
                ),
              ),
              const SizedBox(height: 24),
              StatsBar(
                levelInfo: levelInfo,
                totalGold: progress.totalGold,
                currentStreak: progress.currentStreak,
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'All Habits',
                      style: AppTypography.headingLarge,
                    ),
                  ),
                  if (todayHabits.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        '${todayHabits.length}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              if (todayHabits.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Tap a habit to see its full plan.',
                  style: AppTypography.caption,
                ),
              ],
              const SizedBox(height: 16),
              if (todayHabits.isEmpty)
                _EmptyHabitsMessage()
              else
                for (final habit in todayHabits) ...[
                  HabitCard(habit: habit),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHabitsMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No habits yet.\nTap "Add Habit" to create your first one.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ),
    );
  }
}
