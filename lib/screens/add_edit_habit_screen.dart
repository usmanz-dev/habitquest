import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

const List<String> _kEmojiOptions = [
  '⭐', '✅', '💧', '📚', '🏋️', '🧘', '🙏', '💊', '🩺', '🩸',
  '😴', '🍎', '💰', '📈', '🤝', '✍️', '🎯', '🧹', '🚶', '🏃',
  '🚴', '🎵', '🎨', '💻', '🧠', '❤️', '🌿', '☀️', '🔥', '📖',
];

const List<String> _kWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Custom habit builder (HabitQuest_PRD.md §4.3) — creates a new habit, or
/// edits [existingHabit] in place, writing to the Isar Habit collection.
class AddEditHabitScreen extends ConsumerStatefulWidget {
  const AddEditHabitScreen({super.key, this.existingHabit});

  final Habit? existingHabit;

  bool get isEditing => existingHabit != null;

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetValueController;

  late final TextEditingController _durationCountController;

  late TrackingType _trackingType;
  late FrequencyType _frequencyType;
  late HabitCategory _category;
  late String _icon;
  late Set<int> _specificDays;
  late List<String> _reminderTimes;
  late DurationUnit _durationUnit;

  bool _saving = false;
  String? _daysError;

  @override
  void initState() {
    super.initState();
    final h = widget.existingHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _trackingType = h?.trackingType ?? TrackingType.checkbox;
    _frequencyType = h?.frequencyType ?? FrequencyType.daily;
    _category = h?.category ?? HabitCategory.custom;
    _icon = h?.icon ?? _kEmojiOptions.first;
    _specificDays = (h?.specificDays ?? const <int>[]).toSet();
    _reminderTimes = List.of(h?.reminderTimes ?? const <String>[]);
    _durationUnit = h?.durationUnit ?? DurationUnit.days;
    _durationCountController = TextEditingController(
      text: h?.durationCount != null ? '${h!.durationCount}' : '',
    );
    _targetValueController = TextEditingController(
      text: h?.targetValue != null ? _formatNumber(h!.targetValue!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetValueController.dispose();
    _durationCountController.dispose();
    super.dispose();
  }

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  bool get _needsTrackingTarget =>
      _trackingType == TrackingType.counter || _trackingType == TrackingType.timer;

  bool get _needsWeeklyCount =>
      _frequencyType == FrequencyType.timesPerWeek && !_needsTrackingTarget;

  bool get _showTargetField => _needsTrackingTarget || _needsWeeklyCount;

  String get _targetFieldLabel => switch (_trackingType) {
        TrackingType.counter when _needsTrackingTarget => 'Target count (e.g. 8 glasses)',
        TrackingType.timer when _needsTrackingTarget => 'Duration (minutes)',
        _ => 'Times per week',
      };

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_reminderTimes.contains(formatted)) return;
    setState(() {
      _reminderTimes.add(formatted);
      _reminderTimes.sort();
    });
  }

  bool get _isDuration => _frequencyType == FrequencyType.duration;

