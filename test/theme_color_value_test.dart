import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/settings/color_type.dart';

void main() {
  test('stored theme color supports media presets and legacy hex values', () {
    expect(resolveStoredThemeColor('default'), Colors.green);
    expect(resolveStoredThemeColor('ff2196f3'), const Color(0xff2196f3));
    expect(
      resolveStoredThemeColor('preset:blueCinema'),
      mediaThemePresetSeeds['blueCinema'],
    );
  });

  test('stored theme color falls back instead of throwing on invalid values',
      () {
    expect(resolveStoredThemeColor('preset:missing'), Colors.green);
    expect(resolveStoredThemeColor('not-a-hex-color'), Colors.green);
  });
}
