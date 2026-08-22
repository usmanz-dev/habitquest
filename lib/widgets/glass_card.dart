import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A frosted-glass card: blurs whatever sits behind it, tinted with a
/// white overlay over the surface color (§6.2 "Elevated/glass card").
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppRadius.card,
    this.overlayOpacity = 0.12,
    this.blurSigma = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// White overlay strength blended into the surface color. §6.2 specifies 10–15%.
  final double overlayOpacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: overlayOpacity + 0.03),
                  AppColors.surface,
                ),
                Color.alphaBlend(
                  Colors.white.withValues(alpha: overlayOpacity - 0.03),
                  AppColors.surface,
                ),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
