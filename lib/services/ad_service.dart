import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Every AdMob-triggered moment in HabitQuest_PRD.md §10, backed by real
/// google_mobile_ads calls against HabitQuest's live ad units.
///
/// Every load/show path is wrapped so a failed or slow ad network never
/// crashes the app: banners just don't appear, interstitials silently no-op,
/// and rewarded calls resolve to `false` (never granting the reward) rather
/// than throwing. This also covers newly-created ad units, which can take
/// up to ~1 hour after creation before AdMob starts serving fill for them
/// (https://support.google.com/admob/answer/9298008) — until then, loads
/// just fail like any other no-fill and degrade the same way.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // HabitQuest's live AdMob ad units — real money, real policy rules apply.
  // Never tap/watch these from a dev or CI device; register that device's
  // ID in the AdMob console as a test device first, or swap in the test
  // constants commented out below while developing.
  static const String bannerAdUnitId = 'ca-app-pub-2251790822906209/9684700701';
  static const String interstitialAdUnitId = 'ca-app-pub-2251790822906209/8650770300';
  static const String rewardedAdUnitId = 'ca-app-pub-2251790822906209/5641463584';

  // Google's official test ad units — always fill, never show real (or
  // policy-risky) creatives, safe to tap/watch from any device.
  // https://developers.google.com/admob/android/test-ads
  // static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  // static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  // static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static const Duration _rewardedTimeout = Duration(seconds: 20);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (error, stack) {
      debugPrint('[AdService] MobileAds.initialize failed: $error\n$stack');
    }
  }

  /// Rewarded ad — instant unlock of the Secret Premium Avatar (§5.3, §7
  /// screen 11). Resolves true only from the SDK's `onUserEarnedReward`
  /// callback (i.e. the ad was watched to completion), never merely because
  /// the ad was closed.
  Future<bool> showRewardedAdForAvatarUnlock() => _showRewardedAd();

  /// Rewarded ad — protects the streak after a missed day (§7 screen 12).
  /// Same "reward callback, not just close" guarantee as above.
  Future<bool> showRewardedAdForStreakFreeze() => _showRewardedAd();

  Future<bool> _showRewardedAd() async {
    final completer = Completer<bool>();

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                // If onUserEarnedReward already completed this with `true`,
                // this is a no-op — earned-reward always wins over a later close.
                if (!completer.isCompleted) completer.complete(false);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdService] Rewarded ad failed to show: $error');
                ad.dispose();
                if (!completer.isCompleted) completer.complete(false);
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) {
                if (!completer.isCompleted) completer.complete(true);
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              '[AdService] Rewarded ad failed to load: $error '
              '(if this ad unit is brand new, it can take up to ~1h to start serving)',
            );
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (error, stack) {
      debugPrint('[AdService] Rewarded ad load threw: $error\n$stack');
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future.timeout(_rewardedTimeout, onTimeout: () => false);
  }

  /// Interstitial ad — shown once, exactly when the user completes every
  /// habit for the day (§3, §7 screen 13, §10). Never shown mid-task or
  /// while a text field has focus — the Day Complete screen only calls
  /// this from its own `initState`, so that constraint holds by construction.
  Future<void> showInterstitialOnDayComplete() async {
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) => ad.dispose(),
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdService] Interstitial failed to show: $error');
                ad.dispose();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              '[AdService] Interstitial failed to load: $error '
              '(if this ad unit is brand new, it can take up to ~1h to start serving)',
            );
          },
        ),
      );
    } catch (error, stack) {
      debugPrint('[AdService] Interstitial load threw: $error\n$stack');
    }
  }
}
