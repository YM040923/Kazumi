import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= LayoutBreakpoint.medium['width']!;

    return Skeletonizer(
      enabled: widget.isLoading,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWide ? 28 : 16,
          4,
          isWide ? 28 : 16,
          18,
        ),
        child: _EditorialShelfPanel(
          bangumiItem: widget.bangumiItem,
          showRating: widget.showRating && !widget.isLoading,
          touchedIndex: touchedIndex,
          onTouchRating: (index) {
            setState(() {
              touchedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _EditorialShelfPanel extends StatelessWidget {
  const _EditorialShelfPanel({
    required this.bangumiItem,
    required this.showRating,
    required this.touchedIndex,
    required this.onTouchRating,
  });

  final BangumiItem bangumiItem;
  final bool showRating;
  final int touchedIndex;
  final ValueChanged<int> onTouchRating;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= LayoutBreakpoint.medium['width']!;
    final isCompact = width < LayoutBreakpoint.compact['width']!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 1240 ? 1240.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: _panelDecoration(context),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 22 : 14),
                child: isCompact
                    ? _compactLayout(context)
                    : _wideLayout(context, showChart: isWide),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.78 : 0.88),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.56),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: isDark ? 0.22 : 0.08),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: isDark ? 0.13 : 0.10),
          scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.82 : 0.92),
          scheme.surfaceContainerHighest
              .withValues(alpha: isDark ? 0.58 : 0.72),
        ],
        stops: const [0, 0.42, 1],
      ),
    );
  }

  Widget _wideLayout(BuildContext context, {required bool showChart}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PosterFrame(bangumiItem: bangumiItem, width: showChart ? 214 : 188),
        const SizedBox(width: 24),
        Expanded(
          flex: 7,
          child: _DetailColumn(
            bangumiItem: bangumiItem,
            showSynopsis: true,
          ),
        ),
        if (showChart) ...[
          const SizedBox(width: 22),
          SizedBox(
            width: 300,
            child: _DetailSidePanel(
              child: _RatingShelf(
                bangumiItem: bangumiItem,
                touchedIndex: touchedIndex,
                onTouchRating: onTouchRating,
                showRating: showRating,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _compactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PosterFrame(bangumiItem: bangumiItem, width: 126),
            const SizedBox(width: 14),
            Expanded(
              child: _DetailColumn(
                bangumiItem: bangumiItem,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SynopsisPanel(
          summary: bangumiItem.summary,
          compact: true,
        ),
      ],
    );
  }
}

class _PosterFrame extends StatelessWidget {
  const _PosterFrame({
    required this.bangumiItem,
    required this.width,
  });

  final BangumiItem bangumiItem;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 0.68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Hero(
              tag: bangumiItem.id,
              flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
              child: NetworkImgLayer(
                src: bangumiItem.images['large'] ?? '',
                width: width,
                height: width / 0.68,
                quality: 150,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  const _DetailColumn({
    required this.bangumiItem,
    this.compact = false,
    this.showSynopsis = false,
  });

  final BangumiItem bangumiItem;
  final bool compact;
  final bool showSynopsis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title =
        bangumiItem.nameCn.isNotEmpty ? bangumiItem.nameCn : bangumiItem.name;
    final originalTitle = bangumiItem.nameCn.isNotEmpty ? bangumiItem.name : '';
    final summary = bangumiItem.summary.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.16,
              ),
        ),
        if (originalTitle.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            originalTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaPill(
              icon: Icons.event_rounded,
              label: '首播',
              value: bangumiItem.airDate.isEmpty ? '未知' : bangumiItem.airDate,
            ),
            _MetaPill(
              icon: Icons.star_rounded,
              label: '评分',
              value: bangumiItem.ratingScore > 0
                  ? bangumiItem.ratingScore.toStringAsFixed(1)
                  : '暂无',
            ),
            _MetaPill(
              icon: Icons.leaderboard_rounded,
              label: '排名',
              value: bangumiItem.rank > 0 ? '#${bangumiItem.rank}' : '暂无',
            ),
          ],
        ),
        const SizedBox(height: 12),
        RatingBarIndicator(
          rating:
              bangumiItem.ratingScore <= 0 ? 0 : bangumiItem.ratingScore / 2,
          itemBuilder: (_, __) =>
              Icon(Icons.star_rounded, color: scheme.primary),
          itemCount: 5,
          itemSize: compact ? 15 : 17,
          unratedColor: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
        if (showSynopsis && !compact) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _SynopsisPanel(summary: summary),
          ),
        ] else if (showSynopsis) ...[
          const SizedBox(height: 14),
          _SynopsisPanel(summary: summary, compact: true),
        ],
        if (!compact) ...[
          const SizedBox(height: 12),
          _InfoActionRow(bangumiItem: bangumiItem),
        ],
      ],
    );
  }
}

class _InfoActionRow extends StatelessWidget {
  const _InfoActionRow({required this.bangumiItem});

  final BangumiItem bangumiItem;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TagStrip(tags: bangumiItem.tags, dense: true),
        SizedBox(
          height: 36,
          child: CollectButton.extend(
            bangumiItem: bangumiItem,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}

class _SynopsisPanel extends StatelessWidget {
  const _SynopsisPanel({
    required this.summary,
    this.compact = false,
  });

  final String summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalizedSummary = summary.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '简介',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              normalizedSummary.isEmpty ? '暂无简介' : normalizedSummary,
              maxLines: compact ? 3 : 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: compact ? 1.48 : 1.42,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSidePanel extends StatelessWidget {
  const _DetailSidePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 260),
      child: child,
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: scheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagStrip extends StatelessWidget {
  const _TagStrip({
    required this.tags,
    this.dense = false,
  });

  final List<BangumiTag> tags;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleTags =
        tags.where((tag) => tag.name.trim().isNotEmpty).take(dense ? 5 : 6);

    if (visibleTags.isEmpty) {
      return Text(
        '暂无标签',
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Wrap(
      spacing: dense ? 6 : 7,
      runSpacing: dense ? 0 : 7,
      children: [
        for (final tag in visibleTags)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(dense ? 7 : 8),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 7 : 8,
                vertical: dense ? 4 : 5,
              ),
              child: Text(
                tag.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: dense ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RatingShelf extends StatelessWidget {
  const _RatingShelf({
    required this.bangumiItem,
    required this.touchedIndex,
    required this.onTouchRating,
    required this.showRating,
  });

  final BangumiItem bangumiItem;
  final int touchedIndex;
  final ValueChanged<int> onTouchRating;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '评分分布',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bangumiItem.votes > 0 ? '${bangumiItem.votes} 人参与评分' : '暂无评分样本',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: showRating &&
                      bangumiItem.votes > 0 &&
                      bangumiItem.votesCount.length >= 10
                  ? _ratingChart(context)
                  : Center(
                      child: Text(
                        '暂无图表',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingChart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BarChart(
      duration: const Duration(milliseconds: 80),
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.spot == null) {
              onTouchRating(-1);
              return;
            }
            onTouchRating(response.spot!.touchedBarGroupIndex);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pct =
                  bangumiItem.votesCount[groupIndex] / bangumiItem.votes * 100;
              return BarTooltipItem(
                '${pct.toStringAsFixed(1)}%',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(
          10,
          (i) => BarChartGroupData(
            x: i + 1,
            barRods: [
              BarChartRodData(
                toY: bangumiItem.votesCount[i].toDouble(),
                color: touchedIndex == i
                    ? scheme.primary
                    : scheme.primary.withValues(alpha: 0.32),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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
    );
  }
}
