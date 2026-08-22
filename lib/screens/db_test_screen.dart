import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// Temporary screen for manually verifying the Isar CRUD layer end-to-end
/// before any real UI is built on top of it. Not part of the shipped app.
class DbTestScreen extends StatefulWidget {
  const DbTestScreen({super.key});

  @override
  State<DbTestScreen> createState() => _DbTestScreenState();
}

class _TestResult {
  _TestResult(this.label, this.passed, [this.detail = '']);

  final String label;
  final bool passed;
  final String detail;
}

class _DbTestScreenState extends State<DbTestScreen> {
  final IsarService _db = IsarService.instance;
  final List<_TestResult> _results = [];
  bool _running = false;
  bool _seeding = false;

  /// Dev convenience: creates one persistent habit per tracking type so the
  /// real Home Screen has something to render. Safe to tap more than once.
  Future<void> _seedSampleHabits() async {
    setState(() => _seeding = true);
    final samples = [
      Habit()
        ..name = 'Pray'
        ..trackingType = TrackingType.checkbox
        ..frequencyType = FrequencyType.daily
        ..icon = '🙏'
        ..category = HabitCategory.spiritual
        ..createdAt = DateTime.now(),
      Habit()
        ..name = 'Drink Water'
        ..trackingType = TrackingType.counter
        ..targetValue = 8
        ..frequencyType = FrequencyType.daily
        ..icon = '💧'
        ..category = HabitCategory.health
        ..createdAt = DateTime.now(),
      Habit()
        ..name = 'Study'
        ..trackingType = TrackingType.timer
        ..targetValue = 30
        ..frequencyType = FrequencyType.daily
        ..icon = '📚'
        ..category = HabitCategory.study
        ..createdAt = DateTime.now(),
      Habit()
        ..name = 'Log Blood Sugar'
        ..trackingType = TrackingType.value
        ..frequencyType = FrequencyType.daily
        ..icon = '🩸'
        ..category = HabitCategory.health
        ..createdAt = DateTime.now(),
    ];
    for (final habit in samples) {
      await _db.createHabit(habit);
    }
    setState(() => _seeding = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeded 4 sample habits (one per tracking type)')),
      );
    }
  }

  Future<void> _runCrudTest() async {
    setState(() {
      _running = true;
      _results.clear();
    });

    final results = <_TestResult>[];
    void record(String label, bool passed, [String detail = '']) {
      results.add(_TestResult(label, passed, detail));
      setState(() {
        _results
          ..clear()
          ..addAll(results);
      });
    }

    try {
      // CREATE
      final name = 'Test Habit ${DateTime.now().millisecondsSinceEpoch}';
      final habit = Habit()
        ..name = name
        ..trackingType = TrackingType.checkbox
        ..frequencyType = FrequencyType.daily
        ..icon = '✅'
        ..createdAt = DateTime.now();
      await _db.createHabit(habit);
      record('CREATE habit', habit.id != Isar.autoIncrement, 'id=${habit.id}');

      // READ (single)
      final fetched = await _db.getHabit(habit.id);
      record('READ habit by id', fetched?.name == name);

      // READ (today's checklist)
      final today = await _db.fetchTodayHabits();
      record(
        "READ fetchTodayHabits() includes it",
        today.any((h) => h.id == habit.id),
        '${today.length} habit(s) due today',
      );

      // UPDATE
      final updatedName = '$name (updated)';
      habit.name = updatedName;
      await _db.updateHabit(habit);
      final updated = await _db.getHabit(habit.id);
      record('UPDATE habit name', updated?.name == updatedName);

      // LOG COMPLETION
      final log = await _db.logCompletion(habit.id, completed: true);
      record(
        'CREATE habit log (logCompletion)',
        log.completed && log.habitId == habit.id,
      );

      final logs = await _db.getLogsForHabit(habit.id);
      record('READ logs for habit', logs.length == 1);

      // USER PROGRESS
      final before = await _db.getUserProgress();
      final after = await _db.applyHabitCompletionRewards(
        xpGained: 10,
        goldGained: 5,
        newStreak: before.currentStreak + 1,
      );
      record(
        'UPDATE XP/gold/streak',
        after.totalXP == before.totalXP + 10 &&
            after.totalGold == before.totalGold + 5 &&
            after.currentStreak == before.currentStreak + 1,
        'XP ${before.totalXP} → ${after.totalXP}   '
        'Gold ${before.totalGold} → ${after.totalGold}   '
        'Streak → ${after.currentStreak}',
      );

      // DELETE (+ cascade of its logs)
      await _db.deleteHabit(habit.id);
      final afterDelete = await _db.getHabit(habit.id);
      final logsAfterDelete = await _db.getLogsForHabit(habit.id);
      record(
        'DELETE habit (+ cascade logs)',
        afterDelete == null && logsAfterDelete.isEmpty,
      );
    } catch (e, st) {
      record('Unexpected error', false, '$e\n$st');
    }

    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.passed).length;
    final total = _results.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Database CRUD Test', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        total == 0 ? 'No tests run yet' : '$passed / $total checks passed',
                        style: AppTypography.bodyLarge,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _running ? null : _runCrudTest,
                      child: Text(_running ? 'Running…' : 'Run CRUD Test'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Populate the Home Screen with real data',
                        style: AppTypography.bodyLarge,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _seeding ? null : _seedSampleHabits,
                      child: Text(_seeding ? 'Seeding…' : 'Seed Sample Habits'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          'Tap "Run CRUD Test" to exercise\ncreate / read / update / delete.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          return GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  r.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: r.passed ? AppColors.successStart : AppColors.dangerEnd,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.label, style: AppTypography.bodyLarge),
                                      if (r.detail.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(r.detail, style: AppTypography.bodyMedium),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
