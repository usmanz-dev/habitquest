import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/leveling_service.dart';
import '../../theme/app_theme.dart';
import 'onboarding_template_screen.dart';

/// Onboarding — Avatar Selection (HabitQuest_PRD.md §7 screen 3). HabitQuest
/// has a single avatar that evolves through 5 stages by level (§5.3) rather
/// than several starting avatars to pick between, so this screen introduces
/// that companion and previews the evolution line instead of offering a
/// choice that the data model doesn't support.
class OnboardingAvatarScreen extends StatelessWidget {
  const OnboardingAvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.purpleStart.withValues(alpha: 0.45), blurRadius: 44),
                  ],
                ),
                child: Image.asset(AvatarStage.babyRobot.assetPath, fit: BoxFit.contain),
              ).animate().scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 28),
              Text('Meet your companion', style: AppTypography.headingLarge)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                "It starts as a Baby Robot and evolves as you build real "
                "habits — never resetting, only growing.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final stage in AvatarStage.values.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _StagePreview(stage: stage),
                    ),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingTemplateScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleStart,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagePreview extends StatelessWidget {
  const _StagePreview({required this.stage});

  final AvatarStage stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Image.asset(stage.assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text(stage.displayName, style: AppTypography.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
