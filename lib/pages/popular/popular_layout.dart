double popularPosterGridGap(double contentWidth) {
  if (contentWidth >= 1400) return 16;
  if (contentWidth >= 980) return 14;
  return 12;
}

double popularPosterGridTextHeight(double contentWidth) {
  if (contentWidth < 640) return 54;
  return 58;
}

double popularPosterAspectRatio(double contentWidth) {
  return 0.68;
}

int popularPosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1560) return 8;
  if (contentWidth >= 1320) return 7;
  if (contentWidth >= 1100) return 6;
  if (contentWidth >= 860) return 5;
  if (contentWidth >= 620) return 4;
  return 3;
}

List<T> popularGridItemsExcludingSpotlight<T>(
  List<T> items, {
  required int spotlightStart,
  required int spotlightSize,
}) {
  if (items.length <= spotlightSize) return items;
  final end = spotlightStart + spotlightSize;
  return [
    for (var i = 0; i < items.length; i++)
      if (i < spotlightStart || i >= end) items[i],
  ];
}

List<T> spotlightWindowFor<T>(
  List<T> items, {
  required int start,
  required int size,
}) {
  if (items.length <= size) return items;
  final safeStart = start.clamp(0, items.length - 1);
  final end = (safeStart + size).clamp(0, items.length);
  return items.sublist(safeStart, end);
}

int nextSpotlightIndex({
  required int currentIndex,
  required int itemCount,
}) {
  if (itemCount <= 1) return 0;
  return (currentIndex + 1) % itemCount;
}

int nextSpotlightPageStart({
  required int currentStart,
  required int itemCount,
  required int windowSize,
}) {
  if (itemCount <= windowSize) return 0;
  final nextStart = currentStart + windowSize;
  return nextStart >= itemCount ? 0 : nextStart;
}
