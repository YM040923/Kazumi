import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';

void main() {
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
}
