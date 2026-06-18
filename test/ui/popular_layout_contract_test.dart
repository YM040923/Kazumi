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
      source.indexOf('Widget _buildRemoteError'),
    );
    expect(
      sliverSource.indexOf('_buildContinueWatchingStrip'),
      lessThan(sliverSource.indexOf('_buildGrid')),
    );
  });

  test('discover page uses Chinese media shelf copy and spotlight header', () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();
    final menuSource = File('lib/pages/menu/menu.dart').readAsStringSync();

    for (final marker in [
      '_buildSpotlightBoard',
      '_SpotlightCopy',
      '_SpotlightThumbnailRail',
      '_TrendCategoryBar',
      '_MediaFilterHeader',
      'popularGridItemsExcludingSpotlight',
    ]) {
      expect(source, contains(marker));
    }

    for (final copy in [
      '发现',
      '精选推荐',
      '继续观看',
      '热门作品',
      '评分',
      '重试',
      '删除记录',
    ]) {
      expect(source, contains(copy));
    }

    for (final navCopy in ['发现', '时间表', '追番', '设置']) {
      expect(menuSource, contains(navCopy));
    }

    for (final englishCopy in [
      "'Discover'",
      "'For You'",
      "'Popular'",
      "'Continue Watching'",
      "'Nothing found'",
      "'Retry'",
      "'Score ",
      'label: Text(\'Discover\')',
      "label: 'Discover'",
      "label: 'Schedule'",
      "label: 'Favorites'",
      "label: 'Settings'",
    ]) {
      expect(source + menuSource, isNot(contains(englishCopy)));
    }

    expect(source, isNot(contains('_buildFeaturedRow')));
    expect(source, isNot(contains('CustomDropdownMenu')));
    expect(source, isNot(contains('showTagMenu')));
  });
}
