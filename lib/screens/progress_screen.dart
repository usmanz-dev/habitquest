import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_log.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/glass_card.dart';

/// Progress/Stats Screen (HabitQuest_PRD.md §7 screen 10): weekly/monthly
/// completion stats and a banner ad placeholder. (The §6.6 "streak path"
/// journey map has been removed from this screen.)
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
