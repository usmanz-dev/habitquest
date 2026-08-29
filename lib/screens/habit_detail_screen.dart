import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../services/habit_completion.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/habit_card.dart';

const List<String> _kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _kMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Visual state of a single day in the [HabitDetailScreen]'s date grid.
enum _DayVisualState { completed, missed, todayPending, future }

/// Habit Detail Screen (HabitQuest_PRD.md §7 screen 6) — every habit opens
/// this from its Home Screen card. Shows a round-date-box calendar built
/// from [HabitDuration.scheduleDates]: the full start-to-end range for a
/// [FrequencyType.duration] challenge, or a rolling ~30-day-back/1-week-ahead
/// window for any recurring habit. For checkbox habits, today's box is
/// tappable and marks the habit done directly (same reward flow as the Home
/// Screen's checkbox); other tracking types still get the real, interactive
/// [HabitCard] control below the grid, since counter/timer/value habits need
/// more than a single tap to log.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final Habit habit;

  _DayVisualState _stateFor(DateTime date, DateTime todayKey, Set<DateTime> completedDates) {
    if (completedDates.contains(date)) return _DayVisualState.completed;
    if (date == todayKey) return _DayVisualState.todayPending;
    if (date.isBefore(todayKey)) return _DayVisualState.missed;
    return _DayVisualState.future;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = habit.scheduleDates;
    final isChallenge = habit.frequencyType == FrequencyType.duration;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final logsAsync = ref.watch(habitLogsProvider(habit.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(habit.name, style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Could not load this habit.', style: AppTypography.bodyMedium),
          ),
          data: (logs) {
            final completedDates = {
              for (final log in logs)
                if (log.completed) DateTime(log.date.year, log.date.month, log.date.day),
            };
            final daysSoFar = dates.where((d) => !d.isAfter(todayKey)).length;
            final doneSoFar =
                dates.where((d) => !d.isAfter(todayKey) && completedDates.contains(d)).length;
            final isTodayDone = completedDates.contains(todayKey);
            final isCheckbox = habit.trackingType == TrackingType.checkbox;

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
                                Text(
                                  isChallenge ? '${dates.length}-day challenge' : 'Your habit plan',
                                  style: AppTypography.headingMedium,
                                ),
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
                const SizedBox(height: 28),
                Text('Day by Day', style: AppTypography.headingMedium),
                const SizedBox(height: 4),
                Text(
                  isCheckbox
                      ? "Tap today's date to mark it done."
                      : "Use the card below to log today's progress.",
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 18,
                  children: [
                    for (final date in dates)
                      _DateBox(
                        date: date,
                        state: _stateFor(date, todayKey, completedDates),
                        onTap: (isCheckbox && date == todayKey && !isTodayDone)
                            ? () => logHabitCompletion(ref, habit, completed: true)
                            : null,
                      ),
                  ],
                ),
                if (!isCheckbox) ...[
                  const SizedBox(height: 24),
                  HabitCard(habit: habit, enableDetailTap: false),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_kMonthShort[d.month - 1]}';
}

/// One round date box in the challenge calendar. The weekday + day number is
/// always shown above the circle so the date stays identifiable even when
/// the circle itself shows a check/cross/lock instead of the number.
class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.state, this.onTap});

  final DateTime date;
  final _DayVisualState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${_kWeekdayShort[date.weekday - 1]} ${date.day}';

    final borderColor = switch (state) {
      _DayVisualState.completed => Colors.transparent,
      _DayVisualState.missed => AppColors.dangerEnd.withValues(alpha: 0.75),
      _DayVisualState.todayPending => AppColors.purpleEnd,
      _DayVisualState.future => Colors.white.withValues(alpha: 0.1),
    };

    Widget circle = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: state == _DayVisualState.completed ? AppGradients.success : null,
        color: state == _DayVisualState.completed ? null : AppColors.surface,
        border: Border.all(
          color: borderColor,
          width: state == _DayVisualState.todayPending
              ? 2.5
              : state == _DayVisualState.missed
                  ? 2
                  : 1,
        ),
        boxShadow: state == _DayVisualState.completed
            ? [BoxShadow(color: AppColors.successStart.withValues(alpha: 0.45), blurRadius: 14)]
            : null,
      ),
      child: switch (state) {
        _DayVisualState.completed => const Icon(Icons.check_rounded, color: Colors.white, size: 22),
        _DayVisualState.missed =>
          Icon(Icons.close_rounded, color: AppColors.dangerEnd.withValues(alpha: 0.85), size: 20),
        _DayVisualState.future => Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            size: 16,
          ),
        _DayVisualState.todayPending => Text(
            '${date.day}',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
      },
    );

    if (state == _DayVisualState.todayPending) {
      circle = circle
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return Opacity(
      opacity: state == _DayVisualState.future ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 6),
            circle,
          ],
        ),
      ),
    );
  }
}
