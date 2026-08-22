import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/isar_service.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/user_progress.dart';
import 'leveling_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) => IsarService.instance);

/// Set (only) by [UserProgressNotifier.applyHabitCompletion] when a habit
/// completion pushes the user's avatar into a new stage. The Home Screen
/// listens to this — not to [userProgressProvider] directly — so the
/// full-screen celebration only fires on a real, in-session level-up, never
/// on the initial load of an already-leveled-up user's saved progress.
final pendingCelebrationProvider = StateProvider<AvatarStage?>((ref) => null);

/// The single UserProgress row (XP, gold, HP, streak, avatar level).
class UserProgressNotifier extends StateNotifier<UserProgress> {
  UserProgressNotifier(this._db, this._ref) : super(UserProgress()) {
    refresh();
  }

  final IsarService _db;
  final Ref _ref;

  Future<void> refresh() async {
    state = await _db.getUserProgress();
  }

  Future<void> applyHabitCompletion({
    int xpGained = 0,
    int goldGained = 0,
    int hpDelta = 0,
    int? newStreak,
  }) async {
    final previousStage = LevelingService.stageForLevel(LevelingService.levelForXp(state.totalXP));

    state = await _db.applyHabitCompletionRewards(
      xpGained: xpGained,
      goldGained: goldGained,
      hpDelta: hpDelta,
      newStreak: newStreak,
    );

    final newStage = LevelingService.stageForLevel(LevelingService.levelForXp(state.totalXP));
    if (newStage.index > previousStage.index) {
      _ref.read(pendingCelebrationProvider.notifier).state = newStage;
    }
  }

  /// Shop purchase (HabitQuest_PRD.md §7 screen 11). Returns false, leaving
  /// state untouched, if the balance is too low.
  Future<bool> spendGold(int amount) async {
    final success = await _db.spendGold(amount);
    if (success) state = await _db.getUserProgress();
    return success;
  }

  Future<void> unlockPremiumAvatar() async {
    state = await _db.unlockPremiumAvatar();
  }

  /// Shop cosmetic purchase (HabitQuest_PRD.md §7 screen 11). Returns false,
  /// leaving state untouched, if unaffordable or already owned.
  Future<bool> purchaseCosmetic(String cosmeticId, int cost) async {
    final success = await _db.purchaseCosmetic(cosmeticId, cost);
    if (success) state = await _db.getUserProgress();
    return success;
  }

  Future<void> resetStreak() async {
    state = await _db.resetStreak();
  }
}

final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>(
  (ref) => UserProgressNotifier(ref.watch(isarServiceProvider), ref),
);

/// Today's habit checklist (HabitQuest_PRD.md §4.2 frequency rules).
class TodayHabitsNotifier extends StateNotifier<List<Habit>> {
  TodayHabitsNotifier(this._db) : super(const []) {
    refresh();
  }

  final IsarService _db;

  /// Refetches today's habits and, for each, schedules or cancels today's
  /// "last chance" reminder based on whether it's already completed
  /// (HabitQuest_PRD.md §8) — see NotificationService's doc comment for why
  /// that check has to happen here rather than at notification-fire time.
  Future<void> refresh() async {
    final habits = await _db.fetchTodayHabits();
    state = habits;

    if (!SettingsService.instance.notificationsEnabled) return;
    for (final habit in habits) {
      final log = await _db.getTodayLogForHabit(habit.id);
      await NotificationService.instance
          .scheduleOrCancelLastChance(habit, completedToday: log?.completed == true);
    }
  }
}

final todayHabitsProvider = StateNotifierProvider<TodayHabitsNotifier, List<Habit>>(
  (ref) => TodayHabitsNotifier(ref.watch(isarServiceProvider)),
);

/// Today's log for a single habit, if it's been touched today yet.
final todayLogProvider = FutureProvider.family<HabitLog?, int>((ref, habitId) {
  return ref.watch(isarServiceProvider).getTodayLogForHabit(habitId);
});

/// Days of history the Progress Screen fetches — covers both the streak
/// path (last 14 days) and the monthly stat (last 30 days).
const int kStatsFetchDays = 30;

/// Logs from the last [kStatsFetchDays] days, for the Progress Screen's
/// streak path and weekly/monthly stats (HabitQuest_PRD.md §6.6, §7 screen 10).
final recentLogsProvider = FutureProvider<List<HabitLog>>((ref) {
  final since = DateTime.now().subtract(const Duration(days: kStatsFetchDays - 1));
  return ref.watch(isarServiceProvider).getLogsSince(since);
});

/// Set (only) by [HabitCard] when a completion leaves every one of today's
/// habits complete — the Home Screen listens to this to show the Day
/// Complete screen (HabitQuest_PRD.md §3, §7 screen 13), then resets it.
final pendingDayCompleteProvider = StateProvider<bool>((ref) => false);

bool _wasYesterdayMissed(int currentStreak, List<HabitLog> recentLogs) {
  if (currentStreak <= 0) return false;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final key = DateTime(yesterday.year, yesterday.month, yesterday.day);
  return !recentLogs.any(
    (log) => log.completed && DateTime(log.date.year, log.date.month, log.date.day) == key,
  );
}

/// True once, when the user has an active streak but skipped yesterday
/// entirely — the Streak Freeze trigger (HabitQuest_PRD.md §7 screen 12).
/// There's no background day-rollover job (this app is fully local — see
/// §8's notification doc comment for the same constraint), so this is
/// re-derived from existing log history on each Home Screen load rather
/// than from a separate "was today's freeze already offered" flag.
final streakAtRiskProvider = Provider<bool>((ref) {
  final progress = ref.watch(userProgressProvider);
  final logsAsync = ref.watch(recentLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => _wasYesterdayMissed(progress.currentStreak, logs),
    orElse: () => false,
  );
});

class SettingsState {
  const SettingsState({required this.notificationsEnabled, required this.soundEnabled});

  final bool notificationsEnabled;
  final bool soundEnabled;

  SettingsState copyWith({bool? notificationsEnabled, bool? soundEnabled}) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

/// App preferences (HabitQuest_PRD.md §7 screen 14). Turning notifications
/// off cancels everything already scheduled; turning them back on
/// reschedules reminders for every habit (last-chance notifications pick
/// themselves back up on the next [TodayHabitsNotifier.refresh]).
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._settings, this._db)
      : super(
          SettingsState(
            notificationsEnabled: _settings.notificationsEnabled,
            soundEnabled: _settings.soundEnabled,
          ),
        );

  final SettingsService _settings;
  final IsarService _db;

  Future<void> setNotificationsEnabled(bool value) async {
    await _settings.setNotificationsEnabled(value);
    state = state.copyWith(notificationsEnabled: value);

    if (value) {
      for (final habit in await _db.getAllHabits()) {
        await NotificationService.instance.scheduleRemindersForHabit(habit);
      }
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    await _settings.setSoundEnabled(value);
    state = state.copyWith(soundEnabled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(SettingsService.instance, ref.watch(isarServiceProvider)),
);
