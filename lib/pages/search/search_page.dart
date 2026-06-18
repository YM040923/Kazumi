import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/search/search_history_module.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/utils/logger.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.inputTag = ''});

  final String inputTag;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchController searchController = SearchController();

  /// Don't use modular singleton here. We may have multiple search pages.
  /// Use a new instance of SearchPageController for each search page.
  final SearchPageController searchPageController = SearchPageController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    searchPageController.loadSearchHistories();
    if (widget.inputTag != '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tagString = 'tag:${Uri.decodeComponent(widget.inputTag)}';
        searchController.text = tagString;
        searchPageController.searchBangumi(tagString, type: 'init');
      });
    }
  }

  @override
  void dispose() {
    searchPageController.bangumiList.clear();
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _leaveSearchPage() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    Modular.to.navigate('/tab/popular/');
  }

  void scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !searchPageController.isLoading &&
        searchController.text != '' &&
        searchPageController.bangumiList.length >= 20) {
      KazumiLogger().i('SearchController: search results is loading more');
      searchPageController.searchBangumi(searchController.text, type: 'add');
    }
  }

  void _submitSearch(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    searchController.text = keyword;
    searchPageController.searchBangumi(keyword, type: 'init');
    if (searchController.isOpen) {
      searchController.closeView(keyword);
    }
  }

  void _applySort(String sort) {
    final nextValue =
        searchPageController.attachSortParams(searchController.text, sort);
    searchController.text = nextValue;
    _submitSearch(nextValue);
  }

  Future<void> _openImageSearch() async {
    final result = await Modular.to.pushNamed('/search/image');
    if (result is String && result.isNotEmpty) {
      searchController.text = result;
      searchPageController.searchBangumi(result, type: 'init');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leaveSearchPage();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              WindowControlInset(
                child: _SearchHeader(
                  onBack: _leaveSearchPage,
                  searchBar: _SearchBar(
                    controller: searchController,
                    pageController: searchPageController,
                    onSubmitted: _submitSearch,
                    onImageSearch: _openImageSearch,
                  ),
                ),
              ),
              Expanded(
                child: Observer(
                  builder: (context) {
                    final filteredList = _filteredBangumiItems();
                    return CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: KazumiDesktopPageFrame(
                            maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                            child: _SearchToolbar(
                              resultCount: filteredList.length,
                              isLoading: searchPageController.isLoading,
                              notShowWatched:
                                  searchPageController.notShowWatchedBangumis,
                              notShowAbandoned:
                                  searchPageController.notShowAbandonedBangumis,
                              onSortSelected: _applySort,
                              onToggleWatched: (value) => searchPageController
                                  .setNotShowWatchedBangumis(value),
                              onToggleAbandoned: (value) => searchPageController
                                  .setNotShowAbandonedBangumis(value),
                            ),
                          ),
                        ),
                        if (searchPageController.isTimeOut)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: KazumiDesktopPageFrame(
                              maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                              child: _SearchErrorState(
                                keyword: searchController.text,
                                onRetry: () => _submitSearch(
                                  searchController.text,
                                ),
                              ),
                            ),
                          )
                        else if (searchPageController.isLoading &&
                            searchPageController.bangumiList.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (searchController.text.trim().isEmpty &&
                            searchPageController.bangumiList.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: KazumiDesktopPageFrame(
                              maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                              child: _SearchEmptyState(
                                onImageSearch: _openImageSearch,
                              ),
                            ),
                          )
                        else if (filteredList.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: KazumiDesktopPageFrame(
                              maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                              child: _SearchEmptyState(
                                title: '没有符合筛选条件的作品',
                                message: '关闭已看或已抛弃过滤后再试一次。',
                                onImageSearch: _openImageSearch,
                              ),
                            ),
                          )
                        else
                          SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final contentWidth = constraints.crossAxisExtent;
                              final columns = _searchGridColumns(contentWidth);
                              final gap = _searchGridGap(contentWidth);
                              final textHeight =
                                  _searchGridTextHeight(contentWidth);
                              final availableWidth =
                                  contentWidth - gap * (columns - 1);
                              final posterWidth = availableWidth / columns;

                              return SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 36),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    mainAxisSpacing: gap,
                                    crossAxisSpacing: gap,
                                    crossAxisCount: columns,
                                    mainAxisExtent:
                                        posterWidth / 0.68 + textHeight,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = filteredList[index];
                                      return BangumiCardV(
                                        enableHero: false,
                                        bangumiItem: item,
                                      );
                                    },
                                    childCount: filteredList.length,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (searchPageController.isLoading &&
                            searchPageController.bangumiList.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BangumiItem> _filteredBangumiItems() {
    List<BangumiItem> filteredList = searchPageController.bangumiList.toList();

    if (searchPageController.notShowWatchedBangumis) {
      final watchedBangumiIds = searchPageController.loadWatchedBangumiIds();
      filteredList = filteredList
          .where((item) => !watchedBangumiIds.contains(item.id))
          .toList();
    }

    if (searchPageController.notShowAbandonedBangumis) {
      final abandonedBangumiIds =
          searchPageController.loadAbandonedBangumiIds();
      filteredList = filteredList
          .where((item) => !abandonedBangumiIds.contains(item.id))
          .toList();
    }

    return filteredList;
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.onBack,
    required this.searchBar,
  });

  final VoidCallback onBack;
  final Widget searchBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.62),
      child: dtb.DragToMoveArea(
        child: SafeArea(
          bottom: false,
          child: KazumiDesktopPageFrame(
            maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: '\u8fd4\u56de',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u641c\u7d22',
                              style: textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '按名称、标签或 ID 搜索 Bangumi 条目',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  searchBar,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.pageController,
    required this.onSubmitted,
    required this.onImageSearch,
  });

  final SearchController controller;
  final SearchPageController pageController;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onImageSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusScope(
      descendantsAreFocusable: false,
      child: SearchAnchor.bar(
        searchController: controller,
        barHintText: '输入番剧名、tag:校园、id:400602',
        barLeading: const Icon(Icons.search_rounded),
        barElevation: WidgetStateProperty<double>.fromMap(
          const <WidgetStatesConstraint, double>{WidgetState.any: 0},
        ),
        barBackgroundColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHighest.withValues(alpha: 0.54),
        ),
        viewElevation: 0,
        viewLeading: IconButton(
          tooltip: '\u8fd4\u56de',
          onPressed: () => controller.closeView(controller.text),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        barTrailing: [
          IconButton(
            tooltip: '图片搜索',
            onPressed: onImageSearch,
            icon: const Icon(Icons.image_search_rounded),
          ),
        ],
        isFullScreen:
            MediaQuery.sizeOf(context).width < KazumiDesktopShell.sidebarWidth,
        suggestionsBuilder: (context, controller) => [
          Observer(
            builder: (context) {
              if (controller.text.isNotEmpty) {
                return ListTile(
                  leading: const Icon(Icons.keyboard_return_rounded),
                  title: const Text('无可用搜索建议，回车以直接检索'),
                  subtitle: Text(controller.text),
                  onTap: () => onSubmitted(controller.text),
                );
              }

              final histories = pageController.searchHistories.take(10);
              if (histories.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.history_rounded),
                  title: Text('暂无搜索历史'),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final history in histories)
                    _SearchHistoryTile(
                      history: history,
                      onTap: () {
                        controller.text = history.keyword;
                        onSubmitted(history.keyword);
                      },
                      onDelete: () => pageController.deleteSearchHistory(
                        history,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.resultCount,
    required this.isLoading,
    required this.notShowWatched,
    required this.notShowAbandoned,
    required this.onSortSelected,
    required this.onToggleWatched,
    required this.onToggleAbandoned,
  });

  final int resultCount;
  final bool isLoading;
  final bool notShowWatched;
  final bool notShowAbandoned;
  final ValueChanged<String> onSortSelected;
  final ValueChanged<bool> onToggleWatched;
  final ValueChanged<bool> onToggleAbandoned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
      child: KazumiGlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        showShadow: false,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(KazumiRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_filter_rounded,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    isLoading ? '正在搜索' : '结果 $resultCount',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.local_fire_department_rounded),
                  onPressed: () => onSortSelected('heat'),
                  child: const Text('\u6309\u70ed\u5ea6\u6392\u5e8f'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.star_rounded),
                  onPressed: () => onSortSelected('rank'),
                  child: const Text('按评分排序'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.manage_search_rounded),
                  onPressed: () => onSortSelected('match'),
                  child: const Text('按匹配程度排序'),
                ),
              ],
              builder: (context, controller, child) {
                return OutlinedButton.icon(
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(Icons.sort_rounded),
                  label: const Text('排序'),
                );
              },
            ),
            FilterChip(
              selected: notShowWatched,
              onSelected: onToggleWatched,
              avatar: const Icon(Icons.visibility_off_rounded, size: 18),
              label: const Text('\u9690\u85cf\u5df2\u770b'),
            ),
            FilterChip(
              selected: notShowAbandoned,
              onSelected: onToggleAbandoned,
              avatar: const Icon(Icons.block_rounded, size: 18),
              label: const Text('隐藏抛弃'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHistoryTile extends StatelessWidget {
  const _SearchHistoryTile({
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  final SearchHistory history;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history_rounded),
      title: Text(history.keyword),
      onTap: onTap,
      trailing: IconButton(
        tooltip: '删除记录',
        icon: const Icon(Icons.close_rounded),
        onPressed: onDelete,
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.onImageSearch,
    this.title = '搜索结果将在这里展示',
    this.message = '输入关键词后按回车，也可以用截图进行图片搜索。',
  });

  final String title;
  final String message;
  final VoidCallback onImageSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: KazumiGlassSurface(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 46,
                color: scheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onImageSearch,
                icon: const Icon(Icons.image_search_rounded),
                label: const Text('图片搜索'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({
    required this.keyword,
    required this.onRetry,
  });

  final String keyword;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GeneralErrorWidget(
        errMsg: keyword.trim().isEmpty ? '什么都没有找到' : '没有找到与「$keyword」相关的作品',
        actions: [
          GeneralErrorButton(onPressed: onRetry, text: '点击重试'),
        ],
      ),
    );
  }
}

int _searchGridColumns(double contentWidth) {
  if (contentWidth >= 1280) return 7;
  if (contentWidth >= 1080) return 6;
  if (contentWidth >= 860) return 5;
  if (contentWidth >= 620) return 4;
  return 3;
}

double _searchGridGap(double contentWidth) {
  if (contentWidth >= 980) return 14;
  return 12;
}

double _searchGridTextHeight(double contentWidth) {
  if (contentWidth < 640) return 54;
  return 58;
}
