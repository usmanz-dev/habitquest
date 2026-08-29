import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cosmetics.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class _ShopItem {
  const _ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final String emoji;
}

/// Cosmetics (HabitQuest_PRD.md §7 screen 11) — ownership persists in
/// [UserProgress.ownedCosmeticIds] and every owned effect actually renders:
/// `neon_trail`/`golden_frame`/`rainbow_glow` on [AvatarDisplay] (Home +
/// Avatar Profile), `confetti_burst` on [HabitCard] check-off, and
/// `starry_backdrop` behind the Avatar Profile's avatar. These ids are the
/// single source of truth other widgets key off of — keep them in sync if
/// you rename/add an item.
const List<_ShopItem> _kShopItems = [
  _ShopItem(id: CosmeticIds.neonTrail, name: 'Neon Trail', description: 'A glowing trail behind your avatar', cost: 50, emoji: '✨'),
  _ShopItem(id: CosmeticIds.goldenFrame, name: 'Golden Frame', description: 'A shimmering ring around your avatar', cost: 80, emoji: '🖼️'),
  _ShopItem(id: CosmeticIds.confettiBurst, name: 'Confetti Burst', description: 'Extra confetti on habit completion', cost: 40, emoji: '🎉'),
  _ShopItem(id: CosmeticIds.starryBackdrop, name: 'Starry Backdrop', description: 'A cosmic background for your profile', cost: 60, emoji: '🌌'),
  _ShopItem(id: CosmeticIds.rainbowGlow, name: 'Rainbow Glow', description: 'Cycles the avatar glow through colors', cost: 100, emoji: '🌈'),
];

/// Shop/Rewards Screen (HabitQuest_PRD.md §7 screen 11): spend Gold on
/// cosmetics. The Secret Premium Avatar (Rewarded-Ad unlock) is skipped here
/// for now — [IsarService.unlockPremiumAvatar] and [LevelingService]'s
/// premium-stage gating stay in place so it can come back later.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  Future<void> _buy(_ShopItem item) async {
    final success =
        await ref.read(userProgressProvider.notifier).purchaseCosmetic(item.id, item.cost);
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough gold for that yet.')),
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
            Text('Cosmetics', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            for (final item in _kShopItems) ...[
              _ShopItemCard(
                item: item,
                owned: progress.ownedCosmeticIds.contains(item.id),
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
