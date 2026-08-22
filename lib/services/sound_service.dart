import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// The 4 gamification sound effects (HabitQuest_PRD.md §5.4, §3).
enum AppSound { habitCheck, levelUp, habitMissed, dayComplete }

extension on AppSound {
  String get assetPath => switch (this) {
        AppSound.habitCheck => 'sounds/sound_habit_check.wav',
        AppSound.levelUp => 'sounds/sound_level_up.wav',
        AppSound.habitMissed => 'sounds/sound_habit_missed.wav',
        AppSound.dayComplete => 'sounds/sound_day_complete.wav',
      };
}

/// Plays short gamification sound effects, muted whenever
/// [SettingsService.soundEnabled] is off. Uses [PlayerMode.lowLatency]
/// (SoundPool on Android) since these are quick one-shot SFX rather than
/// background media, so overlapping calls (e.g. a habit check that also
/// completes the day) don't cut each other off.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const double _volume = 0.6;

  final AudioPlayer _player = AudioPlayer(playerId: 'habitquest_sfx')
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  Future<void> play(AppSound sound) async {
    if (!SettingsService.instance.soundEnabled) return;
    try {
      await _player.play(AssetSource(sound.assetPath), volume: _volume);
    } catch (error, stack) {
      // A missing/broken audio asset should never break the app flow.
      debugPrint('[SoundService] Failed to play ${sound.name}: $error\n$stack');
    }
  }
}
