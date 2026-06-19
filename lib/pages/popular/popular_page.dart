import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/card/bangumi_history_card.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';
import 'package:kazumi/utils/constants.dart';

const double _spotlightThumbnailGap = 10;
const double _spotlightThumbnailPreferredWidth = 152;
const double _spotlightThumbnailMinimumWidth = 104;
const double _spotlightThumbnailRailHeight = 76;

class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with AutomaticKeepAliveClientMixin {
  DateTime? _lastPressedAt;
  final ScrollController scrollController = ScrollController();
  final PopularController popularController = Modular.get<PopularController>();
  final HistoryController historyController = Modular.get<HistoryController>();
  static const int _spotlightWindowSize = 6;
  static const Duration _spotlightAutoPlayInterval = Duration(seconds: 6);

  int _selectedSpotlightIndex = 0;
  int _spotlightPageStart = 0;
  bool _refreshing = false;
  PopularFilterState _posterFilter = const PopularFilterState();
  Timer? _spotlightAutoPlayTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    if (popularController.trendList.isEmpty) {
      popularController.queryBangumiByTrend();
    }
    historyController.init();
    _startSpotlightAutoPlay();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    _spotlightAutoPlayTimer?.cancel();
    super.dispose();
  }

  void scrollListener() {
    popularController.scrollOffset = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !popularController.isLoadingMore) {
      if (popularController.currentTag.isEmpty) {
        popularController.queryBangumiByTrend();
      } else {
        popularController.queryBangumiByTag();
      }
    }
  }

  List<BangumiItem> _currentList() {
    return popularController.currentTag.isEmpty
        ? popularController.trendList.toList()
        : popularController.bangumiList.toList();
  }

  List<BangumiItem> _buildFilteredGridItems(List<BangumiItem> list) {
    return filterPopularBangumiItems(list, _posterFilter);
  }

  List<History> _recentHistories() {
    final histories = historyController.histories.toList();
    histories.sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
    return histories.take(10).toList();
  }

  Future<void> _retryCurrentView() => _refreshCurrentView();

  Future<void> _refreshCurrentView() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final changed = _advanceSpotlightWindow();
      if (!changed) {
        if (popularController.currentTag.isEmpty) {
          await popularController.queryBangumiByTrend(type: 'init');
        } else {
          await popularController.queryBangumiByTag(type: 'init');
        }
        _advanceSpotlightWindow();
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _selectCategory(String tag) async {
    if (popularController.currentTag == tag) return;

    setState(() {
      _selectedSpotlightIndex = 0;
      _spotlightPageStart = 0;
    });
    popularController.setCurrentTag(tag);

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: KazumiDurations.normal,
        curve: Curves.easeOutCubic,
      );
    }

    if (tag.isEmpty) {
      popularController.clearBangumiList();
      await popularController.queryBangumiByTrend(type: 'init');
    } else {
      await popularController.queryBangumiByTag(type: 'init');
    }
    _restartSpotlightAutoPlay();
  }

  void _selectSpotlightItem(int index) {
    setState(() => _selectedSpotlightIndex = index);
    _restartSpotlightAutoPlay();
  }

  bool _advanceSpotlightWindow() {
    final list = _currentList();
    if (list.length <= _spotlightWindowSize) return false;

    final nextStart = nextSpotlightPageStart(
      currentStart: _spotlightPageStart,
      itemCount: list.length,
      windowSize: _spotlightWindowSize,
    );
    if (nextStart == _spotlightPageStart && _spotlightPageStart == 0) {
      return false;
    }

    if (mounted) {
      setState(() {
        _spotlightPageStart = nextStart;
        _selectedSpotlightIndex = 0;
      });
    } else {
      _spotlightPageStart = nextStart;
      _selectedSpotlightIndex = 0;
    }
    _restartSpotlightAutoPlay();
    return true;
  }

  void _startSpotlightAutoPlay() {
    _spotlightAutoPlayTimer?.cancel();
    _spotlightAutoPlayTimer = Timer.periodic(_spotlightAutoPlayInterval, (_) {
      final items = spotlightWindowFor(
        _currentList(),
        start: _spotlightPageStart,
        size: _spotlightWindowSize,
      );
      if (!mounted || items.length <= 1) return;
      setState(() {
        _selectedSpotlightIndex = nextSpotlightIndex(
          currentIndex: _selectedSpotlightIndex,
          itemCount: items.length,
        );
      });
    });
  }

  void _restartSpotlightAutoPlay() {
    _startSpotlightAutoPlay();
  }

  void _openDetails(BangumiItem item) {
    Modular.to.pushNamed('/info/', arguments: item);
  }

  Future<void> _showPosterFilterSheet() async {
    final result = await showModalBottomSheet<PopularFilterState>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PosterFilterSheet(initialFilter: _posterFilter),
    );
    if (result == null || result == _posterFilter) return;
    setState(() {
      _posterFilter = result;
      _selectedSpotlightIndex = 0;
      _spotlightPageStart = 0;
    });
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            const Duration(seconds: 2)) {
      _lastPressedAt = DateTime.now();
      KazumiDialog.showToast(message: '再按一次退出应用', context: context);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBackPressed(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Observer(
          builder: (_) {
            final list = _currentList();
            final filteredGridItems = _buildFilteredGridItems(list);
            final showRemoteError = popularController.isTimeOut && list.isEmpty;
            final loading = popularController.isLoadingMore || _refreshing;

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                _buildMediaAppBar(scheme, loading),
                if (showRemoteError)
                  _buildRemoteError()
                else ...[
                  if (list.isEmpty)
                    _buildLoadingSpotlight(scheme)
                  else
                    _buildSpotlightBoard(scheme, list, loading),
                  SliverToBoxAdapter(child: _buildContinueWatchingStrip()),
                  SliverToBoxAdapter(
                    child: _TrendCategoryBar(
                      title: popularController.currentTag.isEmpty
                          ? '热门作品'
                          : '${popularController.currentTag}作品',
                      subtitle: popularController.currentTag.isEmpty
                          ? '从 Bangumi 热门条目里挑选最近值得打开的内容。'
                          : '正在浏览 ${popularController.currentTag} 分类下的作品。',
                      count: list.length,
                      loading: loading && list.isEmpty,
                      child: _buildPosterWallToolbar(scheme),
                    ),
                  ),
                  if (list.isEmpty)
                    _buildLoadingPosterGrid(scheme)
                  else
                    _buildGrid(
                      popularGridItemsExcludingSpotlight(
                        filteredGridItems,
                        spotlightStart: _spotlightPageStart,
                        spotlightSize: _spotlightWindowSize,
                      ),
                    ),
                  if (popularController.isLoadingMore && list.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRemoteError() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GeneralErrorWidget(
          errMsg: '没有找到内容，请检查网络后重试。',
          actions: [
            GeneralErrorButton(onPressed: _retryCurrentView, text: '重试'),
            GeneralErrorButton(
              onPressed: () => Modular.to.pushNamed('/settings/proxy'),
              text: '代理设置',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaAppBar(ColorScheme scheme, bool loading) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      toolbarHeight: 72,
      scrolledUnderElevation: KazumiElevations.subtle,
      backgroundColor: scheme.surface.withValues(alpha: 0.62),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      actions: [
        WindowControlTopActionArea(
          child: WindowControlInset(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '搜索',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => Modular.to.pushNamed('/search/'),
                ),
                IconButton(
                  tooltip: '观看历史',
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => Modular.to.pushNamed('/settings/history/'),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: SafeArea(
        bottom: false,
        child: dtb.DragToMoveArea(
          child: WindowControlInset(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, top: 10, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '精选推荐、继续观看和热门作品',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlightBoard(
    ColorScheme scheme,
    List<BangumiItem> list,
    bool loading,
  ) {
    return SliverToBoxAdapter(
      child: _DesktopContentFrame(
        top: 18,
        bottom: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ContentWidthMetrics.from(constraints.maxWidth);
            final isWide = metrics.contentWidth >= 860;
            final height = isWide ? 326.0 : 492.0;
            final spotlightItems = spotlightWindowFor(
              list,
              start: _spotlightPageStart,
              size: _spotlightWindowSize,
            );
            final selectedIndex = math.min(
              _selectedSpotlightIndex,
              math.max(0, spotlightItems.length - 1),
            );
            final selectedItem = spotlightItems.isEmpty
                ? list.first
                : spotlightItems[selectedIndex];

            return SizedBox(
              width: metrics.contentWidth,
              height: height,
              child: _SpotlightSurface(
                item: selectedItem,
                items: spotlightItems,
                selectedIndex: selectedIndex,
                loading: loading,
                isWide: isWide,
                onOpenDetails: _openDetails,
                onRefresh: _refreshCurrentView,
                onSelect: _selectSpotlightItem,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueWatchingStrip() {
    return Observer(
      builder: (context) {
        final histories = _recentHistories();
        if (histories.isEmpty) return const SizedBox.shrink();

        return _DesktopContentFrame(
          top: 8,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.play_circle_outline_rounded,
                title: '继续观看',
                subtitle: '从上次中断的位置快速回到播放。',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: histories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    return SizedBox(
                      width: 292,
                      child: _ContinueWatchingTile(
                        history: history,
                        onDelete: () {
                          historyController.deleteHistory(history);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChips(ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: [
              _tagChip(
                '热门',
                popularController.currentTag.isEmpty,
                scheme,
                onTap: () => _selectCategory(''),
              ),
              ...defaultAnimeTags.map(
                (tag) => _tagChip(
                  tag,
                  popularController.currentTag == tag,
                  scheme,
                  onTap: () => _selectCategory(tag),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPosterWallToolbar(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTagChips(scheme)),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _showPosterFilterSheet,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('筛选'),
            ),
          ],
        ),
        _buildActiveFilterChips(scheme),
      ],
    );
  }

  Widget _buildActiveFilterChips(ColorScheme scheme) {
    final labels = _posterFilter.activeLabels;
    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels)
            InputChip(
              label: Text(label),
              avatar:
                  Icon(Icons.check_rounded, size: 16, color: scheme.primary),
              onDeleted: () {
                setState(() => _posterFilter = const PopularFilterState());
              },
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, bool selected, ColorScheme scheme,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: KazumiDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.84)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.34)
                  : scheme.outlineVariant.withValues(alpha: 0.34),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<BangumiItem> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: _DesktopContentFrame(
        top: 10,
        bottom: 24,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ContentWidthMetrics.from(constraints.maxWidth);
            final crossCount =
                popularPosterGridColumnCount(metrics.contentWidth);
            final gridGap = popularPosterGridGap(metrics.contentWidth);
            final textHeight =
                popularPosterGridTextHeight(metrics.contentWidth);
            final posterAspectRatio =
                popularPosterAspectRatio(metrics.contentWidth);
            final cardWidth =
                (metrics.contentWidth - (crossCount - 1) * gridGap) /
                    crossCount;

            return SizedBox(
              width: metrics.contentWidth,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: gridGap + 4,
                  crossAxisSpacing: gridGap,
                  crossAxisCount: crossCount,
                  mainAxisExtent: cardWidth / posterAspectRatio + textHeight,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) => BangumiCardV(
                  bangumiItem: list[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSpotlight(ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: _DesktopContentFrame(
        top: 18,
        bottom: 8,
        child: _SkeletonSpotlight(scheme: scheme),
      ),
    );
  }

  Widget _buildLoadingPosterGrid(ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: _DesktopContentFrame(
        top: 10,
        bottom: 24,
        child: Wrap(
          spacing: 14,
          runSpacing: 18,
          children: [
            for (var index = 0; index < 12; index++)
              _SkeletonPosterTile(scheme: scheme),
          ],
        ),
      ),
    );
  }
}

class _SpotlightSurface extends StatelessWidget {
  const _SpotlightSurface({
    required this.item,
    required this.items,
    required this.selectedIndex,
    required this.loading,
    required this.isWide,
    required this.onOpenDetails,
    required this.onRefresh,
    required this.onSelect,
  });

  final BangumiItem item;
  final List<BangumiItem> items;
  final int selectedIndex;
  final bool loading;
  final bool isWide;
  final ValueChanged<BangumiItem> onOpenDetails;
  final VoidCallback onRefresh;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow
              .withValues(alpha: isDark ? 0.74 : 0.86),
          borderRadius: BorderRadius.circular(KazumiRadius.lg),
          border: Border.all(
            color:
                scheme.outlineVariant.withValues(alpha: isDark ? 0.26 : 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KazumiRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SpotlightBackdrop(item: item),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.surface.withValues(alpha: isDark ? 0.88 : 0.82),
                      scheme.surface.withValues(alpha: isDark ? 0.70 : 0.56),
                      scheme.surface.withValues(alpha: isDark ? 0.18 : 0.10),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isWide ? 18 : 14),
                child: isWide ? _buildWide(context) : _buildNarrow(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      children: [
        _FeaturedPoster(
          item: item,
          width: 176,
          height: double.infinity,
          onTap: () => onOpenDetails(item),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SpotlightCopy(
                  item: item,
                  loading: loading,
                  onOpenDetails: () => onOpenDetails(item),
                  onRefresh: onRefresh,
                ),
              ),
              const SizedBox(height: 14),
              _SpotlightThumbnailRail(
                items: items,
                selectedIndex: selectedIndex,
                onOpenDetails: onOpenDetails,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 210,
          child: Row(
            children: [
              _FeaturedPoster(
                item: item,
                width: 132,
                height: 210,
                onTap: () => onOpenDetails(item),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SpotlightCopy(
                  item: item,
                  loading: loading,
                  onOpenDetails: () => onOpenDetails(item),
                  onRefresh: onRefresh,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _SpotlightThumbnailRail(
          items: items,
          selectedIndex: selectedIndex,
          onOpenDetails: onOpenDetails,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

class _SpotlightBackdrop extends StatelessWidget {
  const _SpotlightBackdrop({required this.item});

  final BangumiItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: IgnorePointer(
        child: _SpotlightAmbientPlane(scheme: scheme),
      ),
    );
  }
}

class _SpotlightAmbientPlane extends StatelessWidget {
  const _SpotlightAmbientPlane({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.surface.withValues(alpha: isDark ? 0.80 : 0.88),
                scheme.primaryContainer.withValues(alpha: isDark ? 0.18 : 0.20),
                scheme.secondaryContainer.withValues(
                  alpha: isDark ? 0.12 : 0.16,
                ),
                scheme.surface.withValues(alpha: isDark ? 0.66 : 0.74),
              ],
              stops: const [0, 0.42, 0.74, 1],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.54,
            heightFactor: 0.86,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.24, -0.12),
                  radius: 0.86,
                  colors: [
                    scheme.primary.withValues(alpha: isDark ? 0.18 : 0.16),
                    scheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.44, 1],
                ),
                backgroundBlendMode: BlendMode.softLight,
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.72, -0.42),
          child: FractionallySizedBox(
            widthFactor: 0.30,
            heightFactor: 0.34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.08 : 0.26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.02 : 0.18),
                Colors.transparent,
                scheme.surface.withValues(alpha: isDark ? 0.24 : 0.28),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightCopy extends StatelessWidget {
  const _SpotlightCopy({
    required this.item,
    required this.loading,
    required this.onOpenDetails,
    required this.onRefresh,
    this.compact = false,
  });

  final BangumiItem item;
  final bool loading;
  final VoidCallback onOpenDetails;
  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _bangumiTitle(item);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight < (compact ? 210 : 214);
        final summary = item.summary.trim().isNotEmpty
            ? item.summary.trim()
            : '暂时没有简介，可以先进入详情查看播放源和更多资料。';

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusPill(
              icon: Icons.auto_awesome_rounded,
              label: '精选推荐',
              color: scheme.primary,
            ),
            SizedBox(height: tight ? 8 : 14),
            Text(
              title,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: tight ? (compact ? 22 : 26) : (compact ? 24 : 30),
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: tight ? 8 : 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaPill(
                  icon: Icons.star_rounded,
                  label: item.ratingScore > 0
                      ? '评分 ${item.ratingScore.toStringAsFixed(1)}'
                      : '暂无评分',
                ),
                if (item.rank > 0)
                  _MetaPill(
                    icon: Icons.emoji_events_rounded,
                    label: 'Bangumi #${item.rank}',
                  ),
                if (item.airDate.isNotEmpty)
                  _MetaPill(
                    icon: Icons.calendar_month_rounded,
                    label: item.airDate,
                  ),
              ],
            ),
            SizedBox(height: tight ? 8 : 12),
            Flexible(
              child: Text(
                summary,
                maxLines: tight ? (compact ? 2 : 1) : (compact ? 3 : 2),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: tight ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
            ),
            SizedBox(height: tight ? 10 : 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('打开详情'),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: '换一组精选',
                  onPressed: loading ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightThumbnailRail extends StatelessWidget {
  const _SpotlightThumbnailRail({
    required this.items,
    required this.selectedIndex,
    required this.onOpenDetails,
    required this.onSelect,
  });

  final List<BangumiItem> items;
  final int selectedIndex;
  final ValueChanged<BangumiItem> onOpenDetails;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = _spotlightThumbnailWidth(
          availableWidth: constraints.maxWidth,
          itemCount: items.length,
          gap: _spotlightThumbnailGap,
        );

        return SizedBox(
          height: _spotlightThumbnailRailHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: _spotlightThumbnailGap),
            itemBuilder: (context, index) => SizedBox(
              width: itemWidth,
              child: _SpotlightThumbnailButton(
                item: items[index],
                selected: index == selectedIndex,
                onHover: (hovered) {
                  if (hovered && index != selectedIndex) {
                    onSelect(index);
                  }
                },
                onOpenDetails: () => onOpenDetails(items[index]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpotlightThumbnailButton extends StatelessWidget {
  const _SpotlightThumbnailButton({
    required this.item,
    required this.selected,
    required this.onHover,
    required this.onOpenDetails,
  });

  final BangumiItem item;
  final bool selected;
  final ValueChanged<bool> onHover;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onHover: onHover,
        onTap: onOpenDetails,
        child: AnimatedContainer(
          duration: KazumiDurations.fast,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.64)
                : scheme.surfaceContainerHigh.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.62)
                  : scheme.outlineVariant.withValues(alpha: 0.34),
              width: selected ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.all(7),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _BangumiPosterImage(
                  item: item,
                  width: 42,
                  height: 62,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bangumiTitle(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bangumiMeta(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPoster extends StatelessWidget {
  const _FeaturedPoster({
    required this.item,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final BangumiItem item;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: item.id,
          flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BangumiPosterImage(item: item, width: width, height: height),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.28),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BangumiPosterImage extends StatelessWidget {
  const _BangumiPosterImage({
    required this.item,
    required this.width,
    required this.height,
  });

  final BangumiItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _bangumiPosterImage(item);
    if (imageUrl.isEmpty) {
      return _ImageFallbackSurface(width: width, height: height);
    }

    return NetworkImgLayer(
      src: imageUrl,
      width: width,
      height: height,
      quality: 150,
      fadeInDuration: KazumiDurations.fast,
      fadeOutDuration: KazumiDurations.fast,
    );
  }
}

class _ImageFallbackSurface extends StatelessWidget {
  const _ImageFallbackSurface({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackSize =
        math.min(width.isFinite ? width : 120, height.isFinite ? height : 120);

    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.70),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: fallbackSize * 0.24,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.54),
        ),
      ),
    );
  }
}

class _TrendCategoryBar extends StatelessWidget {
  const _TrendCategoryBar({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.loading,
    required this.child,
  });

  final String title;
  final String subtitle;
  final int count;
  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _DesktopContentFrame(
      top: 18,
      bottom: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _ContentWidthMetrics.from(constraints.maxWidth);
          final compactHeader = metrics.contentWidth < 720;

          return SizedBox(
            width: metrics.contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendHeader(context, scheme, compactHeader),
                const SizedBox(height: 14),
                _MediaFilterHeader(child: child),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendHeader(
    BuildContext context,
    ColorScheme scheme,
    bool compact,
  ) {
    final countBadge = _TrendCountBadge(
      label: loading
          ? '加载中'
          : count == 0
              ? '暂无条目'
              : '$count 部作品',
      loading: loading,
    );
    final titleBlock = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
    final leading = Icon(
      Icons.local_fire_department_rounded,
      size: 22,
      color: scheme.primary,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: leading,
              ),
              const SizedBox(width: 8),
              titleBlock,
            ],
          ),
          const SizedBox(height: 10),
          countBadge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: 8),
        titleBlock,
        const SizedBox(width: 14),
        countBadge,
      ],
    );
  }
}

class _TrendCountBadge extends StatelessWidget {
  const _TrendCountBadge({
    required this.label,
    required this.loading,
  });

  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaFilterHeader extends StatelessWidget {
  const _MediaFilterHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: AnimatedSize(
            duration: KazumiDurations.fast,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
  }
}

class _PosterFilterSheet extends StatefulWidget {
  const _PosterFilterSheet({required this.initialFilter});

  final PopularFilterState initialFilter;

  @override
  State<_PosterFilterSheet> createState() => _PosterFilterSheetState();
}

class _PosterFilterSheetState extends State<_PosterFilterSheet> {
  late PopularFilterState _draft = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: KazumiGlassSurface(
        borderRadius: KazumiRadius.containerBorder,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '海报墙筛选',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _draft = const PopularFilterState());
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FilterSection<PopularSortMode>(
                title: '排序',
                values: PopularSortMode.values,
                selected: _draft.sort,
                labelFor: (value) => value.label,
                onSelected: (value) {
                  setState(() => _draft = _draft.copyWith(sort: value));
                },
              ),
              const SizedBox(height: 14),
              _FilterSection<PopularYearFilter>(
                title: '年份',
                values: PopularYearFilter.values,
                selected: _draft.year,
                labelFor: (value) => value.label,
                onSelected: (value) {
                  setState(() => _draft = _draft.copyWith(year: value));
                },
              ),
              const SizedBox(height: 14),
              _FilterSection<PopularAirStatusFilter>(
                title: '状态',
                values: PopularAirStatusFilter.values,
                selected: _draft.status,
                labelFor: (value) => value.label,
                onSelected: (value) {
                  setState(() => _draft = _draft.copyWith(status: value));
                },
              ),
              const SizedBox(height: 14),
              _FilterSection<PopularVisibilityFilter>(
                title: '只看',
                values: PopularVisibilityFilter.values,
                selected: _draft.visibility,
                labelFor: (value) => value.label,
                onSelected: (value) {
                  setState(() => _draft = _draft.copyWith(visibility: value));
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: const Text('应用'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelFor(value)),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopContentFrame extends StatelessWidget {
  const _DesktopContentFrame({
    required this.child,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: KazumiDesktopPageFrame(
        maxWidth: double.infinity,
        child: child,
      ),
    );
  }
}

class _ContentWidthMetrics {
  const _ContentWidthMetrics({required this.contentWidth});

  final double contentWidth;

  factory _ContentWidthMetrics.from(double viewportWidth) {
    return _ContentWidthMetrics(contentWidth: viewportWidth);
  }
}

class _ContinueWatchingTile extends StatelessWidget {
  const _ContinueWatchingTile({
    required this.history,
    required this.onDelete,
  });

  final History history;
  final VoidCallback onDelete;

  void _showDeleteMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<void>(
          onTap: onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 10),
              Text('删除记录'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Offset? secondaryTapPosition;

    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          secondaryTapPosition = event.position;
        }
      },
      child: GestureDetector(
        onSecondaryTap: () {
          _showDeleteMenu(context, secondaryTapPosition ?? Offset.zero);
        },
        onLongPressStart: (details) {
          _showDeleteMenu(context, details.globalPosition);
        },
        child: BangumiHistoryCardV(
          historyItem: history,
          onDeleted: onDelete,
        ),
      ),
    );
  }
}

class _SkeletonSpotlight extends StatelessWidget {
  const _SkeletonSpotlight({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 306,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(KazumiRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _SkeletonBlock(
              width: 170,
              height: double.infinity,
              radius: 14,
              scheme: scheme,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkeletonBlock(
                    width: 112,
                    height: 30,
                    radius: 999,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 18),
                  _SkeletonBlock(
                    width: 420,
                    height: 36,
                    radius: 10,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  _SkeletonBlock(
                    width: 560,
                    height: 16,
                    radius: 8,
                    scheme: scheme,
                    opacity: 0.62,
                  ),
                  const SizedBox(height: 8),
                  _SkeletonBlock(
                    width: 520,
                    height: 16,
                    radius: 8,
                    scheme: scheme,
                    opacity: 0.48,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      for (var index = 0; index < 4; index++) ...[
                        Expanded(
                          child: _SkeletonBlock(
                            width: double.infinity,
                            height: _spotlightThumbnailRailHeight,
                            radius: 12,
                            scheme: scheme,
                            opacity: 0.72,
                          ),
                        ),
                        if (index != 3)
                          const SizedBox(width: _spotlightThumbnailGap),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPosterTile extends StatelessWidget {
  const _SkeletonPosterTile({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(
            width: 150,
            height: 216,
            radius: 12,
            scheme: scheme,
          ),
          const SizedBox(height: 8),
          _SkeletonBlock(
            width: 126,
            height: 13,
            radius: 6,
            scheme: scheme,
            opacity: 0.58,
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.radius,
    required this.scheme,
    this.opacity = 1,
  });

  final double width;
  final double height;
  final double radius;
  final ColorScheme scheme;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.84 * opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

String _bangumiTitle(BangumiItem item) {
  return item.nameCn.isNotEmpty ? item.nameCn : item.name;
}

String _bangumiMeta(BangumiItem item) {
  if (item.ratingScore > 0) {
    return '评分 ${item.ratingScore.toStringAsFixed(1)}';
  }
  if (item.rank > 0) {
    return 'Bangumi #${item.rank}';
  }
  if (item.airDate.isNotEmpty) {
    return item.airDate;
  }
  return '暂无评分';
}

String _bangumiPosterImage(BangumiItem item) {
  return bestBangumiPosterImage(item.images);
}

String bestBangumiPosterImage(Map<String, String> images) {
  for (final key in ['large', 'common', 'medium', 'small', 'grid']) {
    final value = images[key]?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

double _spotlightThumbnailWidth({
  required double availableWidth,
  required int itemCount,
  required double gap,
}) {
  if (itemCount <= 0) return _spotlightThumbnailMinimumWidth;
  final ideal =
      (availableWidth - gap * (itemCount - 1)) / math.max(1, itemCount);
  return ideal.clamp(
    _spotlightThumbnailMinimumWidth,
    _spotlightThumbnailPreferredWidth,
  );
}
