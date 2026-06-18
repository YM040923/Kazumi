import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/timeline/timeline_layout.dart';

void main() {
  test('timeline poster grid columns follow content width', () {
    expect(timelinePosterGridColumnCount(520), 3);
    expect(timelinePosterGridColumnCount(640), 4);
    expect(timelinePosterGridColumnCount(760), 5);
    expect(timelinePosterGridColumnCount(980), 6);
    expect(timelinePosterGridColumnCount(1180), 7);
    expect(timelinePosterGridColumnCount(1380), 8);
    expect(timelinePosterGridColumnCount(1560), 9);
  });

  test('timeline uses poster-first cards instead of dense info cards', () {
    final pageSource =
        File('lib/pages/timeline/timeline_page.dart').readAsStringSync();
    final cardSource =
        File('lib/bean/card/bangumi_timeline_card.dart').readAsStringSync();

    expect(pageSource, contains('timelinePosterGridColumnCount'));
    expect(pageSource, contains('SliverLayoutBuilder'));
    expect(pageSource,
        isNot(contains('final width = MediaQuery.sizeOf(context).width')));

    expect(cardSource, contains('AspectRatio'));
    expect(cardSource, contains('aspectRatio: 0.68'));
    expect(cardSource, contains('_TimelinePosterFrame'));
    expect(cardSource, isNot(contains('buildInfo(')));
    expect(cardSource, isNot(contains('supportingText')));
  });

  test('global tab theme does not force start alignment on fixed tabs', () {
    final themeSource = File('lib/design/kazumi_theme.dart').readAsStringSync();
    final tabThemeSource = themeSource.substring(
      themeSource.indexOf('static TabBarThemeData _tabBarTheme'),
      themeSource.indexOf('static DialogThemeData _dialogTheme'),
    );

    expect(tabThemeSource, isNot(contains('TabAlignment.start')));
  });
}
