double timelinePosterGridGap(double contentWidth) {
  if (contentWidth >= 1280) return 22;
  if (contentWidth >= 840) return 18;
  return 12;
}

double timelinePosterTextHeight(double contentWidth) {
  if (contentWidth < 640) return 56;
  return 60;
}

int timelinePosterGridColumnCount(double contentWidth) {
  if (contentWidth >= 1500) return 9;
  if (contentWidth >= 1320) return 8;
  if (contentWidth >= 1120) return 7;
  if (contentWidth >= 920) return 6;
  if (contentWidth >= 720) return 5;
  if (contentWidth >= 580) return 4;
  return 3;
}
