double popularPosterGridGap(double contentWidth) {
  if (contentWidth >= 1400) return 16;
  if (contentWidth >= 980) return 14;
  return 12;
}

double popularPosterGridTextHeight(double contentWidth) {
  if (contentWidth < 640) return 54;
  return 58;
}

int popularPosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1560) return 8;
  if (contentWidth >= 1320) return 7;
  if (contentWidth >= 1100) return 6;
  if (contentWidth >= 860) return 5;
  if (contentWidth >= 620) return 4;
  return 3;
}
