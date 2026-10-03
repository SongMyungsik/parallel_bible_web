import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_viewer/data/ref_format.dart';
import 'package:parallel_viewer/data/sections.dart';
import 'package:parallel_viewer/logic/word_matcher.dart';
import 'package:parallel_viewer/state/app_settings.dart';
import 'package:parallel_viewer/ui/grouped_list.dart';

void main() {
  group('WordMatcher', () {
    test('다른 복음서에 같은 표현이 있으면 그 수만큼 센다', () {
      final result = WordMatcher.analyze(
        [
          ['자기 십자가를 지고 나를 따르라'],
          ['자기 십자가를 지고 나를 따를 것이니라'],
          ['자기 십자가를 지고 오라'],
        ],
        ['MAT', 'MRK', 'LUK'],
      );
      // "자기 십자가를 지고" → 세 복음서 공통
      expect(result[0][0].first.sharedBy, 3);
      // "나를 따르라"는 마태·마가에만
      expect(result[0][0][3].sharedBy, 2);
    });

    test('같은 복음서의 반복 말씀끼리는 공통으로 세지 않는다', () {
      final result = WordMatcher.analyze(
        [
          ['자기 십자가를 지고 나를 따르라'],
          ['자기 십자가를 지고 나를 따르라'], // 같은 누가복음의 다른 곳
        ],
        ['LUK', 'LUK'],
      );
      for (final block in result) {
        for (final w in block[0]) {
          expect(w.sharedBy, 1);
        }
      }
    });

    test('[없음] 표시는 공통 표현으로 세지 않는다', () {
      final result = WordMatcher.analyze(
        [
          ['[없음] 거기는 구더기도'],
          ['[없음] 거기는 불도'],
        ],
        ['MAT', 'MRK'],
      );
      expect(result[0][0][0].sharedBy, 1); // "[없음]"
      expect(result[0][0][1].sharedBy, 1); // "거기는" (한 단어만 같음)
    });

    test('구약 인용: 신약끼리는 비교하지 않고 구약과만 비교한다', () {
      // 인용 화면은 책 대신 NT/OT로 나누어 넘깁니다.
      final result = WordMatcher.analyze(
        [
          ['주의 길을 예비하라 그의 첩경을'], // 마태
          ['주의 길을 예비하라 그의 첩경을'], // 마가 (마태와 같지만 칠하지 않음)
          ['여호와의 길을 예비하라'], // 이사야
        ],
        ['NT', 'NT', 'OT'],
      );
      final mat = result[0][0];
      expect(mat[1].sharedBy, 2); // "길을" + "예비하라" → 구약과 같음
      expect(mat[2].sharedBy, 2);
      expect(mat[3].sharedBy, 1); // "그의 첩경을"은 마가에만 같음
      expect(mat[4].sharedBy, 1);
    });

    test('반복 말씀도 다른 복음서와 같으면 칠해진다', () {
      final result = WordMatcher.analyze(
        [
          ['자기 십자가를 지고'], // 마태 본문
          ['자기 십자가를 지고'], // 누가 본문
          ['자기 십자가를 지고'], // 누가 반복 말씀
        ],
        ['MAT', 'LUK', 'LUK'],
      );
      expect(result[0][0].first.sharedBy, 2); // 마태: 누가와 공통
      expect(result[2][0].first.sharedBy, 2); // 누가 반복: 마태와 공통
    });
  });

  group('formatRefs', () {
    Map<String, Object?> ref(int ch, int vs, int chEnd, int ve) => {
      'book': 'MRK',
      'chapter': ch,
      'verse_start': vs,
      'chapter_end': chEnd,
      'verse_end': ve,
    };

    test('같은 장의 나뉜 본문', () {
      expect(
        formatRefs([ref(11, 12, 11, 14), ref(11, 20, 11, 25)]),
        '마가복음 11:12-14, 20-25',
      );
    });

    test('다른 장, 한 절, 장이 넘어가는 범위', () {
      expect(
        formatRefs([ref(9, 23, 9, 27), ref(14, 27, 14, 27)]),
        '마가복음 9:23-27, 14:27',
      );
      expect(formatRef(ref(8, 34, 9, 1)), '마가복음 8:34-9:1');
    });

    test('구약 인용 요약', () {
      Map<String, Object?> r(String b, int c, int vs, int ve) => {
        'book': b,
        'chapter': c,
        'verse_start': vs,
        'chapter_end': c,
        'verse_end': ve,
      };
      expect(
        formatRefsSummary([r('MAT', 1, 22, 23), r('ISA', 7, 14, 14)]),
        '마태 1:22-23 · 이사야 7:14',
      );
      expect(
        formatRefsSummary([
          r('MAT', 5, 31, 31),
          r('MAT', 19, 7, 7),
          r('MRK', 10, 4, 4),
          r('DEU', 24, 1, 1),
        ]),
        '마태 5:31, 19:7 · 마가 10:4 · 신명기 24:1',
      );
      expect(isOldTestament('MAL'), isTrue);
      expect(isOldTestament('MAT'), isFalse);
    });

    test('복음서 목록은 성경 순서로 표시', () {
      expect(formatGospelList('JHN,LUK,MAT,MRK'), '마태 · 마가 · 누가 · 요한');
      expect(formatGospelList('LUK,MAT'), '마태 · 누가');
      expect(formatGospelList(null), '');
    });
  });

  group('RecentView', () {
    test('저장 글자로 바꿨다가 되살림 (제목에 | 가 있어도)', () {
      const v = RecentView(1005, '광야 | 소리');
      final back = RecentView.decode(v.encode())!;
      expect(back.id, 1005);
      expect(back.title, '광야 | 소리');
      expect(RecentView.decode(null), isNull);
      expect(RecentView.decode('잘못된 값'), isNull);
    });
  });

  group('목록 묶기·검색', () {
    test('소제목이 바뀔 때마다 소제목 줄을 넣고 개수를 셈', () {
      final e = groupEntries(['a1', 'a2', 'b1'], (s) => s[0]);
      expect(e.map((x) => x.isHeader ? '[${x.header}:${x.count}]' : x.item), [
        '[a:2]',
        'a1',
        'a2',
        '[b:1]',
        'b1',
      ]);
    });

    test('띄어쓰기 무시하고 제목·구절에서 찾음', () {
      expect(
        matchesQuery('누가 9', ['나를 따르려면', '마태 8:18-22 · 누가 9:57-62']),
        isTrue,
      );
      expect(
        matchesQuery('이사야', ['처녀가 잉태하여', '마태 1:22-23 · 이사야 7:14']),
        isTrue,
      );
      expect(matchesQuery('요한', ['주기도문', '마태 6:9-13 · 누가 11:2-4']), isFalse);
      expect(matchesQuery('', ['아무거나']), isTrue);
    });
  });

  test('앱 색상: 없어진 색은 같은 계열로, 모르는 값은 인디고', () {
    expect(AppColorOption.values.length, 5);
    expect(AppColorOption.fromName('green'), AppColorOption.green);
    expect(AppColorOption.fromName('teal'), AppColorOption.green);
    expect(AppColorOption.fromName('pink'), AppColorOption.wine);
    expect(AppColorOption.fromName('none'), AppColorOption.charcoal);
    expect(AppColorOption.fromName(null), AppColorOption.indigo);
  });

  test('목록 소제목: 1~6은 생애 단계, 105~127은 신약 책', () {
    expect(sectionName(5), '수난');
    expect(sectionName(105), '사도행전');
    expect(sectionName(106), '로마서');
    expect(sectionName(119), '히브리서');
    expect(sectionName(127), '요한계시록');
    expect(sectionName(128), '기타');
  });
}
