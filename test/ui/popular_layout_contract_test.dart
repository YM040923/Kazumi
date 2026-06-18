import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';

void main() {
  test('poster grid column count follows available content width', () {
    expect(popularPosterGridColumnCount(520), 3);
    expect(popularPosterGridColumnCount(700), 4);
    expect(popularPosterGridColumnCount(900), 5);
    expect(popularPosterGridColumnCount(1160), 6);
    expect(popularPosterGridColumnCount(1380), 7);
    expect(popularPosterGridColumnCount(1640), 8);
  });

  test('discover page keeps continue watching before poster wall', () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    expect(source, contains('_buildContinueWatchingStrip'));
    expect(source, contains('historyController.deleteHistory(history)'));
    expect(source, contains('popularPosterGridColumnCount'));
    expect(source, isNot(contains('MediaQuery.sizeOf(context).width;')));

    final sliverSource = source.substring(
      source.indexOf('slivers: ['),
      source.indexOf('Widget _buildAppBar'),
    );
    expect(
      sliverSource.indexOf('_buildContinueWatchingStrip'),
      lessThan(sliverSource.indexOf('_buildGrid')),
    );
  });
}
