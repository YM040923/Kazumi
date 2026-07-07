import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history page exposes a visible back action in its header', () {
    final source =
        File('lib/pages/history/history_page.dart').readAsStringSync();

    final headerSource = source.substring(
      source.indexOf('class _HistoryHeader'),
      source.indexOf('class _HistoryEmptyState'),
    );

    expect(headerSource, contains('required this.onBack'));
    expect(headerSource, contains('final VoidCallback onBack;'));
    expect(headerSource, contains('Icons.arrow_back_rounded'));
    expect(headerSource, contains('tooltip:'));
    expect(headerSource, contains('onPressed: onBack'));
    expect(source, contains('onBack: () => Modular.to.pop()'));
    expect(source, contains('KazumiDesktopHeaderTopRow'));
  });

  test('settings shell exposes a reusable visible back action', () {
    final shellSource =
        File('lib/bean/widget/settings_page_shell.dart').readAsStringSync();

    expect(shellSource,
        contains("import 'package:flutter_modular/flutter_modular.dart';"));
    expect(shellSource, contains('this.onBack'));
    expect(shellSource, contains('final VoidCallback? onBack;'));
    expect(shellSource, contains('Icons.arrow_back_rounded'));
    expect(shellSource, contains("tooltip: '返回'"));
    expect(
        shellSource, contains('onPressed: onBack ?? () => Modular.to.pop()'));
  });

  test('plugin pages inherit the settings shell back action', () {
    for (final path in [
      'lib/pages/plugin_editor/plugin_view_page.dart',
      'lib/pages/plugin_editor/plugin_shop_page.dart',
      'lib/pages/plugin_editor/plugin_editor_page.dart',
      'lib/pages/plugin_editor/plugin_test_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('KazumiSettingsPageShell('), reason: path);
      expect(source, isNot(contains('SysAppBar')), reason: path);
    }
  });

  test('custom settings headers expose visible back actions', () {
    for (final path in [
      'lib/pages/settings/theme_settings_page.dart',
      'lib/pages/settings/interface_settings.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('Icons.arrow_back_rounded'), reason: path);
      expect(source, contains("tooltip: '返回'"), reason: path);
      expect(source, contains('Modular.to.pop()'), reason: path);
    }
  });

  test('settings module pages either share shell or define custom back', () {
    final pagePaths = [
      'lib/pages/settings/theme_settings_page.dart',
      'lib/pages/settings/interface_settings.dart',
      'lib/pages/settings/displaymode_settings.dart',
      'lib/pages/settings/keyboard_settings.dart',
      'lib/pages/settings/player_settings.dart',
      'lib/pages/settings/decoder_settings.dart',
      'lib/pages/settings/renderer_settings.dart',
      'lib/pages/settings/super_resolution_settings.dart',
      'lib/pages/settings/download_settings.dart',
      'lib/pages/settings/proxy/proxy_settings_page.dart',
      'lib/pages/settings/proxy/proxy_editor_page.dart',
      'lib/pages/settings/danmaku/danmaku_settings.dart',
      'lib/pages/settings/danmaku/danmaku_shield_settings.dart',
      'lib/pages/webdav_editor/webdav_setting.dart',
      'lib/pages/webdav_editor/webdav_editor_page.dart',
      'lib/pages/bangumi/bangumi_setting.dart',
      'lib/pages/about/about_page.dart',
      'lib/pages/logs/logs_page.dart',
      'lib/pages/plugin_editor/plugin_view_page.dart',
      'lib/pages/plugin_editor/plugin_shop_page.dart',
      'lib/pages/plugin_editor/plugin_editor_page.dart',
      'lib/pages/plugin_editor/plugin_test_page.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      final hasSharedShell = source.contains('KazumiSettingsPageShell(');
      final hasCustomBack = source.contains('Icons.arrow_back_rounded') &&
          source.contains('Modular.to.pop()');
      expect(hasSharedShell || hasCustomBack, isTrue, reason: path);
    }
  });
}
