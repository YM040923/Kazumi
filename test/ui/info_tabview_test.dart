import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/info/info_tabview.dart';
import 'package:kazumi/utils/ui_verification_fixtures.dart';

import 'ui_test_fixtures.dart';

void main() {
  setUpAll(() {
    Modular.bindModule(_InfoTabViewTestModule());
  });

  testWidgets('overview tab renders summary facts and tags', (tester) async {
    late TabController tabController;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: DefaultTabController(
          length: 5,
          child: Builder(
            builder: (context) {
              tabController = DefaultTabController.of(context);
              return Scaffold(
                body: SizedBox(
                  width: 1280,
                  height: 360,
                  child: InfoTabView(
                    commentsQueryTimeout: false,
                    commentsIsEmpty: false,
                    charactersQueryTimeout: false,
                    charactersIsEmpty: false,
                    staffQueryTimeout: false,
                    staffIsEmpty: false,
                    tabController: tabController,
                    loadMoreComments: ({int offset = 0}) async {},
                    loadCharacters: () async {},
                    loadStaff: () async {},
                    bangumiItem: makeUiVerificationBangumiItems().first,
                    commentsList: const [],
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
    expect(find.text('媒体简介'), findsOneWidget);
    expect(find.text('基础信息'), findsOneWidget);
    expect(find.text('主题标签'), findsOneWidget);
    expect(find.textContaining('勇者一行击败魔王'), findsOneWidget);
  });

  testWidgets('overview tab ignores stale page storage scroll offset',
      (tester) async {
    final bucket = PageStorageBucket();

    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(
          bucket: bucket,
          child: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 360,
              child: ListView(
                key: PageStorageKey<String>('概览'),
                children: [
                  SizedBox(height: 1400),
                  Text('stored bottom'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pump();

    late TabController tabController;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: PageStorage(
          bucket: bucket,
          child: DefaultTabController(
            length: 5,
            child: Builder(
              builder: (context) {
                tabController = DefaultTabController.of(context);
                return Scaffold(
                  body: SizedBox(
                    width: 1280,
                    height: 360,
                    child: InfoTabView(
                      commentsQueryTimeout: false,
                      commentsIsEmpty: false,
                      charactersQueryTimeout: false,
                      charactersIsEmpty: false,
                      staffQueryTimeout: false,
                      staffIsEmpty: false,
                      tabController: tabController,
                      loadMoreComments: ({int offset = 0}) async {},
                      loadCharacters: () async {},
                      loadStaff: () async {},
                      bangumiItem: makeTestBangumiItem(),
                      commentsList: const [],
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
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('媒体简介'), findsOneWidget);
  });
}

class _InfoTabViewTestModule extends Module {}

