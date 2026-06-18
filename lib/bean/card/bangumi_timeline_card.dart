import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';

class BangumiTimelineCard extends StatelessWidget {
  const BangumiTimelineCard({
    super.key,
    required this.bangumiItem,
    required this.showRating,
    this.onTap,
    this.enableHero = true,
  });

  final BangumiItem bangumiItem;
  final bool showRating;
  final VoidCallback? onTap;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title =
        bangumiItem.nameCn.isNotEmpty ? bangumiItem.nameCn : bangumiItem.name;

    return Material(
      color: isDark ? scheme.surfaceContainerLow : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
            () {
              Modular.to.pushNamed('/info/', arguments: bangumiItem);
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TimelinePosterFrame(
                bangumiItem: bangumiItem,
                enableHero: enableHero,
                showRating: showRating,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  if (bangumiItem.airDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bangumiItem.airDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePosterFrame extends StatelessWidget {
  const _TimelinePosterFrame({
    required this.bangumiItem,
    required this.enableHero,
    required this.showRating,
  });

  final BangumiItem bangumiItem;
  final bool enableHero;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget image = LayoutBuilder(
      builder: (context, constraints) {
        return NetworkImgLayer(
          src: bangumiItem.images['large'] ?? '',
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          quality: 120,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
        );
      },
    );

    if (enableHero) {
      image = Hero(
        tag: bangumiItem.id,
        transitionOnUserGestures: true,
        child: image,
      );
    }

    return AspectRatio(
      aspectRatio: 0.68,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 46,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showRating && bangumiItem.ratingScore > 0)
            Positioned(
              top: 7,
              right: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12, color: scheme.onPrimary),
                      const SizedBox(width: 2),
                      Text(
                        bangumiItem.ratingScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
