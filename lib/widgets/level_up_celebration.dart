import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/leveling_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Full-screen "avatar evolved" celebration (HabitQuest_PRD.md §5.4 "Level
/// Up: golden flash overlay, scale/rotate animation, particle burst
/// effect"), shown when a habit completion crosses an avatar-stage milestone
/// (§5.3 — level 5/15/30, or the ad-unlocked Golden Phoenix).
class LevelUpCelebration extends StatefulWidget {
  const LevelUpCelebration({super.key, required this.stage});

  final AvatarStage stage;

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  late final AnimationController _avatarController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    SoundService.instance.play(AppSound.levelUp);
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _flashController.dispose();
    _avatarController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut);
    final rotate = CurvedAnimation(parent: _avatarController, curve: Curves.easeOutBack);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: AppColors.background.withValues(alpha: 0.94)),
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: const Size(340, 340),
              painter: _ParticlePainter(progress: _particleController.value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _avatarController,
                builder: (context, child) => Transform.rotate(
                  angle: (1 - rotate.value) * 0.6,
                  child: Transform.scale(scale: scale.value, child: child),
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.gold,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amberStart.withValues(alpha: 0.6),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(widget.stage.assetPath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 28),
              Text('LEVEL UP!', style: AppTypography.displayLarge),
              const SizedBox(height: 8),
              Text(
                widget.stage.displayName,
                style: AppTypography.headingLarge.copyWith(color: AppColors.amberStart),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleStart,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                ),
                child: Text(
                  'Continue',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // Golden flash, on top, fading out — the first thing seen when the
          // modal appears.
          IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(
                CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
              ),
              child: Container(color: AppColors.amberStart.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress});

  final double progress;
  static const int _particleCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxDistance = size.shortestSide / 2;
    final paint = Paint();

    for (var i = 0; i < _particleCount; i++) {
      // Stagger each particle's phase so the burst reads as continuous.
      final phase = (progress + i / _particleCount) % 1.0;
      final angle = (2 * math.pi / _particleCount) * i;
      final distance = phase * maxDistance;
      final opacity = (1 - phase).clamp(0.0, 1.0);
      final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;

      paint.color = AppColors.amberEnd.withValues(alpha: opacity);
      canvas.drawCircle(offset, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}
