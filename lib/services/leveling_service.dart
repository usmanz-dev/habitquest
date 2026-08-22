/// The 5 avatar stages from HabitQuest_PRD.md §5.3. The first 4 are unlocked
/// purely by level; [goldenPhoenix] is explicitly "Secret Premium — unlocked
/// via Rewarded Ad", not by XP, so [LevelingService.stageForLevel] only ever
/// returns it when told the ad-unlock has happened.
enum AvatarStage { babyRobot, ironWarrior, shadowNinja, cyberMage, goldenPhoenix }

extension AvatarStageInfo on AvatarStage {
  String get displayName => switch (this) {
        AvatarStage.babyRobot => 'Baby Robot',
        AvatarStage.ironWarrior => 'Iron Warrior',
        AvatarStage.shadowNinja => 'Shadow Ninja',
        AvatarStage.cyberMage => 'Cyber Mage',
        AvatarStage.goldenPhoenix => 'Golden Phoenix',
      };

  String get assetPath => switch (this) {
        AvatarStage.babyRobot => 'assets/images/avatars/avatar_1_baby_robot.png',
        AvatarStage.ironWarrior => 'assets/images/avatars/avatar_2_iron_warrior.png',
        AvatarStage.shadowNinja => 'assets/images/avatars/avatar_3_shadow_ninja.png',
        AvatarStage.cyberMage => 'assets/images/avatars/avatar_4_cyber_mage.png',
        AvatarStage.goldenPhoenix => 'assets/images/avatars/avatar_5_golden_phoenix.png',
      };
}

/// XP -> level -> avatar stage, entirely driven by cumulative total XP
/// (HabitQuest_PRD.md §5.2): leveling never reads streak or HP, so a missed
/// habit — which only drains HP (§5.1) and plays the temporary sad animation
/// (§5.4) — can never subtract XP or roll back a level or avatar stage.
/// [UserProgress.totalXP] is only ever incremented (see IsarService
/// .applyHabitCompletionRewards), which is what makes that guarantee hold.
class LevelingService {
  LevelingService._();

  /// XP curve anchors: how much *cumulative* XP is needed to reach the three
  /// avatar-evolution milestone levels (§5.3). Between anchors the curve is
  /// piecewise-linear, getting steeper at each milestone — an MVP pacing
  /// placeholder (see PRD §11 on future balancing), not from the PRD itself.
  static const int xpForLevel5 = 500; // Iron Warrior
  static const int xpForLevel15 = 3000; // Shadow Ninja
  static const int xpForLevel30 = 10050; // Cyber Mage

  static const int _step1To5 = xpForLevel5 ~/ 4; // 125 XP/level, levels 1-5
  static const int _step5To15 = (xpForLevel15 - xpForLevel5) ~/ 10; // 250 XP/level, levels 5-15
  static const int _step15Plus = (xpForLevel30 - xpForLevel15) ~/ 15; // 470 XP/level, levels 15+

  /// Cumulative XP required to *reach* [level] (level 1 = 0).
  static int xpThresholdForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= 5) return (level - 1) * _step1To5;
    if (level <= 15) return xpForLevel5 + (level - 5) * _step5To15;
    return xpForLevel15 + (level - 15) * _step15Plus;
  }

  /// The level reached by [totalXp] (never decreases as XP only accumulates).
  static int levelForXp(int totalXp) {
    if (totalXp < xpForLevel5) return 1 + totalXp ~/ _step1To5;
    if (totalXp < xpForLevel15) return 5 + (totalXp - xpForLevel5) ~/ _step5To15;
    return 15 + (totalXp - xpForLevel15) ~/ _step15Plus;
  }

  /// Which of the 5 avatar stages should display for [level]. [premiumUnlocked]
  /// is the Rewarded-Ad flag from §10 — not implemented yet, so callers that
  /// don't have it should just omit it and get the level-based stage.
  static AvatarStage stageForLevel(int level, {bool premiumUnlocked = false}) {
    if (premiumUnlocked) return AvatarStage.goldenPhoenix;
    if (level >= 30) return AvatarStage.cyberMage;
    if (level >= 15) return AvatarStage.shadowNinja;
    if (level >= 5) return AvatarStage.ironWarrior;
    return AvatarStage.babyRobot;
  }

  /// Level + stage + in-level progress for [totalXp], in one call.
  static LevelInfo levelInfoForXp(int totalXp, {bool premiumUnlocked = false}) {
    final level = levelForXp(totalXp);
    final currentThreshold = xpThresholdForLevel(level);
    final nextThreshold = xpThresholdForLevel(level + 1);
    return LevelInfo(
      level: level,
      stage: stageForLevel(level, premiumUnlocked: premiumUnlocked),
      xpIntoLevel: totalXp - currentThreshold,
      xpForNextLevel: nextThreshold - currentThreshold,
    );
  }
}

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.stage,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  final int level;
  final AvatarStage stage;

  /// XP earned since hitting [level].
  final int xpIntoLevel;

  /// Total XP needed within [level] to reach the next one.
  final int xpForNextLevel;

  double get progress => xpForNextLevel == 0 ? 1 : xpIntoLevel / xpForNextLevel;
}
