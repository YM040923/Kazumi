import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';
import 'package:kazumi/modules/roads/road_module.dart';
import 'package:kazumi/pages/info/info_tabview.dart';

void main() {
  setUpAll(() {
    Modular.bindModule(_InfoTabViewTestModule());
  });

  testWidgets('episode tab renders loaded roads and plays selected episode',
      (tester) async {
    late TabController tabController;
    int? playedRoad;
    int? playedEpisode;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              tabController = DefaultTabController.of(context);
              return Scaffold(
                body: SizedBox(
                  width: 1280,
                  height: 420,
                  child: InfoTabView(
                    episodesIsLoading: false,
                    episodesQueryTimeout: false,
                    episodesIsEmpty: false,
                    episodesLoaded: true,
                    selectedEpisodeRoad: 0,
                    roadList: [
                      Road(
                        name: '主线路',
                        data: const ['a', 'b'],
                        identifier: const ['第 1 集', '第 2 集'],
                      ),
                    ],
                    charactersQueryTimeout: false,
                    charactersIsEmpty: false,
                    staffQueryTimeout: false,
                    staffIsEmpty: false,
                    tabController: tabController,
                    loadEpisodes: () async {},
                    openSourceSheet: () {},
                    selectEpisodeRoad: (_) {},
                    playEpisode: ({required int road, required int episode}) {
                      playedRoad = road;
                      playedEpisode = episode;
                    },
                    loadCharacters: () async {},
                    loadStaff: () async {},
                    bangumiItem: _makeBangumiItem(),
                    characterList: const [],
                    staffList: const [],
                    isLoading: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('主线路'), findsOneWidget);
    expect(find.text('第 1 集'), findsOneWidget);

    await tester.tap(find.text('第 2 集'));
    expect(playedRoad, 0);
    expect(playedEpisode, 2);
  });

  testWidgets('episode tab prompts source search before roads are loaded',
      (tester) async {
    late TabController tabController;
    var openedSourceSheet = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              tabController = DefaultTabController.of(context);
              return Scaffold(
                body: SizedBox(
                  width: 900,
                  height: 420,
                  child: InfoTabView(
                    episodesIsLoading: false,
                    episodesQueryTimeout: false,
                    episodesIsEmpty: true,
                    episodesLoaded: false,
                    selectedEpisodeRoad: 0,
                    roadList: const [],
                    charactersQueryTimeout: false,
                    charactersIsEmpty: false,
                    staffQueryTimeout: false,
                    staffIsEmpty: false,
                    tabController: tabController,
                    loadEpisodes: () async {},
                    openSourceSheet: () {
                      openedSourceSheet = true;
                    },
                    selectEpisodeRoad: (_) {},
                    playEpisode: ({required int road, required int episode}) {},
                    loadCharacters: () async {},
                    loadStaff: () async {},
                    bangumiItem: _makeBangumiItem(),
                    characterList: const [],
                    staffList: const [],
                    isLoading: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('选择播放源后显示选集'), findsOneWidget);
    expect(find.text('搜索播放源'), findsOneWidget);

    await tester.tap(find.text('搜索播放源'));
    expect(openedSourceSheet, isTrue);
  });
}

BangumiItem _makeBangumiItem() {
  return BangumiItem(
    id: 1,
    type: 2,
    name: 'Demo',
    nameCn: '示例作品',
    summary: '用于测试详情页选集。',
    airDate: '2026-01-01',
    airWeekday: 4,
    rank: 1,
    images: const {},
    tags: [
      BangumiTag(name: '测试', count: 1, totalCount: 1),
    ],
    alias: const [],
    ratingScore: 8.5,
    votes: 100,
    votesCount: const [],
    info: '',
  );
}

class _InfoTabViewTestModule extends Module {}
