import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Local reminder notifications (HabitQuest_PRD.md §8) — everything runs
/// on-device via flutter_local_notifications, no server/push service.
///
/// Two kinds of scheduled notification per habit:
/// - **Reminder**: one per [Habit.reminderTimes] entry, fired
///   [reminderLeadMinutes] before that time, recurring (daily, or weekly on
///   the habit's specific days). Set-and-forget once scheduled — only needs
///   rescheduling when the habit itself changes.
/// - **Last chance**: one per habit *per day*, fired later in the day
///   (see [lastChanceTime]) only if the habit is still incomplete. Local
///   notifications can't run Dart code to check completion at fire time,
///   so this is scheduled as a one-time "today" notification each time the
///   day's habit list is refreshed, and cancelled immediately if the habit
///   gets completed before it fires (see [cancelLastChance]). This means it
///   reliably fires as long as the app is opened at least once that day.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';

  /// When "last chance" notifications fire, for habits still incomplete.
  static const int lastChanceHour = 21;
  static const int lastChanceMinute = 0;

  /// How long before a habit's set time its reminder notification fires.
  static const int reminderLeadMinutes = 10;

  /// Root-level navigator, used so a notification tap can return to the
  /// Home Screen from anywhere in the app (§8: "tapping opens Home Screen").
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Falls back to tz.UTC if the platform timezone can't be resolved.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) => _openHomeScreen(),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for your HabitQuest habits',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _openHomeScreen() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Requests the Android 13+ POST_NOTIFICATIONS runtime permission, plus
  /// exact-alarm scheduling permission on Android 12+ (needed for reminders
  /// to fire at the precise minute rather than a batched/delayed window).
  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders for your HabitQuest habits',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ---- Scheduling helpers ----

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Parses an "HH:mm" habit time and returns (hour, minute) shifted
  /// [reminderLeadMinutes] earlier — the reminder fires *before* the habit's
  /// set time (HabitQuest_PRD.md §8), giving the user a heads-up to get ready.
  (int, int) _leadTimeFor(String hhmm) {
    final parts = hhmm.split(':');
    final totalMinutes =
        int.parse(parts[0]) * 60 + int.parse(parts[1]) - reminderLeadMinutes;
    final wrapped = (totalMinutes % (24 * 60) + 24 * 60) % (24 * 60);
    return (wrapped ~/ 60, wrapped % 60);
  }

  int _idFor(int habitId, int a, int b) =>
      Object.hash(habitId, a, b) & 0x7fffffff;

  // ---- Reminders (per habit's reminderTimes) ----

  /// (Re)schedules every reminder notification for [habit], replacing
  /// whatever was previously scheduled for it. Call this whenever a habit
  /// is created or edited.
  Future<void> scheduleRemindersForHabit(Habit habit) async {
    await cancelRemindersForHabit(habit.id);

    for (var i = 0; i < habit.reminderTimes.length; i++) {
      final (hour, minute) = _leadTimeFor(habit.reminderTimes[i]);
      final payload = 'reminder:${habit.id}';
      final title = 'Get ready!';
      final body = '"${habit.name}" starts in $reminderLeadMinutes minutes.';

      if (habit.frequencyType == FrequencyType.specificDays &&
          habit.specificDays.isNotEmpty) {
        for (final weekday in habit.specificDays) {
          await _plugin.zonedSchedule(
            id: _idFor(habit.id, i, weekday),
            title: title,
            body: body,
            scheduledDate: _nextInstanceOfWeekdayTime(weekday, hour, minute),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      } else {
        await _plugin.zonedSchedule(
          id: _idFor(habit.id, i, 0),
          title: title,
          body: body,
          scheduledDate: _nextInstanceOfTime(hour, minute),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      }
    }
  }

  /// Cancels every reminder notification (not the last-chance one) for
  /// [habitId], by scanning pending requests for its payload — avoids
  /// having to guess how many were scheduled last time.
  Future<void> cancelRemindersForHabit(int habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload == 'reminder:$habitId') {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  // ---- Last chance (once per habit per day) ----

  int _lastChanceId(int habitId) => _idFor(habitId, 1 << 20, 0);

  /// Schedules today's "last chance" notification for [habit] if it isn't
  /// completed yet and the time hasn't already passed; cancels it if the
  /// habit is already completed. Call whenever the day's habit list (and
  /// completion state) is refreshed.
  Future<void> scheduleOrCancelLastChance(
    Habit habit, {
    required bool completedToday,
  }) async {
    final id = _lastChanceId(habit.id);
    if (completedToday) {
      await _plugin.cancel(id: id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      lastChanceHour,
      lastChanceMinute,
    );
    if (today.isBefore(now)) {
      // Already past today's last-chance time — nothing to schedule until
      // the next refresh picks a future day.
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'Last chance today!',
      body: '"${habit.name}" is still incomplete.',
      scheduledDate: today,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'lastchance:${habit.id}',
    );
  }

  /// Cancels today's last-chance notification the moment [habitId] is
  /// completed, so it doesn't fire later even though it was scheduled.
  Future<void> cancelLastChance(int habitId) =>
      _plugin.cancel(id: _lastChanceId(habitId));

  // ---- Delete ----

  /// Cancels everything scheduled for [habitId] — reminders and last
  /// chance. Call when a habit is deleted.
  Future<void> cancelAllForHabit(int habitId) async {
    await cancelRemindersForHabit(habitId);
    await cancelLastChance(habitId);
  }

  /// Cancels every scheduled notification — used when the user turns
  /// notifications off in Settings, or resets all data.
  Future<void> cancelAll() => _plugin.cancelAll();
}
