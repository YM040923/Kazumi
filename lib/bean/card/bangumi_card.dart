import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/utils.dart';

/// 番剧卡片 - 现代垂直布局
///
/// 使用 M3 Card 组件 + 表面色区分 + 微动效
class BangumiCardV extends StatelessWidget {
  const BangumiCardV({
    super.key,
    required this.bangumiItem,
    this.canTap = true,
    this.enableHero = true,
  });

  final BangumiItem bangumiItem;
  final bool canTap;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: KazumiElevations.subtle,
      shadowColor: Colors.black26,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: KazumiRadius.cardBorder,
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: theme.brightness == Brightness.dark
          ? scheme.surfaceContainerLow
          : scheme.surface,
      child: GestureDetector(
        child: InkWell(
          onTap: () {
            if (!canTap) {
              KazumiDialog.showToast(message: '编辑模式');
              return;
            }
            Modular.to.pushNamed('/info/', arguments: bangumiItem);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 0.65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(builder: (context, boxConstraints) {
                      final double maxWidth = boxConstraints.maxWidth;
                      final double maxHeight = boxConstraints.maxHeight;
                      return enableHero
                          ? Hero(
                              transitionOnUserGestures: true,
                              flightShuttleBuilder:
                                  NetworkImgLayer.heroFlightShuttleBuilder,
                              tag: bangumiItem.id,
                              child: NetworkImgLayer(
                                src: bangumiItem.images['large'] ?? '',
                                width: maxWidth,
                                height: maxHeight,
                              ),
                            )
                          : NetworkImgLayer(
                              src: bangumiItem.images['large'] ?? '',
                              width: maxWidth,
                              height: maxHeight,
                            );
                    }),
                    // 顶部渐变遮罩 - 让覆盖物更可读
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 底部渐变遮罩 - 让评分更可读
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 评分徽章
                    if (bangumiItem.rating != null &&
                        bangumiItem.rating!.score! > 0)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: _ScoreBadge(score: bangumiItem.rating!.score!),
                      ),
                  ],
                ),
              ),
              // 标题区域
              BangumiContent(bangumiItem: bangumiItem),
            ],
          ),
        ),
      ),
    );
  }
}

/// 评分徽章
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(KazumiRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 11,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 2),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 卡片标题区域
class BangumiContent extends StatelessWidget {
  const BangumiContent({super.key, required this.bangumiItem});

  final BangumiItem bangumiItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ts = MediaQuery.textScalerOf(context);

    final int maxTextLines = Utils.isDesktop()
        ? 3
        : (Utils.isTablet() &&
                MediaQuery.of(context).orientation == Orientation.landscape)
            ? 3
            : 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KazumiSpacing.sm,
        KazumiSpacing.sm,
        KazumiSpacing.sm,
        KazumiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerLow
            : scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bangumiItem.nameCn,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
              height: 1.3,
              color: scheme.onSurface,
            ),
            textScaler: ts.clamp(maxScaleFactor: 1.1),
            maxLines: maxTextLines,
            overflow: TextOverflow.ellipsis,
          ),
          // 副标题（日文名或日期）
          if (bangumiItem.name.isNotEmpty &&
              bangumiItem.name != bangumiItem.nameCn)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                bangumiItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
