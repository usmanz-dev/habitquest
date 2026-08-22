import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';
import 'onboarding_avatar_screen.dart';

/// Onboarding — Welcome (HabitQuest_PRD.md §7 screen 2): the app's pitch
/// before asking for anything, per §1's differentiators.
class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

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
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.purpleStart.withValues(alpha: 0.4), blurRadius: 40),
                  ],
                ),
                child: const Text('⚔️', style: TextStyle(fontSize: 48)),
              ).animate().scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 32),
              Text(
                'Turn your habits\ninto an adventure',
                textAlign: TextAlign.center,
                style: AppTypography.displayLarge,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                'Complete real habits to earn XP and Gold, and watch your '
                'own robot companion level up and evolve. No login, no '
                'internet needed, and a missed day never resets your progress.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingAvatarScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleStart,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                  child: Text(
                    'Get Started',
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
