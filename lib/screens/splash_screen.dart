import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_welcome_screen.dart';

/// Splash Screen (HabitQuest_PRD.md §7 screen 1): a brief animated-logo
/// beat before routing to Onboarding (first launch) or straight to Home
/// (every launch after). Isar/Settings/Notifications/Ads are already
/// initialized in main() before this widget is even built, so the delay
/// here is purely a deliberate branding beat, not a loading wait.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minDisplayTime = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    Future.delayed(_minDisplayTime, _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final destination = SettingsService.instance.hasCompletedOnboarding
        ? const HomeScreen()
        : const OnboardingWelcomeScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleStart.withValues(alpha: 0.55),
                    blurRadius: 50,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/avatars/avatar_1_baby_robot.png',
                fit: BoxFit.contain,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.06, 1.06),
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 28),
            Text('HabitQuest', style: AppTypography.displayLarge)
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms),
            const SizedBox(height: 6),
            Text(
              'Turn your habits into an adventure',
              style: AppTypography.bodyMedium,
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
