import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/appbar/desktop_window_controls.dart';
import 'package:kazumi/bean/card/bangumi_history_card.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/widget/custom_dropdown_menu.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/popular/popular_layout.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;

class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with AutomaticKeepAliveClientMixin {
  DateTime? _lastPressedAt;
  late NavigationBarState navigationBarState;
  final FocusNode _focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final PopularController popularController = Modular.get<PopularController>();
  final HistoryController historyController = Modular.get<HistoryController>();
  final PageController _featuredController =
      PageController(viewportFraction: 0.85);
  int _featuredPage = 0;
  final GlobalKey selectorKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
    _featuredController.addListener(() {
      if (mounted)
        setState(() => _featuredPage = _featuredController.page?.round() ?? 0);
    });
    if (popularController.trendList.isEmpty) {
      popularController.queryBangumiByTrend();
    }
    historyController.init();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    scrollController.removeListener(scrollListener);
    _featuredController.dispose();
    super.dispose();
  }

  void scrollListener() {
    popularController.scrollOffset = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !popularController.isLoadingMore) {
      if (popularController.currentTag != '') {
        popularController.queryBangumiByTag();
      } else {
        popularController.queryBangumiByTrend();
      }
    }
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
        body: Observer(builder: (_) {
          final list = popularController.currentTag == ''
              ? popularController.trendList
              : popularController.bangumiList;
          if (popularController.isTimeOut && list.isEmpty) {
            return Center(
              child: GeneralErrorWidget(
                errMsg: 'Nothing found',
                actions: [
                  GeneralErrorButton(
                      onPressed: () => popularController.queryBangumiByTrend(),
                      text: 'Retry')
                ],
              ),
            );
          }
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              _buildAppBar(scheme),
              if (list.isNotEmpty) ...[
                _buildSectionHeader('For You', Icons.auto_awesome_rounded),
                _buildFeaturedRow(scheme, list),
              ],
              _buildContinueWatchingStrip(),
              if (list.isNotEmpty)
                _buildSectionHeader(
                    'Popular', Icons.local_fire_department_rounded),
              _buildTagChips(scheme),
              if (popularController.isLoadingMore && list.isEmpty)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()))),
              _buildGrid(list),
              if (popularController.isLoadingMore)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))))),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme scheme) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: KazumiElevations.subtle,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      actions: [
        DesktopWindowActionRail(
          actions: [
            IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Modular.to.pushNamed('/search/')),
            IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => Modular.to.pushNamed('/settings/history/')),
          ],
          trailingSpacing: 4,
        ),
      ],
      flexibleSpace: SafeArea(
        bottom: false,
        child: dtb.DragToMoveArea(
            child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Observer(builder: (_) {
                final isTrend = popularController.currentTag == '';
                return InkWell(
                    key: selectorKey,
                    borderRadius: BorderRadius.circular(8),
                    onTap: showTagMenu,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                                  colors: [scheme.primary, scheme.tertiary])
                              .createShader(b),
                          child: Text(
                              isTrend
                                  ? 'Discover'
                                  : popularController.currentTag,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: -0.5))),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 22, color: scheme.primary),
                    ]));
              })),
        )),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(child: _buildSectionHeaderBox(title, icon));
  }

  Widget _buildSectionHeaderBox(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: scheme.onPrimaryContainer)),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 0)),
      ]),
    );
  }

  Widget _buildFeaturedRow(ColorScheme scheme, List list) {
    return SliverToBoxAdapter(
        child: SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _featuredController,
              padEnds: true,
              itemCount: (list.length / 3).ceil().clamp(1, 8),
              itemBuilder: (context, pageIdx) {
                final item = list.isNotEmpty && pageIdx * 3 < list.length
                    ? list[pageIdx * 3]
                    : null;
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(fit: StackFit.expand, children: [
                          if (item != null)
                            Hero(
                                tag: 'featured_${item.id}',
                                child: Image.network(item.images['large'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color:
                                            scheme.surfaceContainerHighest))),
                          Positioned.fill(
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8)
                              ],
                                          stops: const [
                                0.4,
                                1
                              ])))),
                          if (item != null)
                            Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          item.nameCn.isNotEmpty
                                              ? item.nameCn
                                              : item.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: scheme.primary
                                                  .withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(
                                              'Score ${item.ratingScore}',
                                              style: TextStyle(
                                                  color: scheme.onPrimary,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                    ])),
                          Positioned.fill(
                              child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(onTap: () {
                                    if (item != null)
                                      Modular.to
                                          .pushNamed('/info/', arguments: item);
                                  }))),
                        ])));
              },
            )));
  }

  Widget _buildContinueWatchingStrip() {
    return Observer(builder: (context) {
      final histories = historyController.histories.toList()
        ..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
      if (histories.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeaderBox(
                'Continue Watching', Icons.play_circle_fill_rounded),
            SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: histories.length > 12 ? 12 : histories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final history = histories[index];
                  return SizedBox(
                    width: 320,
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
    });
  }

  Widget _buildTagChips(ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _tagChip(
              'Popular',
              popularController.currentTag == '',
              scheme,
              onTap: () {
                if (popularController.currentTag != '') {
                  popularController.setCurrentTag('');
                  popularController.clearBangumiList();
                  if (popularController.trendList.isEmpty) {
                    popularController.queryBangumiByTrend();
                  }
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
            ...defaultAnimeTags.map(
              (tag) => _tagChip(
                tag,
                popularController.currentTag == tag,
                scheme,
                onTap: () {
                  if (popularController.currentTag != tag) {
                    popularController.setCurrentTag(tag);
                    scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    popularController.queryBangumiByTag(type: 'init');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String label, bool selected, ColorScheme scheme,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.crossAxisExtent;
        final crossCount = popularPosterGridColumnCount(contentWidth);
        final gap = popularPosterGridGap(contentWidth);
        final textHeight = popularPosterGridTextHeight(contentWidth);
        final horizontalPadding = contentWidth >= 1440 ? 20.0 : 12.0;
        final availableWidth = contentWidth - horizontalPadding * 2;
        final posterWidth =
            (availableWidth - gap * (crossCount - 1)) / crossCount;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              crossAxisCount: crossCount,
              mainAxisExtent: posterWidth / 0.68 + textHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => index >= list.length
                  ? null
                  : BangumiCardV(bangumiItem: list[index]),
              childCount: list.length,
            ),
          ),
        );
      },
    );
  }

  Future<void> showTagMenu() async {
    final RenderBox renderBox =
        selectorKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final selected = await Navigator.push<String>(
        context,
        PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.transparent,
            pageBuilder: (context, animation, secondaryAnimation) =>
                CustomDropdownMenu(
                    offset: offset,
                    buttonSize: size,
                    animation: animation,
                    maxWidth: 80,
                    items: ['', ...defaultAnimeTags],
                    itemBuilder: (item) => item.isEmpty ? 'Discover' : item),
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 150)));
    if (selected == null) return;
    if (selected == '' && popularController.currentTag != '') {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      popularController.setCurrentTag('');
      popularController.clearBangumiList();
      if (popularController.trendList.isEmpty)
        await popularController.queryBangumiByTrend();
    } else if (selected != '' && selected != popularController.currentTag) {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      popularController.setCurrentTag(selected);
      await popularController.queryBangumiByTag(type: 'init');
    }
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
