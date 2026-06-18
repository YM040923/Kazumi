import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop window actions use a shared right rail', () {
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

    for (final source in [sysAppBarSource, popularSource, infoSource]) {
      expect(source, contains('DesktopWindowActionRail'));
    }

    expect(popularSource, isNot(contains('windowManager.close()')));
    expect(infoSource, isNot(contains('windowManager.close()')));
    expect(sysAppBarSource, isNot(contains('CloseButton(')));
  });
}
