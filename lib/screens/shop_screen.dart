import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ad_service.dart';
import '../services/leveling_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class _ShopItem {
  const _ShopItem({
    required this.name,
    required this.description,
    required this.cost,
    required this.emoji,
  });

  final String name;
  final String description;
  final int cost;
  final String emoji;
}

/// Placeholder cosmetics (HabitQuest_PRD.md §7 screen 11) — not yet backed
/// by their own Isar collection, so "owned" only tracks for this session.
const List<_ShopItem> _kShopItems = [
  _ShopItem(name: 'Neon Trail', description: 'A glowing trail behind your avatar', cost: 50, emoji: '✨'),
  _ShopItem(name: 'Golden Frame', description: 'A shimmering ring around your avatar', cost: 80, emoji: '🖼️'),
  _ShopItem(name: 'Confetti Burst', description: 'Extra confetti on habit completion', cost: 40, emoji: '🎉'),
  _ShopItem(name: 'Starry Backdrop', description: 'A cosmic background for your profile', cost: 60, emoji: '🌌'),
  _ShopItem(name: 'Rainbow Glow', description: 'Cycles the avatar glow through colors', cost: 100, emoji: '🌈'),
];

/// Shop/Rewards Screen (HabitQuest_PRD.md §7 screen 11): spend Gold on
/// cosmetics, or unlock the Secret Premium Avatar with a Rewarded Ad.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final Set<String> _purchasedThisSession = {};
  bool _unlockingPremium = false;

  Future<void> _buy(_ShopItem item) async {
    final success = await ref.read(userProgressProvider.notifier).spendGold(item.cost);
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      setState(() => _purchasedThisSession.add(item.name));
    } else {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough gold for that yet.')),
      );
    }
  }

  Future<void> _unlockPremiumAvatar() async {
    setState(() => _unlockingPremium = true);
    final earned = await AdService.instance.showRewardedAdForAvatarUnlock();
    if (!mounted) return;

    setState(() => _unlockingPremium = false);
    if (earned) {
      HapticFeedback.heavyImpact();
      await ref.read(userProgressProvider.notifier).unlockPremiumAvatar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Golden Phoenix unlocked!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(userProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Shop', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Balance', style: AppTypography.bodyMedium),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: AppColors.amberStart, size: 22),
                      const SizedBox(width: 6),
                      Text('${progress.totalGold}', style: AppTypography.headingLarge),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Secret Premium Avatar', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            _PremiumAvatarCard(
              unlocked: progress.premiumAvatarUnlocked,
              working: _unlockingPremium,
              onUnlock: _unlockPremiumAvatar,
            ),
            const SizedBox(height: 28),
            Text('Cosmetics', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            for (final item in _kShopItems) ...[
              _ShopItemCard(
                item: item,
                owned: _purchasedThisSession.contains(item.name),
                canAfford: progress.totalGold >= item.cost,
                onBuy: () => _buy(item),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumAvatarCard extends StatelessWidget {
  const _PremiumAvatarCard({
    required this.unlocked,
    required this.working,
    required this.onUnlock,
  });

  final bool unlocked;
  final bool working;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final stage = AvatarStage.goldenPhoenix;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(color: AppColors.amberStart.withValues(alpha: 0.35), blurRadius: 28),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Image.asset(stage.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.displayName,
                  style: AppTypography.headingMedium.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked ? 'Unlocked' : 'Unlock instantly with a Rewarded Ad',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: Colors.black87, size: 28)
          else
            ElevatedButton(
              onPressed: working ? null : onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: Text(working ? 'Loading…' : 'Unlock with Ad'),
            ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  final _ShopItem item;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.headingMedium),
                const SizedBox(height: 2),
                Text(item.description, style: AppTypography.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (owned)
            Icon(Icons.check_circle_rounded, color: AppColors.successStart, size: 26)
          else
            ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              child: Text('${item.cost}g'),
            ),
        ],
      ),
    );
  }
}
