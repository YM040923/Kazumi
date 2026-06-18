import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class KazumiDesktopShell {
  KazumiDesktopShell._();

  static const double sidebarWidth = 86;
  static const double pageMaxWidth = 920;
  static const double mediaPageMaxWidth = 1180;
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
    this.horizontalPadding = KazumiDesktopShell.pageHorizontalPadding,
    this.maxWidth = KazumiDesktopShell.pageMaxWidth,
  });

  final Widget child;
  final double horizontalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            math.max(0.0, constraints.maxWidth - horizontalPadding * 2);
        final frameWidth = math.min(maxWidth, availableWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
