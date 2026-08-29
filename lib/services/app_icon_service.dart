import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../database/isar_service.dart';

/// The 4 dynamic-icon states (HabitQuest_PRD.md §9), each backed by an
/// Android activity-alias in AndroidManifest.xml.
enum AppIconState { happy, neutral, sad, angry }

extension on AppIconState {
  /// Must match the keys MainActivity.kt maps to activity-alias names.
  String get wireName => switch (this) {
        AppIconState.happy => 'happy',
        AppIconState.neutral => 'neutral',
        AppIconState.sad => 'sad',
        AppIconState.angry => 'angry',
      };
}

class _DayCompletion {
  const _DayCompletion({required this.due, required this.completed});

  final int due;
  final int completed;

  bool get allCompleted => due > 0 && completed == due;
  bool get allMissed => due > 0 && completed == 0;
}

/// Picks and applies the home-screen launcher icon (HabitQuest_PRD.md §9)
/// by looking at yesterday's (and, if needed, the day before's) completion
/// history in Isar, then flipping the right Android activity-alias via a
/// platform channel to MainActivity.kt.
///
/// Every failure mode here — a bad Isar read, a platform-channel error, an
/// unexpected exception — falls back to [AppIconState.neutral] rather than
/// propagating, so a dynamic-icon bug can never crash the app or block
/// startup.
class AppIconService {
  AppIconService._();

  static final AppIconService instance = AppIconService._();

  static const MethodChannel _channel = MethodChannel('habitquest/app_icon');

  Future<void> refreshIcon([IsarService? db]) async {
    var state = AppIconState.neutral;
    try {
      state = await _determineState(db ?? IsarService.instance);
    } catch (error, stack) {
      debugPrint('[AppIconService] Falling back to neutral: $error\n$stack');
    }

    try {
      await _channel.invokeMethod<void>('setAppIcon', {'icon': state.wireName});
    } catch (error) {
      debugPrint('[AppIconService] setAppIcon failed: $error');
    }
  }

  Future<AppIconState> _determineState(IsarService db) async {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));
    final dayBeforeYesterday = yesterday.subtract(const Duration(days: 1));

    // Immediate positive feedback: if every habit due today is already
    // checked off, reflect that right away instead of waiting for tomorrow's
    // yesterday-lookback to catch up — otherwise a streak the user just
    // fixed today keeps showing yesterday's angry icon until the day after.
    final todayStatus = await _completionStatusFor(db, todayOnly);
    if (todayStatus.allCompleted) {
      final progress = await db.getUserProgress();
      return progress.currentStreak >= 2 ? AppIconState.happy : AppIconState.neutral;
    }

    final yesterdayStatus = await _completionStatusFor(db, yesterday);

    // Nothing was due yesterday at all — nothing to reward or punish.
    if (yesterdayStatus.due == 0) return AppIconState.neutral;

    if (yesterdayStatus.allCompleted) {
      final progress = await db.getUserProgress();
      return progress.currentStreak >= 2 ? AppIconState.happy : AppIconState.neutral;
    }

    if (yesterdayStatus.allMissed) {
      final dayBeforeStatus = await _completionStatusFor(db, dayBeforeYesterday);
      // 2+ consecutive fully-missed days -> angry; just yesterday -> sad.
      return dayBeforeStatus.allMissed ? AppIconState.angry : AppIconState.sad;
    }

    // Completed some, but not all, of yesterday's habits.
    return AppIconState.neutral;
  }

  Future<_DayCompletion> _completionStatusFor(IsarService db, DateTime date) async {
    final dueHabits = await db.fetchHabitsDueOn(date);
    if (dueHabits.isEmpty) return const _DayCompletion(due: 0, completed: 0);

    final logs = await db.getLogsForDate(date);
    final completedHabitIds = logs.where((log) => log.completed).map((log) => log.habitId).toSet();
    final completedCount = dueHabits.where((habit) => completedHabitIds.contains(habit.id)).length;

    return _DayCompletion(due: dueHabits.length, completed: completedCount);
  }
}
