import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/habit_card.dart';

const List<String> _kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _kMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Habit Detail Screen (HabitQuest_PRD.md §7 screen 6) for a
/// [FrequencyType.duration] habit — the full day-by-day list of its
/// challenge, from start date to end date. Today's row embeds the real
/// [HabitCard] so checking it off here behaves identically to Home Screen
/// (same rewards, sound, confetti); every other day is a read-only record
/// of what happened (or, for the future, what's coming).
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final Habit habit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late final Future<List<HabitLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = ref.read(isarServiceProvider).getLogsForHabit(widget.habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final dates = habit.durationDates;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(habit.name, style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: FutureBuilder<List<HabitLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final completedDates = {
              for (final log in snapshot.data!)
                if (log.completed) DateTime(log.date.year, log.date.month, log.date.day),
            };
            final daysSoFar = dates.where((d) => !d.isAfter(todayKey)).length;
            final doneSoFar = dates.where((d) => !d.isAfter(todayKey) && completedDates.contains(d)).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Text(habit.icon, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${dates.length}-day challenge', style: AppTypography.headingMedium),
                                Text(
                                  '${_formatDate(dates.first)} → ${_formatDate(dates.last)}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withValues(alpha: 0.08)),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: daysSoFar == 0 ? 0 : (doneSoFar / daysSoFar).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: AppGradients.progressBarDecoration(AppGradients.success),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$doneSoFar / $daysSoFar days done so far', style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (final date in dates) ...[
                  _buildRow(habit, date, todayKey, completedDates),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(Habit habit, DateTime date, DateTime todayKey, Set<DateTime> completedDates) {
    if (date == todayKey) {
      return HabitCard(habit: habit, enableDetailTap: false);
    }

    final isPast = date.isBefore(todayKey);
    final isCompleted = completedDates.contains(date);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatWeekdayDate(date), style: AppTypography.bodyLarge),
                if (!isPast)
                  Text('Upcoming', style: AppTypography.caption)
                else if (!isCompleted)
                  Text('Missed', style: AppTypography.caption.copyWith(color: AppColors.dangerEnd)),
              ],
            ),
          ),
          if (!isPast)
            Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20)
          else if (isCompleted)
            Icon(Icons.check_circle_rounded, color: AppColors.successStart, size: 24)
          else
            Icon(Icons.close_rounded, color: AppColors.dangerEnd.withValues(alpha: 0.7), size: 22),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_kMonthShort[d.month - 1]}';

  String _formatWeekdayDate(DateTime d) =>
      '${_kWeekdayShort[d.weekday - 1]}, ${d.day} ${_kMonthShort[d.month - 1]}';
}
