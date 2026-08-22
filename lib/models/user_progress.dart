import 'package:isar/isar.dart';

part 'user_progress.g.dart';

/// Single-row collection holding the user's overall progress. Always
/// stored/fetched at a fixed id of 0 — see IsarService.getUserProgress.
@collection
class UserProgress {
  Id id = 0;

  int totalXP = 0;
  int totalGold = 0;
  int currentHP = 100;
  int currentStreak = 0;
  int longestStreak = 0;
  int currentAvatarLevel = 1;

  /// Golden Phoenix unlock (HabitQuest_PRD.md §5.3/§10) — earned via
  /// Rewarded Ad in the Shop, not by leveling.
  bool premiumAvatarUnlocked = false;

  /// Cosmetic ids purchased in the Shop (HabitQuest_PRD.md §7 screen 11) —
  /// see ShopScreen's `_kShopItems` for the id list. All owned cosmetics
  /// render simultaneously (they're independent visual layers, not
  /// mutually exclusive skins), so there's no separate "equipped" state.
  List<String> ownedCosmeticIds = [];
}
