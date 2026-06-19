import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';
import 'package:mobx/mobx.dart';

part 'popular_controller.g.dart';

// ignore: library_private_types_in_public_api
class PopularController = _PopularController with _$PopularController;

abstract class _PopularController with Store {
  final ScrollController scrollController = ScrollController();

  @observable
  String currentTag = '';

  @observable
  ObservableList<BangumiItem> bangumiList = ObservableList.of([]);

  @observable
  ObservableList<BangumiItem> trendList = ObservableList.of([]);

  double scrollOffset = 0.0;

  @observable
  bool isLoadingMore = false;

  @observable
  bool isTimeOut = false;

  void setCurrentTag(String s) {
    currentTag = s;
  }

  void clearBangumiList() {
    bangumiList.clear();
  }

  Future<void> queryBangumiByTrend({String type = 'add'}) async {
    if (type == 'init') {
      trendList.clear();
    }
    isLoadingMore = true;
    var result =
        await BangumiApi.getBangumiTrendsList(offset: trendList.length);
    trendList.addAll(result);
    isLoadingMore = false;
    isTimeOut = trendList.isEmpty;
  }

  Future<void> queryBangumiByTag({String type = 'add'}) async {
    if (type == 'init') {
      bangumiList.clear();
    }
    isLoadingMore = true;
    int randomNumber = Random().nextInt(8000) + 1;
    var tag = currentTag;
    var result = await BangumiApi.getBangumiList(rank: randomNumber, tag: tag);
    bangumiList.addAll(result);
    isLoadingMore = false;
    isTimeOut = bangumiList.isEmpty;
  }

  Future<void> queryBangumiByFilter(
    PopularFilterState filter, {
    String type = 'add',
  }) async {
    if (type == 'init') {
      bangumiList.clear();
    }
    isLoadingMore = true;
    isTimeOut = false;

    final query = buildPopularBangumiSearchQuery(
      filter,
      currentTag: currentTag,
    );
    final result = await BangumiApi.searchBangumiSubjects(
      keyword: query.keyword,
      tags: query.tags,
      rank: query.rank,
      airDate: query.airDate,
      offset: bangumiList.length,
      limit: 30,
      sort: query.sort,
    );
    bangumiList.addAll(result);
    isLoadingMore = false;
    isTimeOut = bangumiList.isEmpty;
  }
}
