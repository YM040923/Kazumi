import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop window controls overlay is built inside MaterialApp builder',
      () {
    final source = File('lib/app_widget.dart').readAsStringSync();

    expect(source, contains('builder: (context, child)'));
    expect(source, contains('DesktopWindowControlsOverlay('));
    expect(source, contains('child: child ?? const SizedBox.shrink()'));
    expect(source,
        isNot(contains('return DesktopWindowControlsOverlay(child: app);')));
  });
}
