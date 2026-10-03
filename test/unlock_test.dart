import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_viewer/data/free_items.dart';
import 'package:parallel_viewer/data/ref_format.dart';
import 'package:parallel_viewer/state/app_settings.dart';
import 'package:parallel_viewer/state/parallel_state.dart';
import 'package:parallel_viewer/state/purchase_state.dart';
import 'package:parallel_viewer/ui/synopsis_table.dart';
import 'package:parallel_viewer/ui/unlock_sheet.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

/// DB 없이 목록 상태만 쓰기 위한 가짜 DB (테스트에서는 DB를 부르지 않음)
class _FakeDb implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 결제가 없는 기기(테스트)용 구매 상태
PurchaseState _purchase(AppSettings settings) =>
    PurchaseState(settings, storeSupported: false);

Widget _app(PurchaseState purchase, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: purchase),
      ChangeNotifierProvider(create: (_) => ParallelState(_FakeDb())),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  test('무료 범위: 탄생과 준비 단계와 대표 사건만', () {
    expect(isFreeItem(id: 1, section: 1), isTrue); // 탄생과 준비
    expect(isFreeItem(id: 1001, section: 1), isTrue); // 인용도 같은 단계면 무료
    expect(isFreeItem(id: 7, section: 2), isTrue); // 오천 명을 먹이심
    expect(isFreeItem(id: 68, section: 5), isTrue); // 마지막 만찬
    expect(isFreeItem(id: 5, section: 2), isFalse); // 갈릴리 사역
    expect(isFreeItem(id: 1092, section: 106), isFalse); // 로마서 인용
  });

  test('잠긴 항목 요약: 장·절 없이 책 이름만 (같은 책은 한 번)', () {
    Map<String, Object?> ref(String book, int ch, int vs) => {
      'book': book,
      'chapter': ch,
      'verse_start': vs,
      'chapter_end': ch,
      'verse_end': vs,
    };
    final refs = [
      ref('ROM', 1, 17),
      ref('GAL', 3, 11),
      ref('HEB', 10, 37),
      ref('HAB', 2, 3),
    ];
    expect(formatBooksSummary(refs), '로마서 · 갈라디아서 · 히브리서 · 하박국');
    expect(
      formatBooksSummary([
        ref('MAT', 5, 31),
        ref('MAT', 19, 7),
        ref('DEU', 24, 1),
      ]),
      '마태 · 신명기',
    );
    expect(formatBooksSummary(const []), '');
  });

  test('구매 전에는 무료 범위만, 구매하면 모두 열림', () async {
    final settings = AppSettings();
    final purchase = _purchase(settings);

    expect(purchase.unlocked, isFalse);
    expect(purchase.canOpen(id: 1, section: 1), isTrue);
    expect(purchase.canOpen(id: 5, section: 2), isFalse);

    await settings.setFullUnlocked(true);
    expect(purchase.unlocked, isTrue);
    expect(purchase.canOpen(id: 5, section: 2), isTrue);
    expect(purchase.canOpen(id: 1092, section: 106), isTrue);
  });

  test('결제가 없는 기기에서 구매·복원을 누르면 안내만 나오고 열리지 않음', () async {
    final purchase = _purchase(AppSettings());

    await purchase.buy();
    expect(purchase.unlocked, isFalse);
    expect(purchase.busy, isFalse);
    expect(purchase.message, contains('구매할 수 없습니다'));

    await purchase.restore();
    expect(purchase.unlocked, isFalse);
    expect(purchase.busy, isFalse);
  });

  testWidgets('전체 열기 안내: 폰 폭(360)에서 넘치지 않고, 구매하면 "열려 있습니다"로 바뀜', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final purchase = _purchase(AppSettings());
    await tester.pumpWidget(
      _app(
        purchase,
        const Column(
          children: [
            UnlockBanner(),
            Padding(padding: EdgeInsets.all(24), child: UnlockPanel()),
          ],
        ),
      ),
    );
    expect(find.text('전체 열기 구매'), findsOneWidget);
    expect(find.text('이미 구매하셨나요? 구매 복원'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget); // 목록 위 안내 줄
    expect(tester.takeException(), isNull);

    await purchase.setUnlockedForDev(true);
    await tester.pump();
    expect(find.text('전체 기능이 열려 있습니다'), findsOneWidget);
    expect(find.text('전체 열기 구매'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing); // 안내 줄도 사라짐
    expect(tester.takeException(), isNull);
  });

  testWidgets('표 아래 안내: 감춘 줄 수를 알려 주고 폰 폭(360)에서 넘치지 않음', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        _purchase(AppSettings()),
        const Column(
          children: [
            HiddenRowsNote(count: 132, unit: '개 사건'),
            HiddenRowsNote(count: 194, unit: '곳'),
          ],
        ),
      ),
    );
    expect(find.text('나머지 132개 사건은 전체 열기 후 표에 나옵니다'), findsOneWidget);
    expect(find.text('나머지 194곳은 전체 열기 후 표에 나옵니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('대조표: 잠긴 줄에 자물쇠가 붙고 폰 폭(360)에서 넘치지 않음', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Map<String, Object?> ref(String book, int ch, int vs, int ve) => {
      'book': book,
      'chapter': ch,
      'verse_start': vs,
      'chapter_end': ch,
      'verse_end': ve,
      'doublet': 0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SynopsisRow(
                order: 5,
                title: '갈릴리 사역의 시작',
                gospelCount: 3,
                refs: [ref('MAT', 4, 12, 17), ref('MRK', 1, 14, 15)],
                locked: true,
                onTap: () {},
              ),
              QuotationRow(
                order: 92,
                title: '의인은 믿음으로 말미암아 살리라',
                refs: [ref('ROM', 1, 17, 17), ref('HAB', 2, 3, 4)],
                locked: true,
                onTap: () {},
              ),
              SynopsisRow(
                order: 1,
                title: '예수 그리스도의 족보',
                gospelCount: 2,
                refs: [ref('MAT', 1, 1, 17)],
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('코드로 열기: 맞는 코드만, 대소문자·하이픈·띄어쓰기 무시', () async {
    expect(PurchaseState.isValidCode('PB-REVIEW-2026'), isTrue);
    expect(PurchaseState.isValidCode(' pb review 2026 '), isTrue);
    expect(PurchaseState.isValidCode('PB-REVIEW-2025'), isFalse);
    expect(PurchaseState.isValidCode(''), isFalse);

    final settings = AppSettings();
    final purchase = _purchase(settings);
    expect(await purchase.redeemCode('틀린코드'), isFalse);
    expect(purchase.unlocked, isFalse);
    expect(purchase.message, contains('맞지 않습니다'));

    expect(await purchase.redeemCode('pbreview2026'), isTrue);
    expect(purchase.unlocked, isTrue);
  });

  testWidgets('전체 열기 안내에 [코드 입력]이 있고, 맞는 코드를 넣으면 열림', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = AppSettings();
    final purchase = _purchase(settings);
    await tester.pumpWidget(
      _app(purchase, const SingleChildScrollView(child: UnlockPanel())),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('코드가 있으신가요? 코드 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'PB-REVIEW-2026');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(purchase.unlocked, isTrue);
    expect(find.text('전체 기능이 열려 있습니다'), findsOneWidget);
  });
}
