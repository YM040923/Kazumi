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
    final controlsSource =
        File('lib/bean/appbar/desktop_window_controls.dart').readAsStringSync();

    expect(source, contains('windowManager.setTitleBarStyle'));
    expect(source, contains('TitleBarStyle.normal'));
    expect(source, contains('TitleBarStyle.hidden'));
    expect(source, contains('windowButtonVisibility: showWindowButton'));
    expect(source, contains('DesktopWindowButtonMode.setShowNativeButtons'));
    expect(controlsSource, contains('ValueListenableBuilder<bool>'));
    expect(
        controlsSource, contains('DesktopWindowButtonMode.showNativeButtons'));
  });

  test('video page suppresses global window overlay controls', () {
    final controlsSource =
        File('lib/bean/appbar/desktop_window_controls.dart').readAsStringSync();
    final videoSource =
        File('lib/pages/video/video_page.dart').readAsStringSync();

    expect(controlsSource, contains('suppressOverlayControls'));
    expect(controlsSource, contains('setSuppressOverlayControls'));
    expect(videoSource,
        contains('DesktopWindowButtonMode.setSuppressOverlayControls(true)'));
    expect(videoSource,
        contains('DesktopWindowButtonMode.setSuppressOverlayControls(false)'));
  });

  test('desktop player keeps top-right actions out of window edge', () {
    final playerSource =
        File('lib/pages/player/player_item_panel.dart').readAsStringSync();

    expect(playerSource, contains('bool get _showPlayerTopActions'));
    expect(playerSource,
        contains('!Utils.isDesktop() || videoPageController.isFullscreen'));
    expect(playerSource, contains('if (_showPlayerTopActions) ...['));
  });
}
