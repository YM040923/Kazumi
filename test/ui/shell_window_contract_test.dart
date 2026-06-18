import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop shell restores placement and avoids duplicate entry points',
      () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final appWidgetSource = File('lib/app_widget.dart').readAsStringSync();
    final menuSource = File('lib/pages/menu/menu.dart').readAsStringSync();
    final infoSource = File('lib/pages/info/info_page.dart').readAsStringSync();

    expect(
        mainSource, contains('_initialDesktopWindowSize(initialWindowSize)'));
    expect(mainSource, contains('_initialDesktopWindowPosition()'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowWidth'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowHeight'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowX'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowY'));
    expect(mainSource, contains('SettingBoxKey.desktopWindowMaximized'));
    expect(mainSource, contains('windowManager.setPosition'));
    expect(mainSource, contains('windowManager.maximize'));
    expect(mainSource, contains('UiVerification.isEnabled'));

    expect(appWidgetSource, contains('_persistDesktopWindowPlacement'));
    expect(appWidgetSource, contains('onWindowResize'));
    expect(appWidgetSource, contains('onWindowMove'));
    expect(appWidgetSource, contains('windowManager.getSize()'));
    expect(appWidgetSource, contains('windowManager.getPosition()'));

    expect(menuSource, isNot(contains("Modular.to.pushNamed('/search/'")));
    expect(menuSource, isNot(contains('FloatingActionButton')));
    expect(menuSource, isNot(contains('Icons.search_rounded')));

    expect(infoSource, contains('WindowControlInset'));
    expect(infoSource, isNot(contains('DesktopWindowActionRail')));
    expect(infoSource, isNot(contains('windowManager.close()')));
  });
}
