import 'dart:io';
import 'dart:ui';
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/bean/card/bangumi_info_card.dart';
import 'package:kazumi/pages/info/source_sheet.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:kazumi/pages/info/info_tabview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;

const double _detailSegmentedTabBarHeight = 64;

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  static const Duration _minimumBangumiInfoLoadingDuration =
      Duration(milliseconds: 600);

  /// Don't use modular singleton here. We may have multiple info pages.
  /// Use a new instance of InfoController for each info page.
  final InfoController infoController = InfoController();
  final VideoPageController videoPageController =
      Modular.get<VideoPageController>();
  final PluginsController pluginsController = Modular.get<PluginsController>();
  final HistoryController historyController = Modular.get<HistoryController>();
  late TabController sourceTabController;
  late TabController infoTabController;
  late bool showRating;

  bool charactersIsLoading = false;
  bool charactersQueryTimeout = false;
  bool charactersIsEmpty = false;
  bool staffIsLoading = false;
  bool staffQueryTimeout = false;
  bool staffIsEmpty = false;
  bool episodesIsLoading = false;
  bool episodesQueryTimeout = false;
  bool episodesIsEmpty = false;
  bool episodesLoaded = false;
  int selectedEpisodeRoad = 0;
  bool _showBangumiInfoSkeleton = false;
  bool _episodeSourceSearchOpenedForCurrentSelection = false;

  final inputBangumiIten = Modular.args.data as BangumiItem;

  bool get _isShowingBangumiInfoSkeleton =>
      infoController.isLoading || _showBangumiInfoSkeleton;

  double _detailHeaderHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= LayoutBreakpoint.medium['width']!) {
      return 430;
    }
    if (width >= LayoutBreakpoint.compact['width']!) {
      return 388;
    }
    return 338;
  }

  bool _needsBangumiInfoRefresh(BangumiItem bangumiItem) {
    final votesCount = bangumiItem.votesCount;
    final missingVoteDistribution =
        votesCount.isEmpty || bangumiItem.votes <= 0 || votesCount.length < 10;
    return bangumiItem.summary == '' || missingVoteDistribution;
  }

  Future<void> loadCharacters() async {
    if (charactersIsLoading) return;
    setState(() {
      charactersIsLoading = true;
      charactersQueryTimeout = false;
      charactersIsEmpty = false;
    });
    try {
      await infoController
          .queryBangumiCharactersByID(infoController.bangumiItem.id);
      if (mounted) {
        setState(() {
          charactersIsLoading = false;
          if (infoController.characterList.isEmpty) {
            charactersIsEmpty = true;
          }
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load characters', error: e);
      if (mounted) {
        setState(() {
          charactersIsLoading = false;
          charactersQueryTimeout = true;
        });
      }
    }
  }

  Future<void> loadStaff() async {
    if (staffIsLoading) return;
    setState(() {
      staffIsLoading = true;
      staffQueryTimeout = false;
      staffIsEmpty = false;
    });
    try {
      await infoController
          .queryBangumiStaffsByID(infoController.bangumiItem.id);
      if (mounted) {
        setState(() {
          staffIsLoading = false;
          if (infoController.staffList.isEmpty) {
            staffIsEmpty = true;
          }
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load staff', error: e);
      if (mounted) {
        setState(() {
          staffIsLoading = false;
          staffQueryTimeout = true;
        });
      }
    }
  }

  History? _latestPlayableHistoryForBangumi() {
    final targetId = infoController.bangumiItem.id;
    final histories = historyController.histories.toList()
      ..sort((a, b) => b.lastWatchTime.compareTo(a.lastWatchTime));
    for (final history in histories) {
      if (history.bangumiItem.id == targetId &&
          history.adapterName.trim().isNotEmpty &&
          history.lastSrc.trim().isNotEmpty) {
        return history;
      }
    }
    return null;
  }

  Plugin? _findPluginByName(String pluginName) {
    for (final plugin in pluginsController.pluginList) {
      if (plugin.name == pluginName) {
        return plugin;
      }
    }
    return null;
  }

  Future<void> loadEpisodes() async {
    if (episodesIsLoading) return;

    historyController.init();
    final history = _latestPlayableHistoryForBangumi();
    if (history == null) {
      _openEpisodeSourceSearch();
      return;
    }

    final plugin = _findPluginByName(history.adapterName);
    if (plugin == null) {
      _openEpisodeSourceSearch();
      return;
    }

    setState(() {
      episodesIsLoading = true;
      episodesQueryTimeout = false;
      episodesIsEmpty = false;
    });

    try {
      videoPageController.bangumiItem = infoController.bangumiItem;
      videoPageController.currentPlugin = plugin;
      videoPageController.title = history.bangumiItem.nameCn.isEmpty
          ? history.bangumiItem.name
          : history.bangumiItem.nameCn;
      videoPageController.src = history.lastSrc;
      await videoPageController.queryRoads(history.lastSrc, plugin.name);
      final loadedRoads = videoPageController.roadList.length;
      final progress = history.progresses[history.lastWatchEpisode];
      final preferredRoad = progress?.road ?? 0;
      final boundedRoad = loadedRoads == 0
          ? 0
          : preferredRoad.clamp(0, loadedRoads - 1).toInt();
      final preferredEpisode = progress?.episode ?? history.lastWatchEpisode;
      final boundedEpisode = loadedRoads == 0
          ? 1
          : preferredEpisode
              .clamp(1, videoPageController.roadList[boundedRoad].data.length)
              .toInt();
      videoPageController.currentRoad = boundedRoad;
      videoPageController.currentEpisode = boundedEpisode;
      if (mounted) {
        setState(() {
          episodesIsLoading = false;
          episodesLoaded = true;
          episodesIsEmpty = videoPageController.roadList.isEmpty;
          selectedEpisodeRoad = boundedRoad;
        });
      }
    } catch (e) {
      KazumiLogger().e('InfoPage: failed to load episodes', error: e);
      if (mounted) {
        setState(() {
          episodesIsLoading = false;
          episodesLoaded = false;
          episodesQueryTimeout = true;
        });
      }
    }
  }

  void _openEpisodeSourceSearch() {
    if (_episodeSourceSearchOpenedForCurrentSelection) return;
    _episodeSourceSearchOpenedForCurrentSelection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || infoTabController.index != 0) return;
      _showSourceSheet(context);
    });
  }

  void _showSourceSheet(BuildContext context) {
    _episodeSourceSearchOpenedForCurrentSelection = true;
    showModalBottomSheet(
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.sizeOf(context).height >=
                LayoutBreakpoint.compact['height']!)
            ? MediaQuery.of(context).size.height * 3 / 4
            : MediaQuery.of(context).size.height,
        maxWidth: (MediaQuery.sizeOf(context).width >=
                LayoutBreakpoint.medium['width']!)
            ? MediaQuery.of(context).size.width * 9 / 16
            : MediaQuery.of(context).size.width,
      ),
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return SourceSheet(
          tabController: sourceTabController,
          infoController: infoController,
        );
      },
    );
  }

  void _selectEpisodeRoad(int road) {
    setState(() {
      selectedEpisodeRoad = road;
    });
  }

  void _playEpisode({required int road, required int episode}) {
    if (road < 0 || road >= videoPageController.roadList.length) {
      KazumiDialog.showToast(message: '选集不可用，请重新选择播放源');
      return;
    }
    if (episode < 1 ||
        episode > videoPageController.roadList[road].data.length) {
      KazumiDialog.showToast(message: '选集不可用，请重新选择播放源');
      return;
    }
    videoPageController.bangumiItem = infoController.bangumiItem;
    videoPageController.requestEpisodeSelection(episode: episode, road: road);
    Modular.to.pushNamed('/video/');
  }

  @override
  void initState() {
    super.initState();
    infoController.bangumiItem = inputBangumiIten;
    infoController.characterList.clear();
    infoController.staffList.clear();
    infoController.pluginSearchResponseList.clear();
    videoPageController.currentEpisode = 1;
    // Because the gap between different bangumi API response is too large, sometimes we need to query the bangumi info again
    // We need the type parameter to determine whether to attach the new data to the old data
    // We can't generally replace the old data with the new data, because the old data contains images url, update them will cause the image to reload and flicker
    if (_needsBangumiInfoRefresh(infoController.bangumiItem)) {
      _showBangumiInfoSkeleton = true;
      queryBangumiInfoByID(
        infoController.bangumiItem.id,
        type: 'attach',
        enforceMinimumLoadingDuration: true,
      );
    }
    sourceTabController =
        TabController(length: pluginsController.pluginList.length, vsync: this);
    infoTabController = TabController(length: 3, initialIndex: 0, vsync: this);
    showRating =
        GStorage.setting.get(SettingBoxKey.showRating, defaultValue: true);
    infoTabController.addListener(() {
      if (infoTabController.indexIsChanging) return;
      int index = infoTabController.index;
      if (index == 0 && !episodesLoaded && !episodesIsLoading) {
        loadEpisodes();
      }
      if (index == 1 &&
          infoController.characterList.isEmpty &&
          !charactersIsLoading &&
          !charactersIsEmpty &&
          !charactersQueryTimeout) {
        loadCharacters();
      }
      if (index == 2 &&
          infoController.staffList.isEmpty &&
          !staffIsLoading &&
          !staffIsEmpty &&
          !staffQueryTimeout) {
        loadStaff();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadEpisodes();
      }
    });
  }

  @override
  void dispose() {
    infoController.characterList.clear();
    infoController.staffList.clear();
    infoController.pluginSearchResponseList.clear();
    videoPageController.currentEpisode = 1;
    sourceTabController.dispose();
    infoTabController.dispose();
    super.dispose();
  }

  Future<void> queryBangumiInfoByID(
    int id, {
    String type = "init",
    bool enforceMinimumLoadingDuration = false,
  }) async {
    final loadingStartedAt = DateTime.now();
    try {
      await infoController.queryBangumiInfoByID(id, type: type);
    } catch (e) {
      KazumiLogger()
          .e('InfoController: failed to query bangumi info by ID', error: e);
    } finally {
      if (enforceMinimumLoadingDuration && mounted) {
        await _waitForMinimumBangumiInfoLoadingDuration(loadingStartedAt);
      }
      if (mounted) {
        setState(() {
          _showBangumiInfoSkeleton = false;
        });
      }
    }
  }

  Future<void> _waitForMinimumBangumiInfoLoadingDuration(
      DateTime loadingStartedAt) async {
    final elapsed = DateTime.now().difference(loadingStartedAt);
    final remaining = _minimumBangumiInfoLoadingDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  void _leaveInfoPage() {
    try {
      if (Modular.to.canPop()) {
        Modular.to.pop();
        return;
      }
    } catch (e) {
      KazumiLogger().w('InfoPage: modular pop failed', error: e);
    }
    Modular.to.navigate('/tab/popular/');
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = <String>['选集', '角色', '制作人员'];
    final bool showWindowButton = GStorage.setting
        .get(SettingBoxKey.showWindowButton, defaultValue: false);
    return PopScope(
      canPop: true,
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar.medium(
                    title: EmbeddedNativeControlArea(
                      child: dtb.DragToMoveArea(
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            infoController.bangumiItem.nameCn == ''
                                ? infoController.bangumiItem.name
                                : infoController.bangumiItem.nameCn,
                          ),
                        ),
                      ),
                    ),
                    automaticallyImplyLeading: false,
                    scrolledUnderElevation: 0.0,
                    leading: EmbeddedNativeControlArea(
                      child: IconButton(
                        tooltip: '返回',
                        onPressed: _leaveInfoPage,
                        icon: Icon(Icons.arrow_back),
                      ),
                    ),
                    actions: [
                      WindowControlInset(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (innerBoxIsScrolled)
                              EmbeddedNativeControlArea(
                                child: CollectButton(
                                  bangumiItem: infoController.bangumiItem,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            EmbeddedNativeControlArea(
                              child: IconButton(
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(
                                        'https://bangumi.tv/subject/${infoController.bangumiItem.id}'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.open_in_browser_rounded),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                    toolbarHeight: (Platform.isMacOS && showWindowButton)
                        ? kToolbarHeight + 22
                        : kToolbarHeight,
                    stretch: true,
                    centerTitle: false,
                    expandedHeight: (Platform.isMacOS && showWindowButton)
                        ? _detailHeaderHeight(context) +
                            _detailSegmentedTabBarHeight +
                            kToolbarHeight +
                            22
                        : _detailHeaderHeight(context) +
                            _detailSegmentedTabBarHeight +
                            kToolbarHeight,
                    collapsedHeight: (Platform.isMacOS && showWindowButton)
                        ? _detailSegmentedTabBarHeight +
                            kToolbarHeight +
                            MediaQuery.paddingOf(context).top +
                            22
                        : _detailSegmentedTabBarHeight +
                            kToolbarHeight +
                            MediaQuery.paddingOf(context).top,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Observer(builder: (context) {
                        final showBangumiInfoSkeleton =
                            _isShowingBangumiInfoSkeleton;
                        return Stack(
                          children: [
                            // No background image when loading to make loading looks better
                            if (!showBangumiInfoSkeleton)
                              Positioned.fill(
                                bottom: _detailSegmentedTabBarHeight,
                                child: IgnorePointer(
                                  child: _InfoHeaderBackground(
                                    imageUrl: infoController
                                            .bangumiItem.images['large'] ??
                                        '',
                                  ),
                                ),
                              ),
                            SafeArea(
                              bottom: false,
                              child: EmbeddedNativeControlArea(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        0, kToolbarHeight, 0, 0),
                                    child: BangumiInfoCardV(
                                      bangumiItem: infoController.bangumiItem,
                                      isLoading: showBangumiInfoSkeleton,
                                      showRating: showRating,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    forceElevated: innerBoxIsScrolled,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(
                        _detailSegmentedTabBarHeight,
                      ),
                      child: _DetailSegmentedTabBar(
                        controller: infoTabController,
                        tabs: tabs,
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Observer(builder: (context) {
              final showBangumiInfoSkeleton = _isShowingBangumiInfoSkeleton;
              return InfoTabView(
                tabController: infoTabController,
                bangumiItem: infoController.bangumiItem,
                episodesIsLoading: episodesIsLoading,
                episodesQueryTimeout: episodesQueryTimeout,
                episodesIsEmpty: episodesIsEmpty,
                episodesLoaded: episodesLoaded,
                selectedEpisodeRoad: selectedEpisodeRoad,
                roadList: videoPageController.roadList,
                charactersQueryTimeout: charactersQueryTimeout,
                charactersIsEmpty: charactersIsEmpty,
                staffQueryTimeout: staffQueryTimeout,
                staffIsEmpty: staffIsEmpty,
                loadEpisodes: loadEpisodes,
                openSourceSheet: () => _showSourceSheet(context),
                selectEpisodeRoad: _selectEpisodeRoad,
                playEpisode: _playEpisode,
                loadCharacters: loadCharacters,
                loadStaff: loadStaff,
                characterList: infoController.characterList,
                staffList: infoController.staffList,
                isLoading: showBangumiInfoSkeleton,
              );
            }),
          ),
          floatingActionButton: _SourceFloatingAction(
            onPressed: () => _showSourceSheet(context),
          ),
        ),
      ),
    );
  }
}

class _SourceFloatingAction extends StatelessWidget {
  const _SourceFloatingAction({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KazumiGlassSurface(
      borderRadius: BorderRadius.circular(999),
      blurSigma: 18,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.62 : 0.78,
      showShadow: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '播放源',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSegmentedTabBar extends StatelessWidget {
  const _DetailSegmentedTabBar({
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _detailSegmentedTabBarHeight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.42),
              ),
            ),
            child: TabBar(
              controller: controller,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.22),
                ),
              ),
              labelColor: scheme.onPrimaryContainer,
              unselectedLabelColor: scheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w700),
              tabs: tabs.map((name) => Tab(text: name)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoHeaderBackground extends StatelessWidget {
  const _InfoHeaderBackground({
    required this.imageUrl,
  });

  static const double _downsample = 0.5;
  static const double _blurSigma = 11.0;
  static const double _opacity = 0.5;
  static const double _edgeBleed = 32.0;
  static const double _bottomFeatherHeight = 48.0;

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        final rasterWidth = width * _downsample;
        final rasterHeight = (height + _edgeBleed) * _downsample;

        final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.8, 1],
                  ).createShader(bounds);
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(
                    child: Transform.scale(
                      scale: 1 / _downsample,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.low,
                      child: SizedBox(
                        width: rasterWidth,
                        height: rasterHeight,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: _blurSigma * _downsample,
                            sigmaY: _blurSigma * _downsample,
                          ),
                          child: NetworkImgLayer(
                            src: imageUrl,
                            width: rasterWidth,
                            height: rasterHeight,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            filterQuality: FilterQuality.low,
                            color: Colors.white.withValues(alpha: _opacity),
                            colorBlendMode: BlendMode.modulate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _bottomFeatherHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor.withValues(alpha: 0),
                        backgroundColor.withValues(alpha: 0.55),
                        backgroundColor,
                      ],
                      stops: const [0, 0.72, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
