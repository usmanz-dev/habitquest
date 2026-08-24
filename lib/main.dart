import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/isar_service.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/app_icon_service.dart';
import 'services/background_tasks.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.instance.init();
  await SettingsService.instance.init();
  // Just channel/plugin registration — no permission prompt, fast and local.
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: HabitQuestApp()));

  // Everything below is either interactive (the notification permission
  // dialog, and on Android 12+ a settings redirect for exact alarms) or
  // network/SDK-touching (ads). Awaiting these before runApp() used to hold
  // the native launch screen up behind a system dialog the user couldn't
  // even see the app underneath — SplashScreen's own branding now shows
  // immediately, and these finish in the background instead.
  unawaited(_finishBackgroundStartup());
}

Future<void> _finishBackgroundStartup() async {
  await NotificationService.instance.requestPermissions();
  if (SettingsService.instance.notificationsEnabled) {
    for (final habit in await IsarService.instance.getAllHabits()) {
      await NotificationService.instance.scheduleRemindersForHabit(habit);
    }
  }

  await AdService.instance.init();

  // Dynamic app icon (PRD §9) — re-evaluated on every launch. Fire-and-forget:
  // AppIconService never throws, and a slightly-stale icon for one frame
  // isn't worth delaying startup over.
  unawaited(AppIconService.instance.refreshIcon());
  unawaited(registerDailyIconRefresh());
}

class HabitQuestApp extends StatelessWidget {
  const HabitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitQuest',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
