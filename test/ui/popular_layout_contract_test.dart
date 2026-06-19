import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';

void main() {
  BangumiItem item({
    required int id,
    required String title,
    required String date,
    required double score,
    required int rank,
    List<String> tags = const [],
  }) {
    return BangumiItem(
      id: id,
      type: 2,
      name: title,
      nameCn: title,
      summary: '',
      airDate: date,
      airWeekday: 1,
      rank: rank,
      images: const {'large': ''},
      tags: tags
          .map((tag) => BangumiTag(name: tag, count: 1, totalCount: 1))
          .toList(),
      alias: const [],
      ratingScore: score,
      votes: 0,
      votesCount: const [],
      info: '',
    );
  }

  test('poster grid column count follows available content width', () {
    expect(popularPosterGridColumnCount(520), 3);
    expect(popularPosterGridColumnCount(700), 4);
    expect(popularPosterGridColumnCount(900), 4);
    expect(popularPosterGridColumnCount(1160), 5);
    expect(popularPosterGridColumnCount(1380), 6);
    expect(popularPosterGridColumnCount(1640), 7);
  });

  test('poster grid keeps wider gutters on desktop windows', () {
    expect(popularPosterGridGap(620), 16);
    expect(popularPosterGridGap(980), 22);
    expect(popularPosterGridGap(1400), 28);
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

  test('discover spotlight controls avoid overflow and open details', () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    final appBarSource = source.substring(
      source.indexOf('Widget _buildMediaAppBar'),
      source.indexOf('Widget _buildSpotlightBoard'),
    );
    expect(appBarSource, isNot(contains('DesktopWindowActionRail')));
    expect(appBarSource, isNot(contains('DesktopWindowControls')));
    expect(appBarSource, contains('WindowControlTopActionArea'));
    expect(appBarSource, contains('toolbarHeight: 72'));
    expect(appBarSource, contains('WindowControlInset'));

    final featuredPosterSource = source.substring(
      source.indexOf('class _FeaturedPoster'),
      source.indexOf('class _BangumiPosterImage'),
    );
    expect(featuredPosterSource, contains('required this.onTap'));
    expect(featuredPosterSource, contains('onTap: onTap'));

    final thumbnailSource = source.substring(
      source.indexOf('class _SpotlightThumbnailButton'),
      source.indexOf('class _FeaturedPoster'),
    );
    expect(thumbnailSource, contains('required this.onOpenDetails'));
    expect(thumbnailSource, contains('onTap: onOpenDetails'));
    expect(thumbnailSource, contains('onHover:'));

    final copySource = source.substring(
      source.indexOf('class _SpotlightCopy'),
      source.indexOf('class _SpotlightThumbnailRail'),
    );
    expect(copySource, contains('LayoutBuilder'));
    expect(copySource, contains('Flexible('));
    expect(copySource, contains('final tight'));
  });

  test('discover spotlight backdrop uses clean ambient stage instead of blur',
      () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    final backdropSource = source.substring(
      source.indexOf('class _SpotlightBackdrop'),
      source.indexOf('class _SpotlightCopy'),
    );

    expect(backdropSource, contains('_SpotlightAmbientPlane'));
    expect(backdropSource, contains('BlendMode.softLight'));
    expect(backdropSource, contains('LinearGradient'));
    expect(backdropSource, contains('IgnorePointer'));
    expect(backdropSource, isNot(contains('_SpotlightBackdropPoster')));
    expect(backdropSource, isNot(contains('ImageFiltered')));
    expect(backdropSource, isNot(contains('ImageFilter.blur')));
    expect(backdropSource, isNot(contains('Image.network')));
    expect(backdropSource, isNot(contains('width: double.infinity')));
    expect(backdropSource, isNot(contains('height: double.infinity')));
  });

  test('discover poster wall filters and sorts local Bangumi results', () {
    final items = [
      item(id: 1, title: 'A', date: '2026-04-01', score: 7.8, rank: 120),
      item(id: 2, title: 'B', date: '2025-01-01', score: 8.7, rank: 40),
      item(id: 3, title: 'C', date: '2025-07-01', score: 0, rank: 0),
      item(id: 4, title: 'D', date: '2024-10-01', score: 8.1, rank: 0),
    ];

    final result = filterPopularBangumiItems(
      items,
      const PopularFilterState(
        sort: PopularSortMode.score,
        year: PopularYearFilter.year2025,
        visibility: PopularVisibilityFilter.rated,
      ),
    );

    expect(result.map((item) => item.id), [2]);
    expect(const PopularFilterState().hasActiveFilters, isFalse);
    expect(
      const PopularFilterState(
        sort: PopularSortMode.score,
        year: PopularYearFilter.year2025,
      ).activeLabels,
      containsAll(['评分优先', '2025']),
    );
  });

  test('discover page exposes a compact filter surface for poster wall', () {
    final source =
        File('lib/pages/popular/popular_page.dart').readAsStringSync();

    expect(source, contains('_buildFilteredGridItems'));
    expect(source, contains('_showPosterFilterSheet'));
    expect(source, contains('_PosterFilterSheet'));
    expect(source, contains('_buildActiveFilterChips'));
    expect(source, contains('Icons.tune_rounded'));
    expect(source, contains('筛选'));
    expect(source, contains('清除'));
    expect(source, contains('应用'));
  });
}
