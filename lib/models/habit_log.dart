import 'package:isar/isar.dart';

part 'habit_log.g.dart';

/// One day's completion record for a [Habit].
@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  /// Composite-indexed with [date] so "today's log for this habit" is a
  /// single indexed lookup — see IsarService.logCompletion.
  @Index(composite: [CompositeIndex('date')])
  late int habitId;

  /// The calendar day this log belongs to, truncated to midnight.
  late DateTime date;

  late bool completed;

  /// Logged amount for counter/timer/value tracking types.
  double? valueLogged;

  late DateTime timestamp;
}
