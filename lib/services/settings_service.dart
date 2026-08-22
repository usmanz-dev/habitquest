import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-level preferences (HabitQuest_PRD.md §7 screen 14).
/// [soundEnabled] gates every [SoundService] call — off mutes all 4
/// gamification sound effects.
class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _notificationsKey = 'settings.notificationsEnabled';
  static const _soundKey = 'settings.soundEnabled';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get notificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;

  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;

  Future<void> setNotificationsEnabled(bool value) => _prefs.setBool(_notificationsKey, value);

  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_soundKey, value);
}
