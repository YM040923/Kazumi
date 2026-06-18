import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:kazumi/design/adaptive_layout.dart';
import 'package:kazumi/design/desktop_layout.dart';

void main() {
  test('window classes map desktop widths consistently', () {
    expect(KazumiWindowClass.forWidth(640), KazumiWindowClass.compact);
    expect(KazumiWindowClass.forWidth(900), KazumiWindowClass.medium);
    expect(KazumiWindowClass.forWidth(1280), KazumiWindowClass.wide);
    expect(KazumiWindowClass.forWidth(1680), KazumiWindowClass.ultrawide);
  });

  test('page metrics reserve gutters and cap readable content', () {
    final compact = KazumiPageMetrics.fromViewport(width: 700, height: 720);
    expect(compact.gutter, 16);
    expect(compact.contentWidth, 668);
    expect(compact.windowClass, KazumiWindowClass.compact);

    final wide = KazumiPageMetrics.fromViewport(width: 1500, height: 960);
    expect(wide.gutter, 32);
    expect(wide.contentWidth, 1180);
    expect(wide.windowClass, KazumiWindowClass.ultrawide);
  });

  test('grid column helper keeps media pages responsive', () {
    expect(
      KazumiPageMetrics.fromViewport(width: 720, height: 720).mediaColumns,
      2,
    );
    expect(
      KazumiPageMetrics.fromViewport(width: 980, height: 860).mediaColumns,
      3,
    );
    expect(
      KazumiPageMetrics.fromViewport(width: 1280, height: 860).mediaColumns,
      5,
    );
  });

  testWidgets('desktop page frame centers capped content on ultrawide windows',
      (tester) async {
    const childKey = Key('framed-child');
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(1600, 900)),
          child: SizedBox(
            width: 1600,
            height: 900,
            child: KazumiDesktopPageFrame(
              maxWidth: 1180,
              child: SizedBox(key: childKey, height: 20),
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byKey(childKey));
    final size = tester.getSize(find.byKey(childKey));

    expect(size.width, 1180);
    expect(topLeft.dx, closeTo(210, 0.01));
  });
}

