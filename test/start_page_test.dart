import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_bible_web/pages/start_page.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size, Widget page) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
  }

  testWidgets('시작 화면: 준비 중에는 버튼 대신 안내, 폰 폭(360)에서 넘치지 않음', (tester) async {
    await pumpAt(
      tester,
      const Size(360, 640),
      const StartPage(message: '성경 본문을 준비하는 중…'),
    );
    expect(find.text('병행 구절 대조'), findsOneWidget);
    expect(find.text('성경 본문을 준비하는 중…'), findsOneWidget);
    expect(find.text('시작하기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시작 화면: 준비가 끝나면 [시작하기]를 누를 수 있음', (tester) async {
    var started = false;
    await pumpAt(
      tester,
      const Size(360, 640),
      StartPage(message: '', onStart: () => started = true),
    );
    await tester.tap(find.text('시작하기'));
    expect(started, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시작 화면: 가로 모드처럼 낮은 화면에서도 넘치지 않음', (tester) async {
    await pumpAt(
      tester,
      const Size(640, 360),
      StartPage(message: '', onStart: () {}),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('시작 화면: 교회 로고가 [시작하기]와 버전 사이에, 다크 모드에서도 넘치지 않음', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: StartPage(message: '', onStart: () {}),
        ),
      );
      final logo = find.byType(ChurchLogo);
      expect(logo, findsOneWidget);
      final logoY = tester.getCenter(logo).dy;
      expect(tester.getCenter(find.text('시작하기')).dy, lessThan(logoY));
      expect(
        tester.getCenter(find.textContaining('Parallel_Bible')).dy,
        greaterThan(logoY),
      );
      expect(tester.takeException(), isNull, reason: '$brightness');
    }
  });
}
