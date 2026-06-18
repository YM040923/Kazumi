import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
}
