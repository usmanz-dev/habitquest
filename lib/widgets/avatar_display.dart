import 'package:flutter/material.dart';

import '../services/leveling_service.dart';
import '../theme/app_theme.dart';

/// Avatar display area for the Home Screen (HabitQuest_PRD.md §7 screen 5).
/// Shows the current avatar-stage artwork (§5.3) idly floating up and down
/// via a [Tween].
class AvatarDisplay extends StatefulWidget {
  const AvatarDisplay({super.key, required this.level, required this.stage});

  final int level;
  final AvatarStage stage;

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleStart.withValues(alpha: 0.45),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(widget.stage.assetPath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        Text('Level ${widget.level}', style: AppTypography.headingMedium),
        const SizedBox(height: 2),
        Text(widget.stage.displayName, style: AppTypography.bodyMedium),
      ],
    );
  }
}
