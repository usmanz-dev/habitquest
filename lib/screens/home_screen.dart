import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/leveling_service.dart';
import '../services/providers.dart';
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
import 'theme_demo_screen.dart';

/// Main dashboard (HabitQuest_PRD.md §7 screen 5): avatar, XP/gold/streak,
/// and today's habit checklist pulled live from Isar (§3 core daily loop).
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
      ).then((_) => ref.read(pendingDayCompleteProvider.notifier).state = false);
    });

    // Fires once when a missed day puts the streak at risk (§7 screen 12).
    ref.listen<bool>(streakAtRiskProvider, (previous, atRisk) {
      if (!atRisk || previous == true) return;
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Progress',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Design system (dev)',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemeDemoScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(todayHabitsProvider.notifier).refresh();
                  await ref.read(userProgressProvider.notifier).refresh();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AvatarProfileScreen()),
                      ),
                      child: AvatarDisplay(level: levelInfo.level, stage: levelInfo.stage),
                    ),
                    const SizedBox(height: 24),
                    StatsBar(
                      levelInfo: levelInfo,
                      totalGold: progress.totalGold,
                      currentStreak: progress.currentStreak,
                    ),
                    const SizedBox(height: 28),
                    Text("Today's Habits", style: AppTypography.headingLarge),
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
            const BannerAdWidget(),
          ],
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
