double timelinePosterGridGap(double contentWidth) {
  if (contentWidth >= 1280) return 16;
  if (contentWidth >= 840) return 14;
  return 12;
}

double timelinePosterTextHeight(double contentWidth) {
  if (contentWidth < 640) return 56;
  return 60;
}

int timelinePosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1480) return 8;
  if (contentWidth >= 1240) return 7;
  if (contentWidth >= 1020) return 6;
  if (contentWidth >= 800) return 5;
  if (contentWidth >= 580) return 4;
  return 3;
}
