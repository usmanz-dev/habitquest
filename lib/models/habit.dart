import 'package:isar/isar.dart';

part 'habit.g.dart';

/// How a habit's completion is tracked. See HabitQuest_PRD.md §4.1.
enum TrackingType { checkbox, counter, timer, value }

/// How often a habit is due. See HabitQuest_PRD.md §4.2.
enum FrequencyType { daily, specificDays, timesPerWeek, multipleTimesPerDay }

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

  /// Reminder times of day, stored as "HH:mm" strings.
  List<String> reminderTimes = [];

  late String icon;

  /// Defaults to [HabitCategory.custom] when the user skips this optional field.
  @enumerated
  HabitCategory category = HabitCategory.custom;

  late DateTime createdAt;
}
