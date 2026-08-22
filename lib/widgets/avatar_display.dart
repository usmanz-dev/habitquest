import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/cosmetics.dart';
import '../services/leveling_service.dart';
import '../theme/app_theme.dart';

/// Colors the avatar's glow cycles through when [CosmeticIds.rainbowGlow]
/// is owned — the app's four accent gradients' leading colors, in a loop.
const List<Color> _kRainbowColors = [
  AppColors.purpleStart,
  AppColors.amberStart,
  AppColors.successStart,
  AppColors.dangerStart,
];

/// Avatar display area for the Home Screen (HabitQuest_PRD.md §7 screen 5)
/// and Avatar Profile Screen. Shows the current avatar-stage artwork (§5.3)
/// idly floating up and down via a [Tween], layered with any owned Shop
/// cosmetics (§7 screen 11): a rotating neon trail ring, a static gold
/// frame, and/or a rainbow-cycling glow — all independent, so however many
/// are owned render together.
class AvatarDisplay extends StatefulWidget {
  const AvatarDisplay({
    super.key,
    required this.level,
    required this.stage,
    this.ownedCosmetics = const {},
  });

  final int level;
  final AvatarStage stage;
  final Set<String> ownedCosmetics;

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  AnimationController? _glowController;
  Animation<Color?>? _glowAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    if (widget.ownedCosmetics.contains(CosmeticIds.rainbowGlow)) {
      _glowController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2 * _kRainbowColors.length),
      )..repeat();
      _glowAnimation = TweenSequence<Color?>([
        for (var i = 0; i < _kRainbowColors.length; i++)
          TweenSequenceItem(
            tween: ColorTween(
              begin: _kRainbowColors[i],
              end: _kRainbowColors[(i + 1) % _kRainbowColors.length],
            ),
            weight: 1,
          ),
      ]).animate(_glowController!);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNeonTrail = widget.ownedCosmetics.contains(CosmeticIds.neonTrail);
    final hasGoldenFrame = widget.ownedCosmetics.contains(CosmeticIds.goldenFrame);

    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_floatController, if (_glowController != null) _glowController]),
          builder: (context, child) {
            final glowColor = _glowAnimation?.value ?? AppColors.purpleStart;
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasNeonTrail)
                      Container(
                        width: 178,
                        height: 178,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              glowColor.withValues(alpha: 0),
                              glowColor.withValues(alpha: 0.9),
                              glowColor.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2400.ms),
                    if (hasGoldenFrame)
                      Container(
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.amberStart, width: 3),
                          boxShadow: [
                            BoxShadow(color: AppColors.amberStart.withValues(alpha: 0.5), blurRadius: 14),
                          ],
                        ),
                      ),
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.45),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            );
          },
          child: Image.asset(widget.stage.assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text('Level ${widget.level}', style: AppTypography.headingMedium),
        const SizedBox(height: 2),
        Text(widget.stage.displayName, style: AppTypography.bodyMedium),
      ],
    );
  }
}
