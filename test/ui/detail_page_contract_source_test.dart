import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail page exposes episodes first and removes overview/comments tabs',
      () {
    final infoPageSource =
        File('lib/pages/info/info_page.dart').readAsStringSync();
    final tabViewSource =
        File('lib/pages/info/info_tabview.dart').readAsStringSync();

    expect(infoPageSource, contains("['选集', '角色', '制作人员']"));
    expect(infoPageSource, contains('TabController(length: 3'));
    expect(infoPageSource, contains('loadEpisodes();'));
    expect(infoPageSource, contains('_showSourceSheet(context);'));
    expect(infoPageSource, isNot(contains('commentsIsLoading')));
    expect(infoPageSource, isNot(contains('loadMoreComments')));

    expect(tabViewSource, contains('episodeListBody'));
    expect(tabViewSource, contains('SliverOverlapInjector'));
    expect(tabViewSource,
        contains('NestedScrollView.sliverOverlapAbsorberHandleFor(context)'));
    expect(tabViewSource, contains('_EpisodeRoadSelector'));
    expect(tabViewSource, contains('_EpisodeTile'));
    expect(tabViewSource, isNot(contains('CommentsCard')));
    expect(tabViewSource, isNot(contains('commentsListBody')));
    expect(tabViewSource, isNot(contains('_InfoOverviewCard')));
  });

  test('detail header uses an editorial shelf composition', () {
    final infoCardSource =
        File('lib/bean/card/bangumi_info_card.dart').readAsStringSync();

    expect(infoCardSource, contains('_EditorialShelfPanel'));
    expect(infoCardSource, contains('_PosterFrame'));
    expect(infoCardSource, contains('_SynopsisPanel'));
    expect(infoCardSource, contains('_MetaPill'));
    expect(infoCardSource, contains('_TagStrip'));
    expect(infoCardSource, contains('_RatingShelf'));
    expect(infoCardSource, contains('CollectButton.extend'));
    expect(infoCardSource, isNot(contains('const Spacer()')));
    expect(infoCardSource, contains('showSynopsis: true'));
    expect(infoCardSource, isNot(contains('showSynopsis: !showChart')));
    expect(infoCardSource, contains('_DetailSidePanel'));
    expect(infoCardSource, contains('minHeight: 260'));
    expect(infoCardSource, isNot(contains('height: 126')));
    expect(infoCardSource, contains('评分'));
    expect(infoCardSource, contains('首播'));
    expect(infoCardSource, contains('排名'));
    expect(infoCardSource, isNot(contains('_MediaControlPanel')));
    expect(infoCardSource, isNot(contains('_RatingConsole')));
    expect(infoCardSource, isNot(contains('letterSpacing: -0.5')));
  });

  test('detail header keeps collect and tags inside the information column',
      () {
    final infoCardSource = File('lib/bean/card/bangumi_info_card.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');

    expect(infoCardSource, contains('class _InfoActionRow'));
    expect(infoCardSource,
        contains('_TagStrip(tags: bangumiItem.tags, dense: true)'));
    expect(infoCardSource, isNot(contains('class _DetailFooter')));
    expect(infoCardSource, isNot(contains('scrollDirection: Axis.horizontal')));
    expect(
        infoCardSource, isNot(contains('width: 220,\n            height: 42')));
  });

  test('detail header does not stretch synopsis into empty space', () {
    final infoCardSource = File('lib/bean/card/bangumi_info_card.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');

    expect(infoCardSource,
        contains('crossAxisAlignment: CrossAxisAlignment.start'));
    expect(infoCardSource, contains('mainAxisSize: MainAxisSize.min'));
    expect(infoCardSource, contains('maxLines: compact ? 3 : 5'));
    expect(
        infoCardSource,
        isNot(contains(
            'Flexible(\n            child: SizedBox(\n              width: double.infinity,\n              child: _SynopsisPanel(summary: summary),')));
  });

  test('detail tabs live with the content instead of the app bar header', () {
    final infoPageSource =
        File('lib/pages/info/info_page.dart').readAsStringSync();
    final tabViewSource =
        File('lib/pages/info/info_tabview.dart').readAsStringSync();

    expect(infoPageSource, contains('class _DetailSegmentedTabBar'));
    expect(infoPageSource, isNot(contains('bottom: PreferredSize(')));
    expect(
        infoPageSource,
        isNot(contains(
            '_detailHeaderHeight(context) +\n                            _detailSegmentedTabBarHeight')));
    expect(infoPageSource, contains('tabBar: _DetailSegmentedTabBar('));
    expect(tabViewSource, contains('final Widget tabBar;'));
    expect(tabViewSource, contains('SliverToBoxAdapter(child: widget.tabBar)'));
    expect(infoPageSource, contains('maxWidth: 360'));
    expect(infoPageSource, contains('indicatorSize: TabBarIndicatorSize.tab'));
    expect(
        infoPageSource, isNot(contains('tabAlignment: TabAlignment.center')));
  });
}
