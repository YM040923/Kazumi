import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/extension.dart';
import 'package:kazumi/utils/logger.dart';

class NetworkImgLayer extends StatelessWidget {
  const NetworkImgLayer({
    super.key,
    this.src,
    required this.width,
    required this.height,
    this.type,
    this.fadeOutDuration,
    this.fadeInDuration,
    this.quality,
    this.origAspectRatio,
    this.filterQuality = FilterQuality.high,
    this.color,
    this.colorBlendMode,
  });

  final String? src;
  final double width;
  final double height;
  final String? type;
  final Duration? fadeOutDuration;
  final Duration? fadeInDuration;
  final int? quality;
  final double? origAspectRatio;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;

  static const int _defaultDecodeQuality = 100;
  static const int _maxDecodePixels = 4096;

  static Widget heroFlightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromHero = fromHeroContext.widget as Hero;
    final toHero = toHeroContext.widget as Hero;
    final heroContext = flightDirection == HeroFlightDirection.push
        ? fromHeroContext
        : toHeroContext;
    final hero =
        flightDirection == HeroFlightDirection.push ? fromHero : toHero;

    return InheritedTheme.captureAll(
      heroContext,
      Material(
        type: MaterialType.transparency,
        child: hero.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = _resolveImageExtent(width, constraints.maxWidth);
        final resolvedHeight =
            _resolveImageExtent(height, constraints.maxHeight);
        final String imageUrl = src ?? '';

        //// We need this to shrink memory usage while keeping poster art sharp.
        int? memCacheWidth, memCacheHeight;
        final double aspectRatio = (resolvedWidth / resolvedHeight).toDouble();
        final double decodeScale = _decodeScaleFromQuality(quality);

        void setMemCacheSizes() {
          if (aspectRatio > 1) {
            memCacheHeight = _cacheSizeFor(
              context,
              resolvedHeight,
              decodeScale: decodeScale,
            );
          } else if (aspectRatio < 1) {
            memCacheWidth = _cacheSizeFor(
              context,
              resolvedWidth,
              decodeScale: decodeScale,
            );
          } else {
            if (origAspectRatio != null && origAspectRatio! > 1) {
              memCacheWidth = _cacheSizeFor(
                context,
                resolvedWidth,
                decodeScale: decodeScale,
              );
            } else if (origAspectRatio != null && origAspectRatio! < 1) {
              memCacheHeight = _cacheSizeFor(
                context,
                resolvedHeight,
                decodeScale: decodeScale,
              );
            } else {
              memCacheWidth = _cacheSizeFor(
                context,
                resolvedWidth,
                decodeScale: decodeScale,
              );
              memCacheHeight = _cacheSizeFor(
                context,
                resolvedHeight,
                decodeScale: decodeScale,
              );
            }
          }
        }

        setMemCacheSizes();

        if (memCacheWidth == null && memCacheHeight == null) {
          memCacheWidth = resolvedWidth.toInt();
        }

        return imageUrl.isNotEmpty
            ? ClipRRect(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(
                  type == 'avatar'
                      ? 50
                      : type == 'emote'
                          ? 0
                          : StyleString.imgRadius.x,
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: resolvedWidth,
                  height: resolvedHeight,
                  memCacheWidth: memCacheWidth,
                  memCacheHeight: memCacheHeight,
                  fit: BoxFit.cover,
                  fadeOutDuration:
                      fadeOutDuration ?? const Duration(milliseconds: 120),
                  fadeInDuration:
                      fadeInDuration ?? const Duration(milliseconds: 120),
                  filterQuality: filterQuality,
                  color: color,
                  colorBlendMode: colorBlendMode,
                  errorListener: (e) {
                    KazumiLogger()
                        .w("NetworkImage: network image load error", error: e);
                  },
                  errorWidget:
                      (BuildContext context, String url, Object error) =>
                          placeholder(
                    context,
                    width: resolvedWidth,
                    height: resolvedHeight,
                  ),
                  placeholder: (BuildContext context, String url) =>
                      placeholder(
                    context,
                    width: resolvedWidth,
                    height: resolvedHeight,
                  ),
                ))
            : placeholder(
                context,
                width: resolvedWidth,
                height: resolvedHeight,
              );
      },
    );
  }

  double _resolveImageExtent(double requested, double constraint) {
    if (requested.isFinite && requested > 0) return requested;
    if (constraint.isFinite && constraint > 0) return constraint;
    return 1;
  }

  double _decodeScaleFromQuality(int? quality) {
    final safeQuality = (quality ?? _defaultDecodeQuality).clamp(50, 200);
    return safeQuality / _defaultDecodeQuality;
  }

  int _cacheSizeFor(
    BuildContext context,
    double extent, {
    required double decodeScale,
  }) {
    final scaledExtent = (extent * decodeScale).clamp(1, _maxDecodePixels);
    return scaledExtent.cacheSize(context).clamp(1, _maxDecodePixels).round();
  }

  Widget placeholder(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onInverseSurface
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(type == 'avatar'
            ? 50
            : type == 'emote'
                ? 0
                : StyleString.imgRadius.x),
      ),
      child: type == 'bg'
          ? const SizedBox()
          : Center(
              child: Image.asset(
                type == 'avatar'
                    ? 'assets/images/noface.jpeg'
                    : 'assets/images/loading.png',
                width: width,
                height: height,
                cacheWidth: width.cacheSize(context),
                cacheHeight: height.cacheSize(context),
              ),
            ),
    );
  }
}
