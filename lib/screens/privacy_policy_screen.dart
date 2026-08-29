import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Privacy Policy Page (HabitQuest_PRD.md §7 screen 15, §13). Content
/// mirrors HabitQuest_Privacy_Policy.md — update that file and this screen
/// together if the policy changes.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Privacy Policy', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last updated: August 18, 2026', style: AppTypography.caption),
              const SizedBox(height: 16),
              Text(
                'This Privacy Policy describes how HabitQuest ("we", "our", "the app") '
                'handles information when you use our mobile application.',
                style: AppTypography.bodyLarge,
              ),
              const _Section(
                title: '1. Information We Collect',
                body:
                    'HabitQuest does not require account creation, login, or any personal '
                    'information (such as name, email, or phone number) to use the app. All '
                    'habit data, progress, XP, levels, and settings you create are stored '
                    'locally on your device only and are never transmitted to us or any '
                    'third party.',
              ),
              const _Section(
                title: '2. Advertising',
                body:
                    'HabitQuest is free to use and supported by advertisements served '
                    "through Google AdMob. Google AdMob may collect certain device "
                    'information (such as advertising identifiers) to serve relevant ads '
                    "and measure ad performance, in accordance with Google's own privacy "
                    'policy. You can learn more about how Google uses this data at: '
                    'https://policies.google.com/technologies/partner-sites\n\n'
                    "You may be able to opt out of personalized advertising through your "
                    "device's ad settings.",
              ),
              const _Section(
                title: '3. Data We Do Not Collect',
                body: 'We do not collect, store, or share:',
                bullets: [
                  'Your name, email, or contact details',
                  'Your location',
                  'Your contacts or camera data',
                  'Any health or medical information you may enter into custom habits',
                ],
              ),
              const _Section(
                title: "4. Children's Privacy",
                body:
                    'HabitQuest is not directed at children under the age of 13, and we do '
                    'not knowingly collect any information from children.',
              ),
              const _Section(
                title: '5. Data Storage & Security',
                body:
                    'All app data is stored locally on your device using local database '
                    'storage. If you uninstall the app or clear its data, this information '
                    'is permanently deleted and cannot be recovered by us, as we never had '
                    'access to it.',
              ),
              const _Section(
                title: '6. Changes to This Policy',
                body:
                    'We may update this Privacy Policy from time to time. Changes will be '
                    'reflected with an updated "Last updated" date.',
              ),
              const _Section(
                title: '7. Contact Us',
                body:
                    'If you have any questions about this Privacy Policy, contact us at: '
                    'habitquest63@gmail.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, this.bullets});

  final String title;
  final String body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: 8),
          Text(body, style: AppTypography.bodyLarge),
          if (bullets != null) ...[
            const SizedBox(height: 8),
            for (final bullet in bullets!)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: AppTypography.bodyLarge),
                    Expanded(child: Text(bullet, style: AppTypography.bodyLarge)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
