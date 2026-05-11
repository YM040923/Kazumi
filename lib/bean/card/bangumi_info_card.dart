import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 番剧详情信息卡片 - 现代水平布局
class BangumiInfoCardV extends StatefulWidget {
  const BangumiInfoCardV({
    super.key,
    required this.bangumiItem,
    required this.isLoading,
    required this.showRating,
  });

  final BangumiItem bangumiItem;
  final bool isLoading;
  final bool showRating;

  @override
  State<BangumiInfoCardV> createState() => _BangumiInfoCardVState();
}

class _BangumiInfoCardVState extends State<BangumiInfoCardV> {
  int touchedIndex = -1;

  Widget get voteBarChart {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '评分透视',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: KazumiSpacing.md),
          AspectRatio(
            aspectRatio: 2,
            child: BarChart(
              duration: const Duration(milliseconds: 80),
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final percentage =
                          widget.bangumiItem.votesCount[groupIndex] /
                              widget.bangumiItem.votes *
                              100;
                      return BarTooltipItem(
                        '${percentage.toStringAsFixed(2)}% (${widget.bangumiItem.votesCount[groupIndex]}人)',
                        TextStyle(color: scheme.onInverseSurface),
                      );
                    },
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(
                  10,
                  (i) => BarChartGroupData(
                    x: i + 1,
                    barRods: [
                      BarChartRodData(
                        toY: widget.bangumiItem.votesCount[i].toDouble(),
                        color: touchedIndex == i
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      )
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            widget.bangumiItem.nameCn == ''
                ? widget.bangumiItem.name
                : widget.bangumiItem.nameCn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: KazumiSpacing.md),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 0.65,
                    child: LayoutBuilder(builder: (context, boxConstraints) {
                      final double maxWidth = boxConstraints.maxWidth;
                      final double maxHeight = boxConstraints.maxHeight;
                      return Hero(
                        transitionOnUserGestures: true,
                        flightShuttleBuilder:
                            NetworkImgLayer.heroFlightShuttleBuilder,
                        tag: widget.bangumiItem.id,
                        child: NetworkImgLayer(
                          src: widget.bangumiItem.images['large'] ?? '',
                          width: maxWidth,
                          height: maxHeight,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: KazumiSpacing.lg),
                // 元数据
                Flexible(
                  child: Skeletonizer(
                    enabled: widget.isLoading,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetaLabel(text: '放送开始'),
                            Text(
                              widget.bangumiItem.airDate == ''
                                  ? '2000-11-11'
                                  : widget.bangumiItem.airDate,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: KazumiSpacing.md),
                            _MetaLabel(
                              text: widget.showRating
                                  ? '${widget.bangumiItem.votes} 人评分'
                                  : '*** 人评分',
                            ),
                            if (widget.isLoading)
                              Text(
                                '10.0 ********',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            if (!widget.isLoading)
                              Row(
                                children: [
                                  Text(
                                    widget.showRating
                                        ? '${widget.bangumiItem.ratingScore}'
                                        : '***',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RatingBarIndicator(
                                    itemCount: 5,
                                    rating: widget.showRating
                                        ? widget.bangumiItem.ratingScore
                                                .toDouble() /
                                            2
                                        : 0,
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star_rounded,
                                      color: scheme.primary,
                                    ),
                                    itemSize: 18.0,
                                  ),
                                ],
                              ),
                            const SizedBox(height: KazumiSpacing.md),
                            _MetaLabel(text: 'Bangumi Ranked'),
                            Text(
                              widget.showRating
                                  ? '#${widget.bangumiItem.rank}'
                                  : '***',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: CollectButton.extend(
                            bangumiItem: widget.bangumiItem,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 评分透视图表
                if (widget.showRating &&
                    MediaQuery.sizeOf(context).width >=
                        LayoutBreakpoint.compact['width']! &&
                    !widget.isLoading)
                  voteBarChart,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 元数据标签
class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
