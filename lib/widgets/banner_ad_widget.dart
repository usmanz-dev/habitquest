import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// The AdMob banner persistent at the bottom of the Home Screen and
/// Progress Screen (HabitQuest_PRD.md §10). Loads its own [BannerAd] and
/// disposes it with the widget; if the ad fails to load (no network, no
/// fill, ad blocked, etc.) this just renders an empty themed strip instead
/// of crashing or leaving a broken widget on screen.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[BannerAdWidget] failed to load: $error '
            '(if this ad unit is brand new, it can take up to ~1h to start serving)',
          );
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    return Container(
      width: double.infinity,
      height: ad?.size.height.toDouble() ?? 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: ad == null ? null : AdWidget(ad: ad),
    );
  }
}
