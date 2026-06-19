import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history page exposes a visible back action in its header', () {
    final source =
        File('lib/pages/history/history_page.dart').readAsStringSync();

    final headerSource = source.substring(
      source.indexOf('class _HistoryHeader'),
      source.indexOf('class _HistoryEmptyState'),
    );

    expect(headerSource, contains('required this.onBack'));
    expect(headerSource, contains('final VoidCallback onBack;'));
    expect(headerSource, contains('Icons.arrow_back_rounded'));
    expect(headerSource, contains('tooltip:'));
    expect(headerSource, contains('onPressed: onBack'));
    expect(source, contains('onBack: () => Modular.to.pop()'));
    expect(source, contains('KazumiDesktopHeaderTopRow'));
  });
}
