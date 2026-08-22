import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habit_templates.dart';
import '../../services/providers.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../home_screen.dart';

/// Onboarding — Routine/Template Selection (HabitQuest_PRD.md §7 screen 4,
/// §4.4): pick one quick-start template to bulk-create its habits, or skip
/// straight to a blank Home Screen and build habits manually.
class OnboardingTemplateScreen extends ConsumerStatefulWidget {
  const OnboardingTemplateScreen({super.key});

  @override
  ConsumerState<OnboardingTemplateScreen> createState() => _OnboardingTemplateScreenState();
}

class _OnboardingTemplateScreenState extends ConsumerState<OnboardingTemplateScreen> {
  bool _working = false;

  Future<void> _finish({HabitTemplate? template}) async {
    setState(() => _working = true);
    final db = ref.read(isarServiceProvider);

    if (template != null) {
      for (final templateHabit in template.habits) {
        await db.createHabit(templateHabit.toHabit());
      }
      await ref.read(todayHabitsProvider.notifier).refresh();
    }

    await SettingsService.instance.setOnboardingCompleted(true);
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text('Pick a starting point', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Choose a routine that fits you — you can edit or add more anytime.',
                style: AppTypography.bodyMedium,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                children: [
                  for (final template in kHabitTemplates) ...[
                    _TemplateCard(
                      template: template,
                      onTap: _working ? null : () => _finish(template: template),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: TextButton(
                onPressed: _working ? null : () => _finish(),
                child: Text(
                  'Skip — I\'ll build my own',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Text(template.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: AppTypography.headingMedium),
                  const SizedBox(height: 4),
                  Text(
                    template.habits.map((h) => h.name).join(' · '),
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
