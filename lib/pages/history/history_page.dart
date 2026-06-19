import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/appbar/window_control_inset.dart';
import 'package:kazumi/bean/card/bangumi_history_card.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/design/desktop_layout.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/design/kazumi_glass.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/utils/constants.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryController historyController = Modular.get<HistoryController>();

  bool showDelete = false;

  @override
  void initState() {
    super.initState();
    historyController.init();
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  void showHistoryClearDialog() {
    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('记录管理'),
          content: const Text('确认要清除所有历史记录吗?'),
          actions: [
            TextButton(
              onPressed: () {
                KazumiDialog.dismiss();
              },
              child: Text(
                '取消',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                KazumiDialog.dismiss();
                try {
                  historyController.clearAll();
                } catch (_) {}
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          onBackPressed(context);
        },
        child: Scaffold(
          body: SafeArea(
            top: false,
            bottom: false,
            child: WindowControlInset(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: KazumiDesktopPageFrame(
                      maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                      child: _HistoryHeader(
                        count: historyController.histories.length,
                        showDelete: showDelete,
                        hasHistory: historyController.histories.isNotEmpty,
                        onBack: () => Modular.to.pop(),
                        onToggleEdit: () {
                          setState(() {
                            showDelete = !showDelete;
                          });
                        },
                        onClearAll: showHistoryClearDialog,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: KazumiSpacing.md),
                  ),
                  if (historyController.histories.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: KazumiDesktopPageFrame(
                        maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
                        child: const _HistoryEmptyState(),
                      ),
                    )
                  else
                    contentGrid,
                  const SliverToBoxAdapter(
                    child: SizedBox(height: KazumiSpacing.xl),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget get contentGrid {
    int crossCount = 1;
    if (MediaQuery.sizeOf(context).width > LayoutBreakpoint.compact['width']!) {
      crossCount = 2;
    }
    if (MediaQuery.sizeOf(context).width > LayoutBreakpoint.medium['width']!) {
      crossCount = 3;
    }

    return SliverToBoxAdapter(
      child: KazumiDesktopPageFrame(
        maxWidth: KazumiDesktopShell.mediaPageMaxWidth,
        child: GridView.builder(
          itemCount: historyController.histories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: KazumiSpacing.sm,
            crossAxisSpacing: StyleString.cardSpace,
            crossAxisCount: crossCount,
            mainAxisExtent: 136,
          ),
          itemBuilder: (BuildContext context, int index) {
            return BangumiHistoryCardV(
              historyItem: historyController.histories[index],
              showDelete: showDelete,
              onDeleted: () {
                historyController.deleteHistory(
                  historyController.histories[index],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.count,
    required this.showDelete,
    required this.hasHistory,
    required this.onBack,
    required this.onToggleEdit,
    required this.onClearAll,
  });

  final int count;
  final bool showDelete;
  final bool hasHistory;
  final VoidCallback onBack;
  final VoidCallback onToggleEdit;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: dtb.DragToMoveArea(
        child: KazumiGlassSurface(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: KazumiDesktopHeaderTopRow(
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onBack,
                  tooltip: '返回',
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '历史记录',
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        count == 0 ? '继续观看和播放记录会在这里汇总。' : '共 $count 条观看记录。',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasHistory) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: onToggleEdit,
                    icon: Icon(
                      showDelete
                          ? Icons.edit_off_outlined
                          : Icons.edit_outlined,
                    ),
                    tooltip: showDelete ? '退出编辑' : '编辑',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: '清除全部',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: KazumiGlassSurface(
        borderRadius: KazumiRadius.panelBorder,
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 34,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: scheme.primary.withValues(alpha: 0.72),
            ),
            const SizedBox(height: KazumiSpacing.md),
            Text(
              '没有找到历史记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: KazumiSpacing.xs),
            Text(
              '开始播放后，这里会记录你的观看进度。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
