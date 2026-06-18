import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kazumi/design/design_tokens.dart';

class KazumiGlassTokens {
  KazumiGlassTokens._();

  static const double panelBlurSigma = 30;
  static const double panelOpacity = 0.58;
  static const double highlightOpacity = 0.26;
  static const double buttonOpacity = 0.46;

  static BorderSide glassBorder(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BorderSide(
      color: (isDark ? Colors.white : scheme.primary)
          .withValues(alpha: isDark ? 0.13 : 0.11),
      width: 1,
    );
  }
}

class KazumiGlassSurface extends StatelessWidget {
  const KazumiGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blurSigma = KazumiGlassTokens.panelBlurSigma,
    this.opacity = KazumiGlassTokens.panelOpacity,
    this.clipBehavior = Clip.antiAlias,
    this.showShadow = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double opacity;
  final Clip clipBehavior;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? KazumiRadius.panelBorder;
    final baseColor = isDark ? scheme.surfaceContainerLow : scheme.surface;

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.fromBorderSide(
              KazumiGlassTokens.glassBorder(scheme, theme.brightness),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(
                  alpha: isDark ? 0.08 : KazumiGlassTokens.highlightOpacity,
                ),
                scheme.surfaceTint.withValues(alpha: isDark ? 0.10 : 0.07),
                baseColor.withValues(alpha: opacity),
              ],
              stops: const [0, 0.36, 1],
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color:
                          scheme.shadow.withValues(alpha: isDark ? 0.28 : 0.10),
                      blurRadius: isDark ? 28 : 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.03 : 0.34),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
