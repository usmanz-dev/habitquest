import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-level preferences (HabitQuest_PRD.md §7 screen 14).
/// [soundEnabled] gates every [SoundService] call — off mutes all 4
/// gamification sound effects.
class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _notificationsKey = 'settings.notificationsEnabled';
  static const _soundKey = 'settings.soundEnabled';
  static const _onboardingCompleteKey = 'settings.hasCompletedOnboarding';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get notificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;

  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;

  /// Whether the user has been through Onboarding (HabitQuest_PRD.md §7
  /// screens 2-4) at least once — SplashScreen reads this to decide
  /// whether to route there or straight to Home.
  bool get hasCompletedOnboarding => _prefs.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setNotificationsEnabled(bool value) => _prefs.setBool(_notificationsKey, value);

  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_soundKey, value);

  Future<void> setOnboardingCompleted(bool value) => _prefs.setBool(_onboardingCompleteKey, value);
}
