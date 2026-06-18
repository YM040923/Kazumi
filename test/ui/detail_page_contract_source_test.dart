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
    expect(infoCardSource, contains('评分'));
    expect(infoCardSource, contains('首播'));
    expect(infoCardSource, contains('排名'));
    expect(infoCardSource, isNot(contains('_MediaControlPanel')));
    expect(infoCardSource, isNot(contains('_RatingConsole')));
    expect(infoCardSource, isNot(contains('letterSpacing: -0.5')));
  });

  test('detail tabs use a compact segmented bar instead of a full-width rail',
      () {
    final infoPageSource =
        File('lib/pages/info/info_page.dart').readAsStringSync();

    expect(infoPageSource, contains('class _DetailSegmentedTabBar'));
    expect(infoPageSource, contains('PreferredSize('));
    expect(infoPageSource, contains('maxWidth: 360'));
    expect(infoPageSource, contains('indicatorSize: TabBarIndicatorSize.tab'));
    expect(
        infoPageSource, isNot(contains('tabAlignment: TabAlignment.center')));
  });
}
