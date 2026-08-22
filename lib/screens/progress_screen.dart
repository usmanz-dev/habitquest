import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_log.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_card.dart';

/// How many trailing days the streak path shows.
const int _kPathDays = 14;

/// Horizontal alignment (-1..1) each node cycles through, giving the path
/// its winding shape (HabitQuest_PRD.md §6.6).
const List<double> _kZigzag = [-0.7, -0.25, 0.3, 0.7, 0.3, -0.25];

const double _kNodeSize = 40;
const double _kRowHeight = 72;

/// Progress/Stats Screen (HabitQuest_PRD.md §7 screen 10): the §6.6 "streak
/// path" journey map, plus weekly/monthly completion stats and a banner ad
/// placeholder.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Progress', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: logsAsync.when(
                data: (logs) => _ProgressBody(logs: logs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Could not load progress.', style: AppTypography.bodyMedium),
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.logs});

  final List<HabitLog> logs;

  Set<DateTime> get _completedDates => {
        for (final log in logs)
          if (log.completed) DateTime(log.date.year, log.date.month, log.date.day),
      };

  double _completionRate(Set<DateTime> completed, int days) {
    final today = DateTime.now();
    var hits = 0;
    for (var i = 0; i < days; i++) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      if (completed.contains(day)) hits++;
    }
    return hits / days;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedDates;
    final weeklyRate = _completionRate(completed, 7);
    final monthlyRate = _completionRate(completed, 30);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Streak Path', style: AppTypography.headingLarge),
        const SizedBox(height: 4),
        Text('Your last $_kPathDays days', style: AppTypography.bodyMedium),
        const SizedBox(height: 16),
        GlassCard(
          child: _StreakPath(completedDates: completed),
        ),
        const SizedBox(height: 28),
        Text('Completion Stats', style: AppTypography.headingLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'This Week', rate: weeklyRate, gradient: AppGradients.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(label: 'This Month', rate: monthlyRate, gradient: AppGradients.gold),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakPath extends StatelessWidget {
  const _StreakPath({required this.completedDates});

  final Set<DateTime> completedDates;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final days = [
      for (var i = _kPathDays - 1; i >= 0; i--) todayOnly.subtract(Duration(days: i)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centers = [
          for (var i = 0; i < days.length; i++)
            Offset(
              width / 2 + _kZigzag[i % _kZigzag.length] * (width / 2 - _kNodeSize),
              _kRowHeight * i + _kRowHeight / 2,
            ),
        ];

        return SizedBox(
          width: width,
          height: _kRowHeight * days.length,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, _kRowHeight * days.length),
                painter: _PathLinePainter(points: centers),
              ),
              for (var i = 0; i < days.length; i++)
                Positioned(
                  left: centers[i].dx - _kNodeSize / 2,
                  top: centers[i].dy - _kNodeSize / 2,
                  child: _PathNode(
                    date: days[i],
                    completed: completedDates.contains(days[i]),
                    isToday: days[i] == todayOnly,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PathLinePainter extends CustomPainter {
  _PathLinePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter oldDelegate) => oldDelegate.points != points;
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.date, required this.completed, required this.isToday});

  final DateTime date;
  final bool completed;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    Widget node = Container(
      width: _kNodeSize,
      height: _kNodeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: completed ? AppGradients.gold : null,
        color: completed ? null : AppColors.surface,
        border: Border.all(
          color: isToday ? AppColors.purpleEnd : Colors.white.withValues(alpha: 0.14),
          width: isToday ? 2.5 : 1,
        ),
        boxShadow: completed
            ? [BoxShadow(color: AppColors.amberStart.withValues(alpha: 0.5), blurRadius: 14)]
            : null,
      ),
      child: Text(
        '${date.day}',
        style: AppTypography.caption.copyWith(
          color: completed ? Colors.black87 : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    // Completed days glow gold; today additionally pulses — both via
    // flutter_animate, layered independently so they animate concurrently.
    if (completed) {
      node = node
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.7));
    }

    if (isToday) {
      node = node
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.18, 1.18),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return node;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.rate, required this.gradient});

  final String label;
  final double rate;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).round();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              '$percent%',
              style: AppTypography.displayLarge.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: rate.clamp(0.0, 1.0),
                    child: Container(decoration: AppGradients.progressBarDecoration(gradient)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
