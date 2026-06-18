import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';

class BangumiCardV extends StatelessWidget {
  const BangumiCardV({super.key, required this.bangumiItem, this.canTap = true, this.enableHero = true});
  final BangumiItem bangumiItem;
  final bool canTap;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (!canTap) { KazumiDialog.showToast(message: 'Edit mode'); return; }
        Modular.to.pushNamed('/info/', arguments: bangumiItem);
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(color: isDark ? scheme.surfaceContainerLow : scheme.surface, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: AspectRatio(aspectRatio: 0.68, child: Stack(fit: StackFit.expand, children: [
              LayoutBuilder(builder: (context, bc) => enableHero
                  ? Hero(tag: bangumiItem.id, flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder, child: NetworkImgLayer(src: bangumiItem.images['large'] ?? '', width: bc.maxWidth, height: bc.maxHeight))
                  : NetworkImgLayer(src: bangumiItem.images['large'] ?? '', width: bc.maxWidth, height: bc.maxHeight)),
              Positioned(bottom: 0, left: 0, right: 0, height: 60, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent]))))),
              if (bangumiItem.ratingScore > 0) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, size: 12, color: Colors.white), const SizedBox(width: 2), Text(bangumiItem.ratingScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]))),
              if (bangumiItem.rank > 0 && bangumiItem.rank <= 100) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text('#${bangumiItem.rank}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
            ]))),
            Container(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), decoration: BoxDecoration(color: isDark ? scheme.surfaceContainerLow : scheme.surface), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bangumiItem.nameCn.isNotEmpty ? bangumiItem.nameCn : bangumiItem.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.25, letterSpacing: 0.1, color: scheme.onSurface)),
              if (bangumiItem.airDate.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(bangumiItem.airDate, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w400))),
            ])),
          ])),
        ),
      ),
    );
  }
}