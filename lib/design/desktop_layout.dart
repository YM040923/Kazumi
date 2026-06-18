import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kazumi/design/adaptive_layout.dart';

class KazumiDesktopShell {
  KazumiDesktopShell._();

  static const double sidebarWidth = 86;
  static const double pageMaxWidth = 920;
  static const double mediaPageMaxWidth = 1560;
  static const double pageHorizontalPadding = 24;

  static double contentMaxWidthFor(double viewportWidth) {
    if (viewportWidth >= pageMaxWidth + pageHorizontalPadding * 2) {
      return pageMaxWidth;
    }
    return viewportWidth;
  }
}

class KazumiDesktopPageFrame extends StatelessWidget {
  const KazumiDesktopPageFrame({
    super.key,
    required this.child,
    this.horizontalPadding,
    this.maxWidth = KazumiDesktopShell.pageMaxWidth,
  });

  final Widget child;
  final double? horizontalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = KazumiPageMetrics.fromViewport(
          width: constraints.maxWidth,
          height: MediaQuery.sizeOf(context).height,
          maxContentWidth: maxWidth,
        );
        final resolvedHorizontalPadding = horizontalPadding ?? metrics.gutter;
        final availableWidth =
            math.max(0.0, constraints.maxWidth - resolvedHorizontalPadding * 2);
        final frameWidth = math.min(maxWidth, availableWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: resolvedHorizontalPadding),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: frameWidth,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
