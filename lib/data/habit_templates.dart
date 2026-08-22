import '../models/habit.dart';

/// One habit pre-filled by a quick-start template — turned into a real
/// [Habit] at creation time via [toHabit] (HabitQuest_PRD.md §4.4).
class TemplateHabit {
  const TemplateHabit({
    required this.name,
    required this.icon,
    this.trackingType = TrackingType.checkbox,
    this.targetValue,
    this.frequencyType = FrequencyType.daily,
    this.category = HabitCategory.custom,
  });

  final String name;
  final String icon;
  final TrackingType trackingType;
  final double? targetValue;
  final FrequencyType frequencyType;
  final HabitCategory category;

  Habit toHabit() => Habit()
    ..name = name
    ..icon = icon
    ..trackingType = trackingType
    ..targetValue = targetValue
    ..frequencyType = frequencyType
    ..specificDays = []
    ..reminderTimes = []
    ..category = category
    ..createdAt = DateTime.now();
}

/// A pick-one onboarding routine (HabitQuest_PRD.md §7 screen 4, §4.4).
class HabitTemplate {
  const HabitTemplate({required this.name, required this.emoji, required this.habits});

  final String name;
  final String emoji;
  final List<TemplateHabit> habits;
}

/// The 5 quick-start templates from HabitQuest_PRD.md §4.4.
const List<HabitTemplate> kHabitTemplates = [
  HabitTemplate(
    name: 'Student',
    emoji: '📚',
    habits: [
      TemplateHabit(
        name: 'Study 2 hours',
        icon: '📚',
        trackingType: TrackingType.timer,
        targetValue: 120,
        category: HabitCategory.study,
      ),
      TemplateHabit(
        name: 'Read 20 pages',
        icon: '📖',
        trackingType: TrackingType.counter,
        targetValue: 20,
        category: HabitCategory.study,
      ),
      TemplateHabit(name: 'No phone after 10pm', icon: '📵', category: HabitCategory.study),
      TemplateHabit(name: 'Check assignments', icon: '✍️', category: HabitCategory.study),
    ],
  ),
  HabitTemplate(
    name: 'Fitness / Gym',
    emoji: '🏋️',
    habits: [
      TemplateHabit(name: 'Workout', icon: '🏋️', category: HabitCategory.fitness),
      TemplateHabit(name: 'Protein intake', icon: '🍎', category: HabitCategory.fitness),
      TemplateHabit(
        name: 'Water intake',
        icon: '💧',
        trackingType: TrackingType.counter,
        targetValue: 8,
        category: HabitCategory.fitness,
      ),
      TemplateHabit(name: '8 hours sleep', icon: '😴', category: HabitCategory.fitness),
      TemplateHabit(
        name: 'Step count',
        icon: '🚶',
        trackingType: TrackingType.value,
        category: HabitCategory.fitness,
      ),
    ],
  ),
  HabitTemplate(
    name: 'Health / Medical',
    emoji: '🩺',
    habits: [
      TemplateHabit(
        name: 'Take medication',
        icon: '💊',
        frequencyType: FrequencyType.multipleTimesPerDay,
        category: HabitCategory.health,
      ),
      TemplateHabit(
        name: 'Blood pressure check',
        icon: '🩺',
        trackingType: TrackingType.value,
        category: HabitCategory.health,
      ),
      TemplateHabit(
        name: 'Sugar level log',
        icon: '🩸',
        trackingType: TrackingType.value,
        category: HabitCategory.health,
      ),
    ],
  ),
  HabitTemplate(
    name: 'Business / Professional',
    emoji: '💼',
    habits: [
      TemplateHabit(name: 'Daily planning', icon: '📈', category: HabitCategory.business),
      TemplateHabit(name: 'Client follow-ups', icon: '🤝', category: HabitCategory.business),
      TemplateHabit(name: 'No procrastination', icon: '🎯', category: HabitCategory.business),
      TemplateHabit(name: 'Networking', icon: '💰', category: HabitCategory.business),
    ],
  ),
  HabitTemplate(
    name: 'Spiritual',
    emoji: '🙏',
    habits: [
      TemplateHabit(
        name: '5 prayers',
        icon: '🙏',
        frequencyType: FrequencyType.multipleTimesPerDay,
        category: HabitCategory.spiritual,
      ),
      TemplateHabit(name: 'Quran reading', icon: '📖', category: HabitCategory.spiritual),
      TemplateHabit(
        name: 'Tasbeeh',
        icon: '📿',
        trackingType: TrackingType.counter,
        targetValue: 33,
        category: HabitCategory.spiritual,
      ),
      TemplateHabit(name: 'Charity', icon: '❤️', category: HabitCategory.spiritual),
    ],
  ),
];
