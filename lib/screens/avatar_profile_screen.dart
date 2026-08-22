import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/leveling_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
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
              child: Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleStart.withValues(alpha: 0.45),
                      blurRadius: 56,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Image.asset(levelInfo.stage.assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Level ${levelInfo.level}', style: AppTypography.displayLarge),
            ),
            Center(
              child: Text(
                levelInfo.stage.displayName,
                style: AppTypography.headingMedium.copyWith(color: AppColors.purpleEnd),
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
