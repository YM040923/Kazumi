import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop window actions avoid duplicate controls on discover', () {
    final controlsSource =
        File('lib/bean/appbar/desktop_window_controls.dart').readAsStringSync();
    final sysAppBarSource =
        File('lib/bean/appbar/sys_app_bar.dart').readAsStringSync();
    final popularSource =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();
    final infoSource = File('lib/pages/info/info_page.dart').readAsStringSync();

    for (final marker in [
      'class DesktopWindowControls',
      'class DesktopWindowActionRail',
      'WindowControlMetrics.buttonWidth',
      'WindowControlMetrics.controlHeight',
      'windowManager.minimize()',
      'windowManager.isMaximized()',
      'windowManager.maximize()',
      'windowManager.unmaximize()',
      'windowManager.close()',
    ]) {
      expect(controlsSource, contains(marker));
    }

    expect(sysAppBarSource, contains('DesktopWindowActionRail'));

    expect(popularSource, isNot(contains('DesktopWindowActionRail')));
    expect(popularSource, contains('WindowControlInset'));
    expect(infoSource, isNot(contains('DesktopWindowActionRail')));
    expect(infoSource, contains('WindowControlInset'));
    expect(popularSource, isNot(contains('windowManager.close()')));
    expect(infoSource, isNot(contains('windowManager.close()')));
    expect(sysAppBarSource, isNot(contains('CloseButton(')));
  });
}
