import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/user_progress.dart';

/// Singleton wrapper around the app's single on-device Isar instance, plus
/// the basic CRUD operations HabitQuest's UI layers build on. See
/// HabitQuest_PRD.md §4 (habits) and §5 (gamification) for the data model.
class IsarService {
  IsarService._();

  static final IsarService instance = IsarService._();

  late final Isar db;

  IsarCollection<Habit> get _habits => db.collection<Habit>();
  IsarCollection<HabitLog> get _habitLogs => db.collection<HabitLog>();
  IsarCollection<UserProgress> get _userProgress => db.collection<UserProgress>();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [HabitSchema, HabitLogSchema, UserProgressSchema],
      directory: dir.path,
    );
  }

  // ---- Habit CRUD ----

  Future<Habit> createHabit(Habit habit) async {
    await db.writeTxn(() async {
      habit.id = await _habits.put(habit);
    });
    return habit;
  }

  Future<List<Habit>> getAllHabits() => _habits.where().findAll();

  Future<Habit?> getHabit(int id) => _habits.get(id);

  Future<void> updateHabit(Habit habit) async {
    await db.writeTxn(() async {
      await _habits.put(habit);
    });
  }

  Future<void> deleteHabit(int id) async {
    await db.writeTxn(() async {
      await _habits.delete(id);
      await _habitLogs.filter().habitIdEqualTo(id).deleteAll();
    });
  }

  /// Habits due today, based on [Habit.frequencyType] (HabitQuest_PRD.md §4.2).
  /// Frequencies that aren't tied to specific weekdays (times-per-week,
  /// multiple-times-per-day) are always included; the day-picking is left to
  /// the user's checklist interaction.
  Future<List<Habit>> fetchTodayHabits() => fetchHabitsDueOn(DateTime.now());

  /// Habits due on [date] — the same weekday-matching rule as
  /// [fetchTodayHabits], applied to an arbitrary day and restricted to
  /// habits that already existed by then. Used by AppIconService to judge
  /// past completion history (HabitQuest_PRD.md §9); frequency rules aren't
  /// tracked historically, so this approximates "due that day" using each
  /// habit's *current* frequency, which is fine over the 1-2 day lookback
  /// the icon logic actually needs.
  Future<List<Habit>> fetchHabitsDueOn(DateTime date) async {
    final all = await _habits.where().findAll();
    final weekday = date.weekday; // 1 = Monday ... 7 = Sunday
    final dayOnly = _dateOnly(date);
    return all.where((habit) {
      if (_dateOnly(habit.createdAt).isAfter(dayOnly)) return false;
      if (habit.frequencyType == FrequencyType.specificDays) {
        return habit.specificDays.contains(weekday);
      }
      return true;
    }).toList();
  }

  // ---- HabitLog CRUD ----

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Creates or overwrites today's log entry for [habitId].
  Future<HabitLog> logCompletion(
    int habitId, {
    required bool completed,
    double? valueLogged,
  }) async {
    final today = _dateOnly(DateTime.now());
    late HabitLog log;
    await db.writeTxn(() async {
      final existing = await _habitLogs
          .filter()
          .habitIdEqualTo(habitId)
          .dateEqualTo(today)
          .findFirst();

      log = existing ?? HabitLog();
      log
        ..habitId = habitId
        ..date = today
        ..completed = completed
        ..valueLogged = valueLogged
        ..timestamp = DateTime.now();

      log.id = await _habitLogs.put(log);
    });
    return log;
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) =>
      _habitLogs.filter().habitIdEqualTo(habitId).findAll();

  /// Today's log for [habitId], or null if it hasn't been touched today.
  Future<HabitLog?> getTodayLogForHabit(int habitId) {
    final today = _dateOnly(DateTime.now());
    return _habitLogs
        .filter()
        .habitIdEqualTo(habitId)
        .dateEqualTo(today)
        .findFirst();
  }

  /// Count of habits already completed today, across all habits. Used to
  /// decide whether a new completion is the day's first (see
  /// HomeScreen._completeHabit, which bumps the streak only on that first one).
  Future<int> countTodayCompletedLogs() {
    final today = _dateOnly(DateTime.now());
    return _habitLogs.filter().dateEqualTo(today).completedEqualTo(true).count();
  }

  /// All logs dated on/after [since] (inclusive, truncated to midnight) —
  /// used by the Progress Screen's streak path and weekly/monthly stats
  /// (HabitQuest_PRD.md §6.6, §7 screen 10).
  Future<List<HabitLog>> getLogsSince(DateTime since) {
    return _habitLogs.filter().dateGreaterThan(_dateOnly(since), include: true).findAll();
  }

  /// All logs dated exactly [date] — used by AppIconService (§9) to judge a
  /// single past day's completion.
  Future<List<HabitLog>> getLogsForDate(DateTime date) {
    return _habitLogs.filter().dateEqualTo(_dateOnly(date)).findAll();
  }

  /// True once every id in [habitIds] has a completed log for today — the
  /// "Day Complete" trigger (HabitQuest_PRD.md §3, §7 screen 13). False for
  /// an empty list (nothing to celebrate).
  Future<bool> isDayComplete(List<int> habitIds) async {
    if (habitIds.isEmpty) return false;
    for (final id in habitIds) {
      final log = await getTodayLogForHabit(id);
      if (log?.completed != true) return false;
    }
    return true;
  }

  // ---- UserProgress ----

  /// Fetches the single UserProgress row, creating it with defaults on first use.
  Future<UserProgress> getUserProgress() async {
    final existing = await _userProgress.get(0);
    if (existing != null) return existing;

    final fresh = UserProgress();
    await db.writeTxn(() async {
      await _userProgress.put(fresh);
    });
    return fresh;
  }

  /// Applies the rewards from a completed habit in one write: XP and gold
  /// are added (XP is cumulative and never decreases, per
  /// HabitQuest_PRD.md §5.1), HP moves by [hpDelta] (clamped to 0..100 —
  /// completing habits heals the mood meter that missed habits drain), and
  /// the streak is set to [newStreak] if provided.
  Future<UserProgress> applyHabitCompletionRewards({
    int xpGained = 0,
    int goldGained = 0,
    int hpDelta = 0,
    int? newStreak,
  }) async {
    final progress = await getUserProgress();
    progress.totalXP += xpGained;
    progress.totalGold += goldGained;
    progress.currentHP = (progress.currentHP + hpDelta).clamp(0, 100);
    if (newStreak != null) {
      progress.currentStreak = newStreak;
      if (newStreak > progress.longestStreak) {
        progress.longestStreak = newStreak;
      }
    }
    await db.writeTxn(() async {
      await _userProgress.put(progress);
    });
    return progress;
  }

  /// Deducts [amount] gold for a Shop purchase (HabitQuest_PRD.md §7 screen
  /// 11). Returns false without writing anything if the balance is too low.
  Future<bool> spendGold(int amount) async {
    final progress = await getUserProgress();
    if (progress.totalGold < amount) return false;
    progress.totalGold -= amount;
    await db.writeTxn(() async {
      await _userProgress.put(progress);
    });
    return true;
  }

  /// Unlocks the Golden Phoenix avatar stage after a successful Rewarded Ad
  /// (HabitQuest_PRD.md §5.3, §10).
  Future<UserProgress> unlockPremiumAvatar() async {
    final progress = await getUserProgress();
    progress.premiumAvatarUnlocked = true;
    await db.writeTxn(() async {
      await _userProgress.put(progress);
    });
    return progress;
  }

  /// Resets the current streak to 0 — the consequence of declining a Streak
  /// Freeze after a missed day (HabitQuest_PRD.md §7 screen 12).
  /// [longestStreak] is a historical record and is left untouched.
  Future<UserProgress> resetStreak() async {
    final progress = await getUserProgress();
    progress.currentStreak = 0;
    await db.writeTxn(() async {
      await _userProgress.put(progress);
    });
    return progress;
  }

  /// "Reset all data" (HabitQuest_PRD.md §7 screen 14) — wipes every habit,
  /// every log, and progress back to defaults. Irreversible; callers own
  /// confirming with the user first.
  Future<void> resetAllData() async {
    await db.writeTxn(() async {
      await _habits.clear();
      await _habitLogs.clear();
      await _userProgress.clear();
    });
  }
}
