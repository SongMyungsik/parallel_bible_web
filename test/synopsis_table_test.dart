import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_viewer/data/ref_format.dart';
import 'package:parallel_viewer/ui/synopsis_table.dart';

Map<String, Object?> ref(
  String book,
  int ch,
  int vs,
  int chEnd,
  int ve, {
  bool doublet = false,
}) => {
  'book': book,
  'chapter': ch,
  'verse_start': vs,
  'chapter_end': chEnd,
  'verse_end': ve,
  'doublet': doublet ? 1 : 0,
};

void main() {
  testWidgets('폰 폭(360)에서 대조표가 넘치지 않고 칸이 채워짐', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SynopsisHeaderRow(),
              // 긴 범위 + 반복 말씀
              SynopsisRow(
                order: 78,
                title: '자기 십자가를 지고 따르라',
                gospelCount: 3,
                refs: [
                  ref('MAT', 16, 24, 16, 28),
                  ref('MAT', 10, 38, 10, 39, doublet: true),
                  ref('MRK', 8, 34, 9, 1),
                  ref('LUK', 9, 23, 9, 27),
                  ref('LUK', 14, 27, 14, 27, doublet: true),
                  ref('LUK', 17, 33, 17, 33, doublet: true),
                ],
                onTap: () {},
              ),
              // 나뉜 본문 + 요한복음
              SynopsisRow(
                order: 129,
                title: '베드로가 예수님을 부인함',
                gospelCount: 4,
                refs: [
                  ref('MAT', 26, 69, 26, 75),
                  ref('MRK', 14, 66, 14, 72),
                  ref('LUK', 22, 54, 22, 62),
                  ref('JHN', 18, 15, 18, 18),
                  ref('JHN', 18, 25, 18, 27),
                ],
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    // 넘침(overflow) 오류가 있으면 여기서 실패
    expect(tester.takeException(), isNull);
    expect(find.text('마가'), findsOneWidget);
    expect(find.text('8:34-9:1'), findsOneWidget);
    expect(find.text('(14:27, 17:33)'), findsOneWidget);
    expect(find.text('18:15-18, 25-27'), findsOneWidget);
  });

  test('약자 줄: 책마다 한 줄, 같은 책은 이어서', () {
    expect(
      formatAbbrLines([
        ref('MAT', 5, 31, 5, 31),
        ref('MAT', 19, 7, 19, 7),
        ref('MRK', 10, 4, 10, 4),
      ]),
      ['마 5:31, 19:7', '막 10:4'],
    );
    expect(
      formatAbbrLines([ref('ISA', 56, 7, 56, 7), ref('JER', 7, 11, 7, 11)]),
      ['사 56:7', '렘 7:11'],
    );
  });

  testWidgets('폰 폭(360)에서 구약 인용 표가 넘치지 않음', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const QuotationHeaderRow(),
              QuotationRow(
                order: 6,
                title: '광야에서 외치는 자의 소리',
                refs: [
                  ref('MAT', 3, 3, 3, 3),
                  ref('MRK', 1, 3, 1, 3),
                  ref('LUK', 3, 4, 3, 6),
                  ref('JHN', 1, 23, 1, 23),
                  ref('ISA', 40, 3, 40, 5),
                ],
                onTap: () {},
              ),
              QuotationRow(
                order: 57,
                title: '권능의 우편에 앉은 것과 하늘 구름을 타고',
                refs: [
                  ref('MAT', 26, 64, 26, 64),
                  ref('MRK', 14, 62, 14, 62),
                  ref('LUK', 22, 69, 22, 69),
                  ref('PSA', 110, 1, 110, 1),
                  ref('DAN', 7, 13, 7, 13),
                ],
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('신약'), findsOneWidget);
    expect(find.text('눅 3:4-6'), findsOneWidget);
    expect(find.text('사 40:3-5'), findsOneWidget);
    expect(find.text('시 110:1'), findsOneWidget);
  });
}
