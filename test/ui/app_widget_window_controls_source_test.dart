import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop window controls overlay is built inside MaterialApp builder',
      () {
    final source = File('lib/app_widget.dart').readAsStringSync();

    expect(source, contains('builder: (context, child)'));
    expect(source, contains('debugShowCheckedModeBanner: false'));
    expect(source, contains('DesktopWindowControlsOverlay('));
    expect(source, contains('child: child ?? const SizedBox.shrink()'));
    expect(source,
        isNot(contains('return DesktopWindowControlsOverlay(child: app);')));
  });

  test('appearance settings synchronizes native and custom window buttons', () {
    final source =
        File('lib/pages/settings/theme_settings_page.dart').readAsStringSync();

    expect(source, contains('windowManager.setTitleBarStyle'));
    expect(source, contains('TitleBarStyle.normal'));
    expect(source, contains('TitleBarStyle.hidden'));
    expect(source, contains('windowButtonVisibility: showWindowButton'));
  });
}
