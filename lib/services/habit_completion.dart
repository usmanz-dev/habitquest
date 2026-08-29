import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../utils/rewards.dart';
import 'app_icon_service.dart';
import 'notification_service.dart';
import 'providers.dart';
import 'sound_service.dart';

/// Writes today's log for [habit] and, when it completes the habit, applies
/// XP/gold/HP/streak rewards, refreshes the dynamic launcher icon, and checks
/// for a full "Day Complete". Shared by every completion entry point — the
/// Home Screen's [HabitCard] controls and the Habit Detail Screen's date grid
/// — so rewards and the launcher-icon state never drift between them.
Future<void> logHabitCompletion(
  WidgetRef ref,
  Habit habit, {
  required bool completed,
  double? valueLogged,
}) async {
  final db = ref.read(isarServiceProvider);

  final wasFirstCompletionToday = completed && await db.countTodayCompletedLogs() == 0;

  await db.logCompletion(habit.id, completed: completed, valueLogged: valueLogged);
  ref.invalidate(todayLogProvider(habit.id));
  ref.invalidate(habitLogsProvider(habit.id));
  // Fire-and-forget: the icon logic never throws and a one-frame delay in
  // reflecting the launcher icon isn't worth blocking on.
  unawaited(AppIconService.instance.refreshIcon());

  if (!completed) return;

  await NotificationService.instance.cancelLastChance(habit.id);

  final currentStreak = ref.read(userProgressProvider).currentStreak;
  await ref.read(userProgressProvider.notifier).applyHabitCompletion(
        xpGained: kXpPerCompletion,
        goldGained: kGoldPerCompletion,
        hpDelta: kHpRegenPerCompletion,
        newStreak: wasFirstCompletionToday ? currentStreak + 1 : null,
      );

  HapticFeedback.lightImpact();
  SoundService.instance.play(AppSound.habitCheck);

  final todayHabits = ref.read(todayHabitsProvider);
  if (todayHabits.isNotEmpty &&
      await db.isDayComplete(todayHabits.map((h) => h.id).toList())) {
    ref.read(pendingDayCompleteProvider.notifier).state = true;
  }
}
