import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kazumi/bean/widget/collect_button.dart';
import 'package:kazumi/design/design_tokens.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BangumiInfoCardV extends StatefulWidget {
  const BangumiInfoCardV({super.key, required this.bangumiItem, required this.isLoading, required this.showRating});
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
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= LayoutBreakpoint.compact['width']!;
    return Skeletonizer(enabled: widget.isLoading, child: Container(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor], stops: const [0.0, 0.35])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: isWide ? 320 : 260, child: isWide ? _wideLayout(scheme) : _narrowLayout(scheme)),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 44, child: CollectButton.extend(bangumiItem: widget.bangumiItem)),
    ])));
  }

  Widget _wideLayout(ColorScheme scheme) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_coverImage(width: 180), const SizedBox(width: 20), Expanded(child: _metadataColumn(scheme)), const SizedBox(width: 20), if (widget.showRating && !widget.isLoading) SizedBox(width: 200, child: _ratingChart(scheme))]);
  Widget _narrowLayout(ColorScheme scheme) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_coverImage(width: 130), const SizedBox(width: 16), Expanded(child: _metadataColumn(scheme))]);

  Widget _coverImage({required double width}) => ClipRRect(borderRadius: BorderRadius.circular(14), child: AspectRatio(aspectRatio: 0.68, child: LayoutBuilder(builder: (context, bc) => Hero(tag: widget.bangumiItem.id, flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder, child: NetworkImgLayer(src: widget.bangumiItem.images['large'] ?? '', width: bc.maxWidth, height: bc.maxHeight, fadeInDuration: Duration.zero, fadeOutDuration: Duration.zero))))));

  Widget _metadataColumn(ColorScheme scheme) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(widget.bangumiItem.nameCn.isNotEmpty ? widget.bangumiItem.nameCn : widget.bangumiItem.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5, color: Colors.white, shadows: [const Shadow(color: Colors.black54, blurRadius: 8)]), maxLines: 2, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 12),
    _infoRow('Date', widget.bangumiItem.airDate),
    const SizedBox(height: 8),
    _infoRow('Score', '${widget.bangumiItem.ratingScore} / 10'),
    const SizedBox(height: 4),
    RatingBarIndicator(rating: widget.bangumiItem.ratingScore / 2, itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber), itemCount: 5, itemSize: 16),
    const SizedBox(height: 8),
    _infoRow('Rank', '#${widget.bangumiItem.rank}'),
    if (widget.bangumiItem.summary.isNotEmpty) ...[const SizedBox(height: 10), Expanded(child: Text(widget.bangumiItem.summary, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis))],
  ]);

  Widget _infoRow(String label, String value) => Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70))), const SizedBox(width: 8), Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))]);

  Widget _ratingChart(ColorScheme scheme) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Rating', style: TextStyle(color: Colors.white70, fontSize: 12)),
    const SizedBox(height: 8),
    Expanded(child: BarChart(duration: const Duration(milliseconds: 80), BarChartData(
      borderData: FlBorderData(show: false), gridData: FlGridData(show: false),
      barTouchData: BarTouchData(touchCallback: (event, response) { setState(() { if (!event.isInterestedForInteractions || response == null || response.spot == null) { touchedIndex = -1; return; } touchedIndex = response.spot!.touchedBarGroupIndex; }); },
        touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => scheme.inverseSurface, getTooltipItem: (group, groupIndex, rod, rodIndex) { final pct = widget.bangumiItem.votesCount[groupIndex] / widget.bangumiItem.votes * 100; return BarTooltipItem('${pct.toStringAsFixed(1)}%', TextStyle(color: scheme.onInverseSurface, fontSize: 11)); })),
      barGroups: List.generate(10, (i) => BarChartGroupData(x: i + 1, barRods: [BarChartRodData(toY: widget.bangumiItem.votesCount[i].toDouble(), color: touchedIndex == i ? scheme.primary : Colors.white38, width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))])),
      titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (value, meta) => SideTitleWidget(meta: meta, space: 4, child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 9))))), topTitles: const AxisTitles(), leftTitles: const AxisTitles(), rightTitles: const AxisTitles()),
    ))),
  ]);
}