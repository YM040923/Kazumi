import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_sync_plan.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:provider/provider.dart';

class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage>
    with SingleTickerProviderStateMixin {
  final CollectController collectController = Modular.get<CollectController>();
  late final NavigationBarState navigationBarState;
  late final TabController tabController;
  bool showDelete = false;
  bool syncCollectiblesing = false;
  Box setting = GStorage.setting;

  final List<_CollectTabData> tabs = const <_CollectTabData>[
    _CollectTabData(
      label: '\u5728\u770b',
      icon: Icons.play_circle_rounded,
    ),
    _CollectTabData(
      label: '\u60f3\u770b',
      icon: Icons.star_rounded,
    ),
    _CollectTabData(
      label: '\u6401\u7f6e',
      icon: Icons.pause_circle_rounded,
    ),
    _CollectTabData(
      label: '\u770b\u8fc7',
      icon: Icons.done_all_rounded,
    ),
    _CollectTabData(
      label: '\u629b\u5f03',
      icon: Icons.heart_broken_rounded,
    ),
  ];

  Future<bool> _syncBangumiWithProgress({
    required ValueNotifier<double?> progressValue,
    required ValueNotifier<String> progressText,
  }) async {
    progressText.value = '\u51c6\u5907\u540c\u6b65 Bangumi \u6536\u85cf...';
    progressValue.value = null;

    await Future<void>.delayed(const Duration(milliseconds: 80));

    return collectController.syncCollectiblesBangumi(
      showSuccessToast: false,
      onProgress: (message, current, total) {
        progressText.value = total > 0 ? '$message ($current/$total)' : message;
        if (total > 0) {
          progressValue.value = (current / total).clamp(0.0, 1.0);
        } else {
          progressValue.value = null;
        }
      },
    );
  }

  void _showFullSyncProgressDialog({
    required ValueNotifier<double?> progressValue,
    required ValueNotifier<String> progressText,
  }) {
    unawaited(
      KazumiDialog.show(
        clickMaskDismiss: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u6536\u85cf\u5168\u91cf\u540c\u6b65\u4e2d',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: progressText,
                        builder: (_, value, __) => Text(value),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<double?>(
                        valueListenable: progressValue,
                        builder: (_, value, __) =>
                            LinearProgressIndicator(value: value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildFullSyncSummary({
    required CollectSyncPlan plan,
    required bool webDavSynced,
    required bool bangumiSynced,
    required bool webDavUploaded,
  }) {
    final List<String> states = [];
    if (plan.shouldSyncWebDavCollectibles) {
      states.add(
        webDavSynced
            ? 'WebDav \u5df2\u540c\u6b65'
            : 'WebDav \u672a\u5b8c\u6210',
      );
    }
    if (plan.shouldSyncBangumi) {
      states.add(
        bangumiSynced
            ? 'Bangumi \u5df2\u540c\u6b65'
            : 'Bangumi \u672a\u5b8c\u6210',
      );
    }
    if (plan.shouldSyncWebDavCollectibles &&
        plan.shouldSyncBangumi &&
        webDavSynced &&
        bangumiSynced) {
      states.add(
        webDavUploaded
            ? 'WebDav \u5df2\u56de\u4f20\u6700\u65b0\u6570\u636e'
            : 'WebDav \u672a\u56de\u4f20\u6700\u65b0\u6570\u636e',
      );
    }
    return states.join('\uff0c');
  }

  Future<void> _runFullSync({
    required CollectSyncPlan plan,
  }) async {
    final ValueNotifier<double?> progressValue = ValueNotifier<double?>(null);
    final ValueNotifier<String> progressText = ValueNotifier<String>(
      '\u51c6\u5907\u5f00\u59cb\u540c\u6b65\u6536\u85cf...',
    );

    _showFullSyncProgressDialog(
      progressValue: progressValue,
      progressText: progressText,
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));

    bool webDavSynced = false;
    bool bangumiSynced = false;
    bool webDavUploaded = false;

    try {
      if (plan.shouldSyncWebDavCollectibles) {
        progressText.value = '\u6b63\u5728\u540c\u6b65 WebDav \u6536\u85cf...';
        progressValue.value = null;
        webDavSynced =
            await collectController.syncCollectibles(showSuccessToast: false);
      }

      if (plan.shouldSyncBangumi) {
        bangumiSynced = await _syncBangumiWithProgress(
          progressValue: progressValue,
          progressText: progressText,
        );
      }

      if (plan.shouldUploadWebDavAfterBangumi(
        webDavSynced: webDavSynced,
        bangumiSynced: bangumiSynced,
      )) {
        progressText.value =
            '\u6b63\u5728\u56de\u4f20\u6700\u65b0\u6536\u85cf\u5230 WebDav...';
        progressValue.value = null;
        webDavUploaded = await collectController.uploadCollectiblesToWebDav(
          showSuccessToast: false,
        );
      }
    } finally {
      if (KazumiDialog.observer.hasKazumiDialog) {
        KazumiDialog.dismiss();
      }
      progressValue.dispose();
      progressText.dispose();
    }

    KazumiDialog.showToast(
      message: _buildFullSyncSummary(
        plan: plan,
        webDavSynced: webDavSynced,
        bangumiSynced: bangumiSynced,
        webDavUploaded: webDavUploaded,
      ),
    );
  }

  Future<void> _runCollectSync() async {
    final bool webDavenable = await setting.get(
      SettingBoxKey.webDavEnable,
      defaultValue: false,
    );
    final bool webDavCollectEnable = await setting.get(
      SettingBoxKey.webDavEnableCollect,
      defaultValue: false,
    );
    final bool bgmSyncEnable = await setting.get(
      SettingBoxKey.bangumiSyncEnable,
      defaultValue: false,
    );
    final syncPlan = CollectSyncPlan(
      webDavEnabled: webDavenable,
      webDavCollectiblesEnabled: webDavCollectEnable,
      bangumiEnabled: bgmSyncEnable,
    );
    if (!syncPlan.canSync) {
      KazumiDialog.showToast(
        message:
            '\u540c\u6b65\u529f\u80fd\u4e0d\u53ef\u7528\uff0c\u8bf7\u81f3\u5c11\u5f00\u542f\u4e00\u4e2a\u540c\u6b65\u529f\u80fd',
      );
      return;
    }
    if (showDelete) {
      KazumiDialog.showToast(
        message: '\u7f16\u8f91\u6a21\u5f0f\u65e0\u6cd5\u6267\u884c\u540c\u6b65',
      );
      return;
    }
    if (syncCollectiblesing) {
      return;
    }
    setState(() {
      syncCollectiblesing = true;
    });
    try {
      await _runFullSync(
        plan: syncPlan,
      );
    } finally {
      if (mounted) {
        setState(() {
          syncCollectiblesing = false;
        });
      }
    }
  }

  void _goDiscover() {
    navigationBarState.updateSelectedIndex(0);
    Modular.to.navigate('/tab/popular/');
  }

  void onBackPressed(BuildContext context) {
    if (syncCollectiblesing) {
      return;
    }
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
    _goDiscover();
  }

  @override
  void initState() {
    super.initState();
    collectController.loadCollectibles();
    tabController = TabController(vsync: this, length: tabs.length);
    navigationBarState =
        Provider.of<NavigationBarState>(context, listen: false);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || syncCollectiblesing) {
          return;
        }
        onBackPressed(context);
      },
      child: Scaffold(
        body: Observer(
          builder: (context) {
            final groupedCollectibles =
                _groupCollectibles(collectController.collectibles);
            final counts = groupedCollectibles.map((items) => items.length);
            final totalCount = collectController.collectibles.length;

            return SafeArea(
              top: false,
              child: Column(
                children: [
                  _CollectHeader(
                    controller: tabController,
                    tabs: tabs,
                    counts: counts.toList(growable: false),
                    totalCount: totalCount,
                    showDelete: showDelete,
                    syncCollectiblesing: syncCollectiblesing,
                    onSync: _runCollectSync,
                    onToggleEdit: totalCount == 0
                        ? null
                        : () {
                            setState(() {
                              showDelete = !showDelete;
                            });
                          },
                  ),
                  Expanded(
                    child: totalCount == 0
                        ? KazumiDesktopPageFrame(
                            maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                            child: _CollectEmptyState(
                              onDiscover: _goDiscover,
                            ),
                          )
                        : TabBarView(
                            controller: tabController,
                            children: [
                              for (final items in groupedCollectibles)
                                _CollectGrid(
                                  items: items,
                                  showDelete: showDelete,
                                  onDiscover: _goDiscover,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<List<CollectedBangumi>> _groupCollectibles(
    List<CollectedBangumi> collectedBangumiList,
  ) {
    final groupedCollectibles =
        List.generate(tabs.length, (_) => <CollectedBangumi>[]);

    for (final element in collectedBangumiList) {
      final index = element.type - 1;
      if (index >= 0 && index < groupedCollectibles.length) {
        groupedCollectibles[index].add(element);
      }
    }

    for (final items in groupedCollectibles) {
      items.sort(
        (a, b) => b.time.millisecondsSinceEpoch.compareTo(
          a.time.millisecondsSinceEpoch,
        ),
      );
    }

    return groupedCollectibles;
  }
}

class _CollectHeader extends StatelessWidget {
  const _CollectHeader({
    required this.controller,
    required this.tabs,
    required this.counts,
    required this.totalCount,
    required this.showDelete,
    required this.syncCollectiblesing,
    required this.onSync,
    required this.onToggleEdit,
  });

  final TabController controller;
  final List<_CollectTabData> tabs;
  final List<int> counts;
  final int totalCount;
  final bool showDelete;
  final bool syncCollectiblesing;
  final VoidCallback onSync;
  final VoidCallback? onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.62),
      child: dtb.DragToMoveArea(
        child: KazumiDesktopHeaderFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KazumiDesktopHeaderTopRow(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.72,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.collections_bookmark_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u8ffd\u756a',
                              style: textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              totalCount == 0
                                  ? '\u8fd8\u6ca1\u6709\u8ffd\u756a'
                                  : '\u5171 $totalCount \u90e8\u4f5c\u54c1\uff0c\u6309\u6536\u85cf\u72b6\u6001\u5206\u7c7b\u6574\u7406',
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
                      const SizedBox(width: 16),
                      _CollectPageActions(
                        showDelete: showDelete,
                        syncCollectiblesing: syncCollectiblesing,
                        onSync: onSync,
                        onToggleEdit: onToggleEdit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: KazumiGlassSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    showShadow: false,
                    child: TabBar(
                      controller: controller,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(KazumiRadius.sm),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      tabs: [
                        for (int i = 0; i < tabs.length; i++)
                          _CollectTab(
                            data: tabs[i],
                            count: counts.length > i ? counts[i] : 0,
                          ),
                      ],
                    ),
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

class _CollectPageActions extends StatelessWidget {
  const _CollectPageActions({
    required this.showDelete,
    required this.syncCollectiblesing,
    required this.onSync,
    required this.onToggleEdit,
  });

  final bool showDelete;
  final bool syncCollectiblesing;
  final VoidCallback onSync;
  final VoidCallback? onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        FilledButton.tonalIcon(
          onPressed: syncCollectiblesing ? null : onSync,
          icon: syncCollectiblesing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
          label: Text(
            syncCollectiblesing ? '\u540c\u6b65\u4e2d' : '\u540c\u6b65',
          ),
        ),
        OutlinedButton.icon(
          onPressed: onToggleEdit,
          icon: Icon(
            showDelete ? Icons.done_rounded : Icons.edit_outlined,
          ),
          label: Text(
            showDelete ? '\u5b8c\u6210' : '\u7f16\u8f91',
          ),
        ),
      ],
    );
  }
}

class _CollectTab extends StatelessWidget {
  const _CollectTab({
    required this.data,
    required this.count,
  });

  final _CollectTabData data;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 18),
            const SizedBox(width: 7),
            Text(data.label),
            const SizedBox(width: 7),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectGrid extends StatelessWidget {
  const _CollectGrid({
    required this.items,
    required this.showDelete,
    required this.onDiscover,
  });

  final List<CollectedBangumi> items;
  final bool showDelete;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return KazumiDesktopPageFrame(
        maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
        child: _CollectEmptyState(
          title: '\u8fd9\u4e2a\u5206\u7c7b\u8fd8\u6ca1\u6709\u4f5c\u54c1',
          message:
              '\u4ece\u53d1\u73b0\u9875\u6253\u5f00\u4f5c\u54c1\uff0c\u7136\u540e\u628a\u5b83\u52a0\u5230\u5bf9\u5e94\u7684\u8ffd\u756a\u72b6\u6001\u3002',
          onDiscover: onDiscover,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.crossAxisExtent;
            final contentWidth = (viewportWidth - 48)
                .clamp(0.0, KazumiDesktopShell.mediaPageMaxWidth)
                .toDouble();
            final horizontalPadding = (viewportWidth - contentWidth) / 2;
            final columns = _collectGridColumns(contentWidth);
            final gap = _collectGridGap(contentWidth);
            final posterWidth = (contentWidth - gap * (columns - 1)) / columns;

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                40,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  crossAxisCount: columns,
                  mainAxisExtent: posterWidth / 0.68 + 58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: BangumiCardV(
                            enableHero: false,
                            bangumiItem: item.bangumiItem,
                            canTap: !showDelete,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: AnimatedScale(
                            duration: KazumiDurations.fast,
                            scale: showDelete ? 1 : 0.82,
                            child: AnimatedOpacity(
                              duration: KazumiDurations.fast,
                              opacity: showDelete ? 1 : 0,
                              child: IgnorePointer(
                                ignoring: !showDelete,
                                child: _CollectEditBadge(
                                  bangumi: item,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: items.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CollectEditBadge extends StatelessWidget {
  const _CollectEditBadge({
    required this.bangumi,
  });

  final CollectedBangumi bangumi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      elevation: 4,
      child: SizedBox.square(
        dimension: 40,
        child: CollectButton(
          bangumiItem: bangumi.bangumiItem,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _CollectEmptyState extends StatelessWidget {
  const _CollectEmptyState({
    required this.onDiscover,
    this.title = '\u8fd8\u6ca1\u6709\u8ffd\u756a',
    this.message =
        '\u4ece\u53d1\u73b0\u9875\u6253\u5f00\u4f5c\u54c1\uff0c\u9009\u62e9\u60f3\u770b\u3001\u5728\u770b\u6216\u770b\u8fc7\u6765\u5efa\u7acb\u81ea\u5df1\u7684\u5a92\u4f53\u5e93\u3002',
  });

  final String title;
  final String message;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: KazumiGlassSurface(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.collections_bookmark_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
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
                onPressed: onDiscover,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('\u53bb\u53d1\u73b0'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectTabData {
  const _CollectTabData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

int _collectGridColumns(double contentWidth) {
  if (contentWidth >= 1500) return 8;
  if (contentWidth >= 1260) return 7;
  if (contentWidth >= 1040) return 6;
  if (contentWidth >= 820) return 5;
  if (contentWidth >= 620) return 4;
  return 3;
}

double _collectGridGap(double contentWidth) {
  if (contentWidth >= 1260) return 22;
  if (contentWidth >= 820) return 18;
  return 14;
}
