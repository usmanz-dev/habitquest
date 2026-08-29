import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Terms of Service Page (HabitQuest_PRD.md §7 screen 16, §13). Content
/// mirrors HabitQuest_Terms_of_Service.md — update that file and this
/// screen together if the terms change.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Terms of Service', style: AppTypography.headingMedium),
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
                'By downloading and using HabitQuest, you agree to the following terms.',
                style: AppTypography.bodyLarge,
              ),
              const _Section(
                title: '1. Use of the App',
                body:
                    'HabitQuest is a free habit-tracking application provided "as is" for '
                    'personal, non-commercial use. You may use it to create, track, and '
                    'manage personal habits and routines.',
              ),
              const _Section(
                title: '2. No Account Required',
                body:
                    'The app does not require registration or login. You are responsible '
                    'for your own device and any data you enter into the app.',
              ),
              const _Section(
                title: '3. Advertisements',
                body:
                    'The app displays advertisements through Google AdMob, including '
                    'banner, interstitial, and rewarded video ads, to support the app '
                    'being free. By using the app, you agree to the display of such ads.',
              ),
              const _Section(
                title: '4. No Medical or Professional Advice',
                body:
                    'HabitQuest is a general habit-tracking tool. It is not intended to '
                    'provide medical, health, fitness, or professional advice. Always '
                    'consult a qualified professional for medical or health-related '
                    'decisions.',
              ),
              const _Section(
                title: '5. Data Loss Disclaimer',
                body:
                    'Since all data is stored locally on your device, we are not '
                    'responsible for any loss of data due to app uninstallation, device '
                    'damage, device change, or operating system issues.',
              ),
              const _Section(
                title: '6. Limitation of Liability',
                body:
                    'The app is provided without warranties of any kind. We are not '
                    'liable for any damages arising from the use or inability to use the '
                    'app.',
              ),
              const _Section(
                title: '7. Changes to the App or Terms',
                body:
                    'We may update the app or these Terms at any time. Continued use of '
                    'the app after changes constitutes acceptance of the updated Terms.',
              ),
              const _Section(
                title: '8. Contact Us',
                body: 'For any questions regarding these Terms, contact us at: habitquest63@gmail.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

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
        ],
      ),
    );
  }
}
