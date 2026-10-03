import 'package:sqflite/sqflite.dart';

import 'bible_text_source.dart';

/// bible_verse 표에서 실제 성경 본문을 읽어 옵니다.
/// 샘플(SampleBibleTextSource) 대신 main.dart에서 이것을 연결하면 됩니다.
class DbBibleTextSource implements BibleTextSource {
  DbBibleTextSource(this.db);

  final Database db;

  @override
  Future<Map<String, int>> chapterCounts() async {
    final rows = await db.rawQuery(
      'SELECT book, MAX(chapter) AS n FROM bible_verse GROUP BY book',
    );
    return {for (final r in rows) r['book'] as String: r['n'] as int};
  }

  @override
  Future<List<VerseText>> getVerses({
    required String book,
    required int chapter,
    required int verseStart,
    required int chapterEnd,
    required int verseEnd,
  }) async {
    // (장 × 1000 + 절)로 바꿔서 "8장 23절 ~ 9장 2절" 같은 범위도 한 번에 찾습니다.
    final rows = await db.query(
      'bible_verse',
      where: 'book = ? AND (chapter * 1000 + verse) BETWEEN ? AND ?',
      whereArgs: [
        book,
        chapter * 1000 + verseStart,
        chapterEnd * 1000 + verseEnd,
      ],
      orderBy: 'chapter, verse',
    );

    return [
      for (final r in rows)
        VerseText(
          r['chapter'] as int,
          r['verse'] as int,
          r['text'] as String,
          heading: r['heading'] as String?,
        ),
    ];
  }
}
