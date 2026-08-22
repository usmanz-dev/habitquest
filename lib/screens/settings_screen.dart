import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../services/notification_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// Settings Screen (HabitQuest_PRD.md §7 screen 14, §13): notification and
/// sound toggles, theme info, data reset, Rate Us, and the Privacy
/// Policy/Terms of Service links required for AdMob/Play Store compliance.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _resetting = false;

  Future<void> _rateUs() async {
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } catch (error) {
      debugPrint('[SettingsScreen] Rate Us failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the review prompt right now.")),
      );
    }
  }

  Future<void> _confirmResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Reset all data?', style: AppTypography.headingMedium),
        content: Text(
          'This permanently deletes every habit, log, and your XP/gold/streak '
          'progress. This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Reset', style: TextStyle(color: AppColors.dangerEnd)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _resetting = true);
    HapticFeedback.heavyImpact();

    await ref.read(isarServiceProvider).resetAllData();
    await NotificationService.instance.cancelAll();
    await ref.read(todayHabitsProvider.notifier).refresh();
    await ref.read(userProgressProvider.notifier).refresh();

    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Settings', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Preferences'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    subtitle: 'Habit reminders & last-chance alerts',
                    value: settings.notificationsEnabled,
                    onChanged: (value) =>
                        ref.read(settingsProvider.notifier).setNotificationsEnabled(value),
                  ),
                  _rowDivider(),
                  _SwitchRow(
                    icon: Icons.volume_up_outlined,
                    label: 'Sound Effects',
                    subtitle: 'Coming soon',
                    value: settings.soundEnabled,
                    onChanged: (value) =>
                        ref.read(settingsProvider.notifier).setSoundEnabled(value),
                  ),
                  _rowDivider(),
                  const _InfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Theme',
                    value: 'Dark Neon (default)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('Data'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: _ActionRow(
                icon: Icons.delete_forever_outlined,
                iconColor: AppColors.dangerEnd,
                label: _resetting ? 'Resetting…' : 'Reset all data',
                onTap: _resetting ? null : _confirmResetAllData,
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('Support'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: _ActionRow(
                icon: Icons.star_outline_rounded,
                iconColor: AppColors.amberStart,
                label: 'Rate Us',
                onTap: _rateUs,
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('Legal'),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                  _rowDivider(),
                  _ActionRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() => Divider(height: 1, color: Colors.white.withValues(alpha: 0.08));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTypography.caption);
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purpleStart,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTypography.bodyLarge)),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(color: iconColor),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
