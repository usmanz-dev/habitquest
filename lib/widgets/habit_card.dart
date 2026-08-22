import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:math' as math;

import '../data/cosmetics.dart';
import '../models/habit.dart';
import '../screens/add_edit_habit_screen.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/rewards.dart';
import 'glass_card.dart';

/// One row of the Home Screen's today checklist (HabitQuest_PRD.md §7
/// screen 5). Renders a check control appropriate to [Habit.trackingType]
/// and, on completion, writes rewards to Isar, bounces the card
/// (§5.4 "Habit Checked" animation spec: CurvedAnimation + Curves.elasticOut),
/// and fires a light haptic + sound effect.
class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({super.key, required this.habit});

  final Habit habit;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _confettiController;

  Timer? _countdownTimer;
  int? _remainingSeconds;
  bool _showConfetti = false;
  final TextEditingController _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiController.dispose();
    _countdownTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  void _playBounce() {
    _bounceController.forward(from: 0).then((_) => _bounceController.reverse());
  }

  /// Confetti Burst cosmetic (HabitQuest_PRD.md §7 screen 11) — plays once
  /// over the card, then removes itself; a no-op if not owned.
  void _maybePlayConfetti() {
    if (!ref.read(userProgressProvider).ownedCosmeticIds.contains(CosmeticIds.confettiBurst)) {
      return;
    }
    setState(() => _showConfetti = true);
    _confettiController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  /// Writes today's log and, if this completes the habit, applies rewards,
  /// bounces the card, and fires haptic feedback.
  Future<void> _writeLogAndMaybeReward({
    required bool completed,
    double? valueLogged,
  }) async {
    final db = ref.read(isarServiceProvider);

    final wasFirstCompletionToday =
        completed && await db.countTodayCompletedLogs() == 0;

    await db.logCompletion(
      widget.habit.id,
      completed: completed,
      valueLogged: valueLogged,
    );
    ref.invalidate(todayLogProvider(widget.habit.id));

    if (!completed) return;

    await NotificationService.instance.cancelLastChance(widget.habit.id);

    final currentStreak = ref.read(userProgressProvider).currentStreak;
    await ref.read(userProgressProvider.notifier).applyHabitCompletion(
          xpGained: kXpPerCompletion,
          goldGained: kGoldPerCompletion,
          hpDelta: kHpRegenPerCompletion,
          newStreak: wasFirstCompletionToday ? currentStreak + 1 : null,
        );

    _playBounce();
    HapticFeedback.lightImpact();
    SoundService.instance.play(AppSound.habitCheck);
    _maybePlayConfetti();

    final todayHabits = ref.read(todayHabitsProvider);
    if (todayHabits.isNotEmpty &&
        await db.isDayComplete(todayHabits.map((h) => h.id).toList())) {
      ref.read(pendingDayCompleteProvider.notifier).state = true;
    }
  }

  void _startTimer() {
    HapticFeedback.selectionClick();
    final totalSeconds = ((widget.habit.targetValue ?? 1) * 60).round();
    setState(() => _remainingSeconds = totalSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_remainingSeconds ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _remainingSeconds = null);
        _writeLogAndMaybeReward(
          completed: true,
          valueLogged: widget.habit.targetValue,
        );
      } else {
        setState(() => _remainingSeconds = next);
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = null);
  }

  Future<void> _adjustCounter(int current, int target, int delta) async {
    HapticFeedback.selectionClick();
    final next = (current + delta).clamp(0, target);
    await _writeLogAndMaybeReward(
      completed: next >= target,
      valueLogged: next.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayLog = ref.watch(todayLogProvider(widget.habit.id)).valueOrNull;
    final isDone = todayLog?.completed == true;

    final Widget control = switch (widget.habit.trackingType) {
      TrackingType.checkbox => _CheckboxControl(
          isDone: isDone,
          onTap: () => _writeLogAndMaybeReward(completed: true),
        ),
      TrackingType.counter => _CounterControl(
          current: (todayLog?.valueLogged ?? 0).toInt(),
          target: (widget.habit.targetValue ?? 1).toInt(),
          isDone: isDone,
          onAdjust: _adjustCounter,
        ),
      TrackingType.timer => _TimerControl(
          isDone: isDone,
          remainingSeconds: _remainingSeconds,
          onStart: _startTimer,
          onCancel: _cancelTimer,
        ),
      TrackingType.value => _ValueControl(
          isDone: isDone,
          loggedValue: todayLog?.valueLogged,
          controller: _valueController,
          onLog: () {
            final value = double.tryParse(_valueController.text);
            if (value == null) return;
            _writeLogAndMaybeReward(completed: true, valueLogged: value);
          },
        ),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: GlassCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(widget.habit.icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.habit.name,
                    style: AppTypography.headingMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                control,
                IconButton(
                  tooltip: 'Edit habit',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditHabitScreen(existingHabit: widget.habit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiController.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Confetti Burst cosmetic effect (HabitQuest_PRD.md §7 screen 11) — a
/// handful of colored squares flying outward from the card's center and
/// fading, over [_HabitCardState._confettiController]'s 800ms run.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _colors = [
    AppColors.purpleStart,
    AppColors.amberStart,
    AppColors.successStart,
    AppColors.dangerStart,
    Colors.white,
  ];
  static const int _particleCount = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    final random = math.Random(7); // fixed seed — consistent burst shape

    for (var i = 0; i < _particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 40 + random.nextDouble() * 60;
      final distance = progress * speed;
      final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      paint.color = _colors[i % _colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(progress * 2 * math.pi);
      canvas.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _DoneChip extends StatelessWidget {
  const _DoneChip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.successStart, size: 20),
        const SizedBox(width: 6),
        Text('Done', style: AppTypography.bodyMedium),
      ],
    );
  }
}

class _CheckboxControl extends StatelessWidget {
  const _CheckboxControl({required this.isDone, required this.onTap});

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDone ? AppGradients.success : null,
          border: isDone
              ? null
              : Border.all(color: AppColors.textSecondary, width: 2),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _CounterControl extends StatelessWidget {
  const _CounterControl({
    required this.current,
    required this.target,
    required this.isDone,
    required this.onAdjust,
  });

  final int current;
  final int target;
  final bool isDone;
  final void Function(int current, int target, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: Icons.remove_rounded,
          onTap: (isDone || current <= 0)
              ? null
              : () => onAdjust(current, target, -1),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$current / $target',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
        ),
        _RoundIconButton(
          icon: Icons.add_rounded,
          onTap: isDone ? null : () => onAdjust(current, target, 1),
        ),
      ],
    );
  }
}

class _TimerControl extends StatelessWidget {
  const _TimerControl({
    required this.isDone,
    required this.remainingSeconds,
    required this.onStart,
    required this.onCancel,
  });

  final bool isDone;
  final int? remainingSeconds;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (isDone) return const _DoneChip();

    if (remainingSeconds != null) {
      final m = (remainingSeconds! ~/ 60).toString().padLeft(2, '0');
      final s = (remainingSeconds! % 60).toString().padLeft(2, '0');
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$m:$s', style: AppTypography.bodyLarge),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      );
    }

    return ElevatedButton(onPressed: onStart, child: const Text('Start'));
  }
}

class _ValueControl extends StatelessWidget {
  const _ValueControl({
    required this.isDone,
    required this.loggedValue,
    required this.controller,
    required this.onLog,
  });

  final bool isDone;
  final double? loggedValue;
  final TextEditingController controller;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loggedValue?.toStringAsFixed(1) ?? '', style: AppTypography.bodyLarge),
          const SizedBox(width: 8),
          const _DoneChip(),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodyLarge,
            decoration: const InputDecoration(isDense: true, hintText: '0'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: onLog, child: const Text('Log')),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface.withValues(alpha: enabled ? 1 : 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.06)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
