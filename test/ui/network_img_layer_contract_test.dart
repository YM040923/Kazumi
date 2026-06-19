import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';

void main() {
  test('network image layer resolves non-finite layout sizes before caching',
      () {
    final source =
        File('lib/bean/card/network_img_layer.dart').readAsStringSync();

    expect(source, contains('LayoutBuilder'));
    expect(source, contains('_resolveImageExtent'));
    expect(source, contains('requested.isFinite'));
    expect(source, contains('constraint.isFinite'));
    expect(source, isNot(contains('width.toInt()')));
  });

  testWidgets('quality increases foreground poster decode size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 2),
          child: Center(
            child: NetworkImgLayer(
              src: 'https://example.com/poster.jpg',
              width: 120,
              height: 180,
              quality: 150,
            ),
          ),
        ),
      ),
    );

    final image =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

    expect(image.memCacheWidth, 360);
    expect(image.memCacheHeight, isNull);
    expect(image.filterQuality, FilterQuality.high);
  });

  test('media posters opt into high resolution decode budgets', () {
    final sources = [
      File('lib/bean/card/bangumi_card.dart').readAsStringSync(),
      File('lib/bean/card/bangumi_info_card.dart').readAsStringSync(),
      File('lib/bean/card/bangumi_history_card.dart').readAsStringSync(),
      File('lib/bean/card/bangumi_timeline_card.dart').readAsStringSync(),
      File('lib/pages/popular/popular_page.dart').readAsStringSync(),
    ].join('\n');

    expect(sources, contains('quality: 140'));
    expect(sources, contains('quality: 150'));
    expect(sources, isNot(contains('FilterQuality.low,\n')));
  });
}
