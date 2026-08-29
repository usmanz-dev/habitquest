import 'package:isar/isar.dart';

part 'habit.g.dart';

/// How a habit's completion is tracked. See HabitQuest_PRD.md §4.1.
enum TrackingType { checkbox, counter, timer, value }

/// How often a habit is due. See HabitQuest_PRD.md §4.2.
/// [duration] is a fixed-length challenge (e.g. "30 days") rather than an
/// open-ended recurring pattern — see [Habit.durationCount]/[durationUnit].
enum FrequencyType { daily, specificDays, timesPerWeek, multipleTimesPerDay, duration }

/// Unit for [Habit.durationCount] when [Habit.frequencyType] is [FrequencyType.duration].
enum DurationUnit { days, weeks, months }

/// Optional category tag. See HabitQuest_PRD.md §4.3.
enum HabitCategory { health, fitness, study, business, spiritual, personal, custom }

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String name;

  @enumerated
  late TrackingType trackingType;

  /// Target for counter/timer types. Also doubles as the count for
  /// [FrequencyType.timesPerWeek] (e.g. 3 = "3 times per week").
  double? targetValue;

  @enumerated
  late FrequencyType frequencyType;

  /// Weekdays this habit is due, using [DateTime.weekday] values (1=Mon..7=Sun).
  /// Only meaningful when [frequencyType] is [FrequencyType.specificDays].
  List<int> specificDays = [];

  /// How many [durationUnit]s the challenge runs for (e.g. 30 + days).
  /// Only meaningful when [frequencyType] is [FrequencyType.duration] — this
  /// is the field to check for "is this a duration habit", since Isar's
  /// @enumerated fields can't be nullable ([durationUnit] always has a value).
  int? durationCount;

  /// Defaults to [DurationUnit.days] when unused, same reason [Habit.category]
  /// defaults rather than going nullable.
  @enumerated
  DurationUnit durationUnit = DurationUnit.days;

  /// Reminder times of day, stored as "HH:mm" strings.
  List<String> reminderTimes = [];

  late String icon;

  /// Defaults to [HabitCategory.custom] when the user skips this optional field.
  @enumerated
  HabitCategory category = HabitCategory.custom;

  late DateTime createdAt;
}

extension HabitDuration on Habit {
  /// The last day (inclusive) of a [FrequencyType.duration] challenge, or
  /// null for any other frequency type or if the count/unit weren't set.
  DateTime? get durationEndDate {
    final count = durationCount;
    if (frequencyType != FrequencyType.duration || count == null) {
      return null;
    }
    final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return switch (durationUnit) {
      DurationUnit.days => start.add(Duration(days: count - 1)),
      DurationUnit.weeks => start.add(Duration(days: count * 7 - 1)),
      DurationUnit.months => DateTime(start.year, start.month + count, start.day)
          .subtract(const Duration(days: 1)),
    };
  }

  /// Every calendar day in this challenge, start to end inclusive. Empty for
  /// any habit that isn't [FrequencyType.duration].
  List<DateTime> get durationDates {
    final end = durationEndDate;
    if (end == null) return const [];
    final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final totalDays = end.difference(start).inDays + 1;
    return [for (var i = 0; i < totalDays; i++) start.add(Duration(days: i))];
  }

  /// How many days back a non-[FrequencyType.duration] habit's
  /// [scheduleDates] window looks, so the Habit Detail Screen's date grid
  /// stays a fixed size instead of growing forever for an old habit.
  static const int _kRollingWindowLookbackDays = 29;

  /// How many days ahead [scheduleDates] previews for a recurring habit —
  /// enough to see "what's coming" without rendering an unbounded future.
  static const int _kRollingWindowLookaheadDays = 6;

  /// The days the Habit Detail Screen's grid should show for *any* habit,
  /// not just [FrequencyType.duration] ones: the fixed challenge range for a
  /// duration habit, or a rolling ~30-day-back/~1-week-ahead window (clipped
  /// to not start before [createdAt]) for a recurring one, filtered down to
  /// just the due weekdays for [FrequencyType.specificDays].
  List<DateTime> get scheduleDates {
    if (frequencyType == FrequencyType.duration) return durationDates;

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final createdOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final earliestWindowStart =
        todayOnly.subtract(const Duration(days: _kRollingWindowLookbackDays));
    final start = createdOnly.isAfter(earliestWindowStart) ? createdOnly : earliestWindowStart;
    final end = todayOnly.add(const Duration(days: _kRollingWindowLookaheadDays));

    final totalDays = end.difference(start).inDays + 1;
    final allDays = [for (var i = 0; i < totalDays; i++) start.add(Duration(days: i))];

    if (frequencyType == FrequencyType.specificDays && specificDays.isNotEmpty) {
      return allDays.where((d) => specificDays.contains(d.weekday)).toList();
    }
    return allDays;
  }
}
