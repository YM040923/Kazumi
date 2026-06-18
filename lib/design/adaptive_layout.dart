import 'dart:math' as math;

enum KazumiWindowClass {
  compact,
  medium,
  wide,
  ultrawide;

  static KazumiWindowClass forWidth(double width) {
    if (width >= 1440) return KazumiWindowClass.ultrawide;
    if (width >= 1100) return KazumiWindowClass.wide;
    if (width >= 760) return KazumiWindowClass.medium;
    return KazumiWindowClass.compact;
  }
}

class KazumiPageMetrics {
  const KazumiPageMetrics({
    required this.viewportWidth,
    required this.viewportHeight,
    required this.windowClass,
    required this.gutter,
    required this.contentWidth,
  });

  final double viewportWidth;
  final double viewportHeight;
  final KazumiWindowClass windowClass;
  final double gutter;
  final double contentWidth;

  bool get isCompact => windowClass == KazumiWindowClass.compact;
  bool get isMediumOrLarger =>
      windowClass.index >= KazumiWindowClass.medium.index;
  bool get isWideOrLarger => windowClass.index >= KazumiWindowClass.wide.index;

  int get mediaColumns {
    return switch (windowClass) {
      KazumiWindowClass.compact => 2,
      KazumiWindowClass.medium => 3,
      KazumiWindowClass.wide => 5,
      KazumiWindowClass.ultrawide => 5,
    };
  }

  double get dialogMaxWidth {
    return switch (windowClass) {
      KazumiWindowClass.compact => viewportWidth,
      KazumiWindowClass.medium => math.min(720, viewportWidth - gutter * 2),
      KazumiWindowClass.wide => math.min(860, viewportWidth - gutter * 2),
      KazumiWindowClass.ultrawide => math.min(920, viewportWidth - gutter * 2),
    };
  }

  double get dialogMaxHeight {
    return switch (windowClass) {
      KazumiWindowClass.compact => viewportHeight,
      _ => viewportHeight * 0.82,
    };
  }

  factory KazumiPageMetrics.fromViewport({
    required double width,
    required double height,
    double maxContentWidth = 1560,
  }) {
    final windowClass = KazumiWindowClass.forWidth(width);
    final gutter = switch (windowClass) {
      KazumiWindowClass.compact => 16.0,
      KazumiWindowClass.medium => 24.0,
      KazumiWindowClass.wide => 28.0,
      KazumiWindowClass.ultrawide => 32.0,
    };
    final availableWidth = math.max(0.0, width - gutter * 2);

    return KazumiPageMetrics(
      viewportWidth: width,
      viewportHeight: height,
      windowClass: windowClass,
      gutter: gutter,
      contentWidth: math.min(maxContentWidth, availableWidth),
    );
  }
}
