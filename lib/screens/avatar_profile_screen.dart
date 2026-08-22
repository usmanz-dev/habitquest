import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cosmetics.dart';
import '../services/leveling_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/glass_card.dart';

/// Avatar Profile Screen (HabitQuest_PRD.md §7 screen 8): large avatar,
/// current level, a gallery of all 5 avatar stages (locked ones greyed
/// out/silhouetted), and progress toward the next unlock.
class AvatarProfileScreen extends ConsumerWidget {
  const AvatarProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final levelInfo = LevelingService.levelInfoForXp(
      progress.totalXP,
      premiumUnlocked: progress.premiumAvatarUnlocked,
    );
    final nextUnlock = _nextUnlock(levelInfo.stage, progress.totalXP);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Avatar Profile', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (progress.ownedCosmeticIds.contains(CosmeticIds.starryBackdrop))
                    const _StarryBackdrop(),
                  AvatarDisplay(
                    level: levelInfo.level,
                    stage: levelInfo.stage,
                    ownedCosmetics: progress.ownedCosmeticIds.toSet(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Evolution', style: AppTypography.bodyMedium),
                  const SizedBox(height: 8),
                  if (nextUnlock == null)
                    Text('Max evolution reached!', style: AppTypography.headingMedium)
                  else ...[
                    Text(
                      nextUnlock.stage.displayName,
                      style: AppTypography.headingMedium,
                    ),
                    const SizedBox(height: 12),
                    if (nextUnlock.progress != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 12,
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withValues(alpha: 0.08)),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: nextUnlock.progress!.clamp(0.02, 1.0),
                                child: Container(
                                  decoration:
                                      AppGradients.progressBarDecoration(AppGradients.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level ${levelInfo.level} → Level ${nextUnlock.requiredLevel}',
                        style: AppTypography.caption,
                      ),
                    ] else
                      Text(
                        'Unlocked via a Rewarded Ad — see the Shop.',
                        style: AppTypography.caption,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Avatar Gallery', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
              children: [
                for (final stage in AvatarStage.values)
                  _AvatarGalleryTile(
                    stage: stage,
                    unlocked: stage.index <= levelInfo.stage.index,
                    isCurrent: stage == levelInfo.stage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextUnlock {
  const _NextUnlock({required this.stage, required this.requiredLevel, this.progress});

  final AvatarStage stage;
  final int requiredLevel;

  /// Progress (0.0-1.0) toward this unlock, or null when it isn't XP-based
  /// (the Golden Phoenix — unlocked via Rewarded Ad, per §5.3/§10).
  final double? progress;
}

/// What the user is working toward next, given their current [stage].
_NextUnlock? _nextUnlock(AvatarStage stage, int totalXp) {
  switch (stage) {
    case AvatarStage.babyRobot:
      return _NextUnlock(
        stage: AvatarStage.ironWarrior,
        requiredLevel: 5,
        progress: totalXp / LevelingService.xpForLevel5,
      );
    case AvatarStage.ironWarrior:
      final span = LevelingService.xpForLevel15 - LevelingService.xpForLevel5;
      return _NextUnlock(
        stage: AvatarStage.shadowNinja,
        requiredLevel: 15,
        progress: (totalXp - LevelingService.xpForLevel5) / span,
      );
    case AvatarStage.shadowNinja:
      final span = LevelingService.xpForLevel30 - LevelingService.xpForLevel15;
      return _NextUnlock(
        stage: AvatarStage.cyberMage,
        requiredLevel: 30,
        progress: (totalXp - LevelingService.xpForLevel15) / span,
      );
    case AvatarStage.cyberMage:
      return const _NextUnlock(stage: AvatarStage.goldenPhoenix, requiredLevel: 0, progress: null);
    case AvatarStage.goldenPhoenix:
      return null;
  }
}

/// Starry Backdrop cosmetic (HabitQuest_PRD.md §7 screen 11): a small
/// twinkling starfield behind the avatar, seeded once so stars don't jump
/// position on rebuild.
class _StarryBackdrop extends StatefulWidget {
  const _StarryBackdrop();

  @override
  State<_StarryBackdrop> createState() => _StarryBackdropState();
}

class _StarryBackdropState extends State<_StarryBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Offset> _starPositions;
  late final List<double> _starPhases;

  static const int _starCount = 18;
  static const double _fieldSize = 260;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    final random = math.Random(42); // fixed seed — stable star field
    _starPositions = List.generate(
      _starCount,
      (_) => Offset(random.nextDouble() * _fieldSize, random.nextDouble() * _fieldSize),
    );
    _starPhases = List.generate(_starCount, (_) => random.nextDouble());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: const Size(_fieldSize, _fieldSize),
          painter: _StarFieldPainter(
            positions: _starPositions,
            phases: _starPhases,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.positions, required this.phases, required this.progress});

  final List<Offset> positions;
  final List<double> phases;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < positions.length; i++) {
      final twinkle = (math.sin((progress + phases[i]) * 2 * math.pi) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.15 + twinkle * 0.55);
      canvas.drawCircle(positions[i], 1.2 + twinkle * 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => oldDelegate.progress != progress;
}

class _AvatarGalleryTile extends StatelessWidget {
  const _AvatarGalleryTile({
    required this.stage,
    required this.unlocked,
    required this.isCurrent,
  });

  final AvatarStage stage;
  final bool unlocked;
  final bool isCurrent;

  String get _unlockLabel => switch (stage) {
        AvatarStage.babyRobot => 'Unlocked',
        AvatarStage.ironWarrior => 'Level 5',
        AvatarStage.shadowNinja => 'Level 15',
        AvatarStage.cyberMage => 'Level 30',
        AvatarStage.goldenPhoenix => 'Rewarded Ad',
      };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(stage.assetPath, fit: BoxFit.contain);

    // Plain surface container rather than GlassCard: 5 stacked
    // BackdropFilter blurs in one grid is unnecessarily expensive to render.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (unlocked)
                  image
                else
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.35, 0, // dim + mostly-transparent -> silhouette look
                    ]),
                    child: image,
                  ),
                if (!unlocked)
                  const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stage.displayName,
            style: AppTypography.bodyMedium.copyWith(
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          Text(_unlockLabel, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
