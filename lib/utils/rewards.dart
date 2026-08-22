/// Base reward values for completing a habit. HabitQuest_PRD.md §5 defines
/// the currencies (XP, Gold, HP, Streak) but not exact tuning numbers, so
/// these are placeholder MVP values — expect them to move to Remote Config
/// or a balancing pass later (see PRD §11).
const int kXpPerCompletion = 10;
const int kGoldPerCompletion = 5;

/// HP heals when a habit is completed — it's the mood meter that missed
/// habits drain (§5.1), so finishing habits is what restores it.
const int kHpRegenPerCompletion = 2;
const int kMaxHp = 100;
