import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'desktop pages share one bounded scroll shell instead of full-width drift',
      () {
    final desktopLayoutSource =
        File('lib/design/desktop_layout.dart').readAsStringSync();
    final settingsSource = File('lib/pages/my/my_page.dart').readAsStringSync();
    final timelineSource =
        File('lib/pages/timeline/timeline_page.dart').readAsStringSync();
    final collectSource =
        File('lib/pages/collect/collect_page.dart').readAsStringSync();
    final settingsShellSource =
        File('lib/bean/widget/settings_page_shell.dart').readAsStringSync();

    for (final marker in [
      'class KazumiDesktopScrollFrame',
      'ScrollConfiguration',
      'scrollbars: false',
      'class KazumiDesktopHeaderFrame',
      'WindowControlInset',
      'KazumiDesktopPageFrame',
    ]) {
      expect(desktopLayoutSource, contains(marker));
    }

    for (final source in [settingsSource, settingsShellSource]) {
      expect(source, contains('KazumiDesktopScrollFrame('));
      expect(source,
          isNot(contains('WindowControlInset(\n          child: ListView')));
      expect(source,
          isNot(contains('WindowControlInset(\n        child: ListView')));
    }

    for (final source in [timelineSource, collectSource]) {
      expect(source, contains('KazumiDesktopHeaderFrame('));
      expect(source,
          isNot(contains('WindowControlInset(\n                    child: _')));
      expect(source,
          isNot(contains('WindowControlInset(\n                  child: _')));
    }
  });

  test('timeline and collection filter rails do not stretch into empty glass',
      () {
    final timelineSource =
        File('lib/pages/timeline/timeline_page.dart').readAsStringSync();
    final collectSource =
        File('lib/pages/collect/collect_page.dart').readAsStringSync();

    final timelineHeaderSource = timelineSource.substring(
      timelineSource.indexOf('class _TimelineHeader'),
    );
    final collectHeaderSource = collectSource.substring(
      collectSource.indexOf('class _CollectHeader'),
      collectSource.indexOf('class _CollectPageActions'),
    );

    for (final source in [timelineHeaderSource, collectHeaderSource]) {
      expect(source, contains('Align('));
      expect(source, contains('widthFactor: 1'));
      expect(
        source,
        isNot(contains('crossAxisAlignment: CrossAxisAlignment.stretch')),
      );
    }
  });
}