  Future<void> _save() async {
    setState(() => _daysError = null);
    final formValid = _formKey.currentState?.validate() ?? false;
    final daysValid = !(_frequencyType == FrequencyType.specificDays && _specificDays.isEmpty);
    if (!daysValid) setState(() => _daysError = 'Pick at least one day');
    if (!formValid || !daysValid) return;

    setState(() => _saving = true);

    final db = ref.read(isarServiceProvider);
    final habit = widget.existingHabit ?? Habit();
    habit
      ..name = _nameController.text.trim()
      ..trackingType = _trackingType
      ..targetValue = _showTargetField ? double.tryParse(_targetValueController.text) : null
      ..frequencyType = _frequencyType
      ..specificDays = (_specificDays.toList()..sort())
      ..durationCount = _isDuration ? int.tryParse(_durationCountController.text) : null
      ..durationUnit = _durationUnit
      ..reminderTimes = _reminderTimes
      ..icon = _icon
      ..category = _category
      ..createdAt = widget.existingHabit?.createdAt ?? DateTime.now();

    if (widget.isEditing) {
      await db.updateHabit(habit);
    } else {
      await db.createHabit(habit);
    }
    if (SettingsService.instance.notificationsEnabled) {
      await NotificationService.instance.scheduleRemindersForHabit(habit);
    }
    await ref.read(todayHabitsProvider.notifier).refresh();

    HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final habit = widget.existingHabit;
    if (habit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${habit.name}"?', style: AppTypography.headingMedium),
        content: Text(
          'This removes the habit and its reminders. Past progress stays in your stats.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.dangerEnd)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    await ref.read(isarServiceProvider).deleteHabit(habit.id);
    await NotificationService.instance.cancelAllForHabit(habit.id);
    await ref.read(todayHabitsProvider.notifier).refresh();

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.isEditing ? 'Edit Habit' : 'Add Habit',
          style: AppTypography.headingMedium,
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete habit',
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.dangerEnd),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving…' : 'Save',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.purpleEnd,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SectionLabel('Habit name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyLarge,
                decoration: _fieldDecoration('e.g. Study for 30 minutes'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a habit name' : null,
              ),
              const SizedBox(height: 24),
              _SectionLabel('Tracking type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OptionChip(
                    label: 'Checkbox',
                    icon: Icons.check_box_outlined,
                    selected: _trackingType == TrackingType.checkbox,
                    onTap: () => setState(() => _trackingType = TrackingType.checkbox),
                  ),
                  _OptionChip(
                    label: 'Counter',
                    icon: Icons.exposure_plus_1_rounded,
                    selected: _trackingType == TrackingType.counter,
                    onTap: () => setState(() => _trackingType = TrackingType.counter),
                  ),
                  _OptionChip(
                    label: 'Timer',
                    icon: Icons.timer_outlined,
                    selected: _trackingType == TrackingType.timer,
                    onTap: () => setState(() => _trackingType = TrackingType.timer),
                  ),
                  _OptionChip(
                    label: 'Value',
                    icon: Icons.numbers_rounded,
                    selected: _trackingType == TrackingType.value,
                    onTap: () => setState(() => _trackingType = TrackingType.value),
                  ),
                ],
              ),
              if (_showTargetField) ...[
                const SizedBox(height: 20),
                TextFormField(
                  key: ValueKey(_targetFieldLabel),
                  controller: _targetValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodyLarge,
                  decoration: _fieldDecoration(_targetFieldLabel),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Enter a valid number';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              _SectionLabel('Frequency'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OptionChip(
                    label: 'Daily',
                    selected: _frequencyType == FrequencyType.daily,
                    onTap: () => setState(() => _frequencyType = FrequencyType.daily),
                  ),
                  _OptionChip(
                    label: 'Specific Days',
                    selected: _frequencyType == FrequencyType.specificDays,
                    onTap: () => setState(() => _frequencyType = FrequencyType.specificDays),
                  ),
                  _OptionChip(
                    label: 'X / Week',
                    selected: _frequencyType == FrequencyType.timesPerWeek,
                    onTap: () => setState(() => _frequencyType = FrequencyType.timesPerWeek),
                  ),
                  _OptionChip(
                    label: 'Multiple / Day',
                    selected: _frequencyType == FrequencyType.multipleTimesPerDay,
                    onTap: () =>
                        setState(() => _frequencyType = FrequencyType.multipleTimesPerDay),
                  ),
                  _OptionChip(
                    label: 'Duration',
                    icon: Icons.event_repeat_rounded,
                    selected: _isDuration,
                    onTap: () => setState(() => _frequencyType = FrequencyType.duration),
                  ),
                ],
              ),
              if (_isDuration) ...[
                const SizedBox(height: 16),
                Text(
                  'A fixed-length challenge, e.g. "30 days" — shows a full '
                  'day-by-day checklist when you tap into it from Home.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _durationCountController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyLarge,
                        decoration: _fieldDecoration('e.g. 30'),
                        validator: (v) {
                          if (!_isDuration) return null;
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final unit in DurationUnit.values)
                            _OptionChip(
                              label: _durationUnitLabel(unit),
                              selected: _durationUnit == unit,
                              onTap: () => setState(() => _durationUnit = unit),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (_frequencyType == FrequencyType.specificDays) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final weekday = i + 1; // DateTime.weekday: 1=Mon..7=Sun
                    final selected = _specificDays.contains(weekday);
                    return _OptionChip(
                      label: _kWeekdayLabels[i],
                      selected: selected,
                      onTap: () => setState(() {
                        selected ? _specificDays.remove(weekday) : _specificDays.add(weekday);
                      }),
                    );
                  }),
                ),
                if (_daysError != null) ...[
                  const SizedBox(height: 6),
                  Text(_daysError!, style: AppTypography.caption.copyWith(color: AppColors.dangerEnd)),
                ],
              ],
              const SizedBox(height: 24),
              _SectionLabel('Reminders (optional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in _reminderTimes)
                    Chip(
                      label: Text(time, style: AppTypography.bodyMedium),
                      backgroundColor: AppColors.surface,
                      deleteIconColor: AppColors.textSecondary,
                      onDeleted: () => setState(() => _reminderTimes.remove(time)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18, color: AppColors.purpleEnd),
                    label: Text('Add time', style: AppTypography.bodyMedium),
                    backgroundColor: AppColors.surface,
                    onPressed: _pickReminderTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel('Icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _kEmojiOptions)
                    GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _icon == emoji ? AppGradients.primary : null,
                          color: _icon == emoji ? null : AppColors.surface,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel('Category (optional)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<HabitCategory>(
                initialValue: _category,
                dropdownColor: AppColors.surface,
                style: AppTypography.bodyLarge,
                decoration: _fieldDecoration('Category'),
                items: [
                  for (final c in HabitCategory.values)
                    DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationUnitLabel(DurationUnit u) => switch (u) {
        DurationUnit.days => 'Days',
        DurationUnit.weeks => 'Weeks',
        DurationUnit.months => 'Months',
      };

  String _categoryLabel(HabitCategory c) => switch (c) {
        HabitCategory.health => 'Health',
        HabitCategory.fitness => 'Fitness',
        HabitCategory.study => 'Study',
        HabitCategory.business => 'Business',
        HabitCategory.spiritual => 'Spiritual',
        HabitCategory.personal => 'Personal',
        HabitCategory.custom => 'Custom',
      };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTypography.caption);
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: selected
                  ? AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)
                  : AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
