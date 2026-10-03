import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_bible_web/data/memory_bible_text_source.dart';
import 'package:parallel_bible_web/data/passage_data.dart';

/// 실제 assets/data의 JSON을 메모리에 올려 보는 검사 (DB 없이 웹에서 쓰는 방식)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('병행 138개 · 인용 204개를 읽고 검사를 통과함', () async {
    final data = await PassageData.load();
    final parallels = data.groups(PassageCollection.parallel);
    final quotations = data.groups(PassageCollection.quotation);
    expect(parallels.length, 138);
    expect(quotations.length, 204);

    // 예수님의 세례(id 1): 마태·마가·누가 (요한은 다른 본문)
    final baptism = parallels.firstWhere((g) => g['id'] == 1);
    expect(baptism['title'], '예수님의 세례');
    expect(baptism['gospel_count'], greaterThanOrEqualTo(3));
    expect(data.refs(1).first['book'], 'MAT');

    // 생애 단계 순서대로 정렬 (단계 0 = 기타는 맨 뒤)
    final sections = [for (final g in parallels) g['section'] as int];
    final nonZero = sections.where((s) => s != 0).toList();
    expect(nonZero, [...nonZero]..sort());
  });

  test('성경의 한 장에 걸친 병행·인용 칩 (마태 3장에 세례)', () async {
    final data = await PassageData.load();
    final rows = data.refsInChapter('MAT', 3);
    expect(rows.any((r) => r['group_id'] == 1), isTrue);
    for (final r in rows) {
      expect(r['chapter'] as int, lessThanOrEqualTo(3));
      expect(r['chapter_end'] as int, greaterThanOrEqualTo(3));
      expect(r['collection'], anyOf('parallel', 'quotation'));
    }
  });

  test('성경 본문 66권 31,102절, 장을 넘는 범위도 읽음', () async {
    final bible = await MemoryBibleTextSource.load();
    final counts = await bible.chapterCounts();
    expect(counts.length, 66);
    expect(counts['GEN'], 50);
    expect(counts['REV'], 22);

    var total = 0;
    for (final e in counts.entries) {
      total += (await bible.getVerses(
        book: e.key,
        chapter: 1,
        verseStart: 1,
        chapterEnd: e.value,
        verseEnd: 999,
      )).length;
    }
    expect(total, 31102);

    // 마태 8:23 ~ 9:2
    final verses = await bible.getVerses(
      book: 'MAT',
      chapter: 8,
      verseStart: 23,
      chapterEnd: 9,
      verseEnd: 2,
    );
    expect(verses.first.chapter, 8);
    expect(verses.first.verse, 23);
    expect(verses.last.chapter, 9);
    expect(verses.last.verse, 2);

    // "(없음)" 표시는 "[없음] …"으로 (마 17:21)
    final omitted = await bible.getVerses(
      book: 'MAT',
      chapter: 17,
      verseStart: 21,
      chapterEnd: 17,
      verseEnd: 21,
    );
    expect(omitted.single.text, startsWith('[없음]'));
  });
}
