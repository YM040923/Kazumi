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
}
