import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'db_test_screen.dart';

/// Visual reference for the design system — colors, typography, and the
/// glassmorphism card — so it can be checked against the PRD's dark neon
/// "premium gaming" look before any real screens are built.
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Temporary: jumps to the Isar CRUD test screen. Remove once real UI
      // screens exist and navigate here properly.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DbTestScreen()),
        ),
        icon: const Icon(Icons.storage_rounded),
        label: const Text('DB Test'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text('HabitQuest', style: AppTypography.displayLarge),
            const SizedBox(height: 4),
            Text('Design System Preview', style: AppTypography.bodyMedium),
            const SizedBox(height: 32),
            Text('Typography', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display', style: AppTypography.displayLarge),
                  const SizedBox(height: 10),
                  Text('Heading Large', style: AppTypography.headingLarge),
                  const SizedBox(height: 10),
                  Text('Heading Medium', style: AppTypography.headingMedium),
                  const SizedBox(height: 10),
                  Text(
                    'Body Large — the quick brown fox jumps over the lazy dog.',
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Body Medium / secondary label text',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text('CAPTION · METADATA', style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Colors', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorSwatch(label: 'Background', color: AppColors.background),
                _ColorSwatch(label: 'Surface', color: AppColors.surface),
                _GradientSwatch(label: 'Purple', gradient: AppGradients.primary),
                _GradientSwatch(label: 'Gold', gradient: AppGradients.gold),
                _GradientSwatch(label: 'Danger', gradient: AppGradients.danger),
                _GradientSwatch(label: 'Success', gradient: AppGradients.success),
              ],
            ),
            const SizedBox(height: 32),
            Text('Glassmorphism Card', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleStart.withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Study for 30 minutes', style: AppTypography.headingMedium),
                        const SizedBox(height: 4),
                        Text('Daily · 6:00 PM reminder', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Gradient Helper', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            Container(
              height: 52,
              alignment: Alignment.center,
              decoration: AppGradients.buttonDecoration(AppGradients.primary),
              child: Text(
                'Complete Habit',
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 12,
                color: Colors.white.withValues(alpha: 0.08),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.65,
                  child: Container(
                    decoration: AppGradients.progressBarDecoration(AppGradients.gold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch({required this.label, required this.gradient});

  final String label;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
