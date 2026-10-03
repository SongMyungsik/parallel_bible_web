import 'ref_format.dart';

/// 한 절의 본문
class VerseText {
  const VerseText(this.chapter, this.verse, this.text, {this.heading});

  final int chapter;
  final int verse;
  final String text;

  /// 이 절 앞에 붙는 소제목 (예: "세례를 받으시다"). 없으면 null.
  final String? heading;
}

/// "본문을 어디서 가져오는가"를 정해 두는 약속(인터페이스).
///
/// 지금은 SampleBibleTextSource(가짜 본문)를 쓰고,
/// 나중에 실제 성경 DB를 읽는 클래스를 만들어 main.dart에서
/// 한 줄만 바꾸면 화면 코드는 고치지 않고 연결됩니다.
abstract class BibleTextSource {
  Future<List<VerseText>> getVerses({
    required String book,
    required int chapter,
    required int verseStart,
    required int chapterEnd,
    required int verseEnd,
  });

  /// 책 코드 → 장 수 (예: GEN → 50). 본문이 있는 책만 들어 있습니다.
  Future<Map<String, int>> chapterCounts();
}

/// 화면 확인용 샘플. 실제 성경 본문이 아니라 자리표시용 문장입니다.
/// (번역본 본문은 저작권이 있을 수 있어서 일부러 가짜 문장을 씁니다.)
class SampleBibleTextSource implements BibleTextSource {
  // 장이 넘어가는 범위에서 중간 장의 절 수를 모르므로 샘플에서는 30절로 가정
  static const int _assumedVersesPerChapter = 30;

  /// 샘플에서는 모든 책을 5장으로 가정
  @override
  Future<Map<String, int>> chapterCounts() async => {
    for (final code in bookNames.keys) code: 5,
  };

  @override
  Future<List<VerseText>> getVerses({
    required String book,
    required int chapter,
    required int verseStart,
    required int chapterEnd,
    required int verseEnd,
  }) async {
    final result = <VerseText>[];

    for (var c = chapter; c <= chapterEnd; c++) {
      final start = c == chapter ? verseStart : 1;
      final end = c == chapterEnd ? verseEnd : _assumedVersesPerChapter;

      for (var v = start; v <= end; v++) {
        // 3절마다 문장을 길게 해서 줄바꿈이 어떻게 보이는지 확인
        final longer = v % 3 == 0 ? ' 줄바꿈과 문단 모양을 확인하기 위해 덧붙인 긴 문장입니다.' : '';
        result.add(
          VerseText(
            c,
            v,
            '${bookName(book)} $c장 $v절 샘플 본문입니다. '
            '실제 성경 본문은 나중에 DB를 연결하면 표시됩니다.$longer',
          ),
        );
      }
    }
    return result;
  }
}
