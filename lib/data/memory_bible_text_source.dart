import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import 'bible_text_source.dart';
import 'ref_format.dart';

/// 성경 본문 JSON(assets)을 통째로 메모리에 올려 두고 읽는 본문 공급처.
///
/// 웹에서는 SQLite를 쓸 수 없어서, 앱을 켤 때마다 JSON을 읽어 메모리에 둡니다.
/// (본문은 읽기만 하므로 DB가 없어도 충분합니다. 브라우저가 파일을 기억해 두어 두 번째부터는 빠름)
///
/// 사용: final bible = await MemoryBibleTextSource.load();
class MemoryBibleTextSource implements BibleTextSource {
  MemoryBibleTextSource(this._books);

  static const String assetPath = 'assets/data/koreanbible.json';

  /// 책 코드 → 장 번호 → 그 장의 절들 (절 번호 순)
  final Map<String, Map<int, List<VerseText>>> _books;

  /// JSON을 읽어 가공한 뒤 메모리에 올립니다.
  static Future<MemoryBibleTextSource> load() async {
    final raw = await rootBundle.loadString(assetPath);
    // 8MB짜리 JSON 해석은 별도 작업 공간(isolate)에서 해서 화면이 멈추지 않게 함
    // (웹에서는 같은 곳에서 돌지만 결과는 같습니다)
    return MemoryBibleTextSource(await compute(parseBible, raw));
  }

  @override
  Future<Map<String, int>> chapterCounts() async => {
    for (final e in _books.entries)
      e.key: e.value.keys.reduce((a, b) => a > b ? a : b),
  };

  @override
  Future<List<VerseText>> getVerses({
    required String book,
    required int chapter,
    required int verseStart,
    required int chapterEnd,
    required int verseEnd,
  }) async {
    final chapters = _books[book];
    if (chapters == null) return const [];

    // (장 × 1000 + 절)로 바꿔서 "8장 23절 ~ 9장 2절" 같은 범위도 한 번에 찾습니다.
    final start = chapter * 1000 + verseStart;
    final end = chapterEnd * 1000 + verseEnd;
    return [
      for (var c = chapter; c <= chapterEnd; c++)
        for (final v in chapters[c] ?? const <VerseText>[])
          if (v.chapter * 1000 + v.verse >= start &&
              v.chapter * 1000 + v.verse <= end)
            v,
    ];
  }
}

// compute()에 넘기려면 클래스 밖(최상위)에 있어야 합니다.

/// 본문 앞의 괄호를 소제목으로 떼어 낼지 여부.
/// 개역개정 파일에는 "(세례를 받으시다)" 같은 소제목이 붙어 있었지만,
/// 개역한글에는 소제목이 없고 괄호는 본문의 일부입니다. (예: 눅 23:51, 히 7:19)
/// 소제목이 붙은 판본으로 바꾸면 true로 바꾸세요.
const bool _extractHeadings = false;

/// 소제목으로 볼 패턴: 맨 앞의 짧은 괄호(30자 이하, 괄호 안에 괄호 없음) + 그 뒤에 본문
final RegExp _headingPattern = RegExp(r'^\(([^()]{1,30})\)\s+(\S[\s\S]*)$');

/// 시편 1절 앞의 표제: "[다윗의 시, 영장으로 현악에 맞춘 노래] 여호와여…"
final RegExp _psalmTitlePattern = RegExp(r'^\[([^\[\]]+)\]\s*(\S[\s\S]*)$');

/// 사본 문제로 빠지기도 하는 절 앞에 붙은 "(없음)" 표시 (예: 마 17:21)
final RegExp _omittedMark = RegExp(r'^\(없음\)\s*');

/// JSON 한 줄 = {no, book, chapter, paragraph, korean} 을 가공해
/// 책 코드 → 장 → 절 목록으로 묶습니다.
Map<String, Map<int, List<VerseText>>> parseBible(String raw) {
  final list = jsonDecode(raw) as List;

  final used = <String>{}; // 이미 쓴 (책|장|절)
  final maxVerse = <String, int>{}; // 장별로 지금까지 나온 가장 큰 절 번호
  final books = <String, Map<int, List<VerseText>>>{};

  for (final item in list) {
    final r = item as Map<String, dynamic>;

    final name = r['book'] as String;
    final code = codeFromBookName(name);
    if (code == null) {
      // 판본을 바꿨을 때 책 이름 표기가 다르면 여기서 바로 알려 줍니다.
      throw FormatException(
        '책 이름을 알 수 없습니다: $name (ref_format.dart의 bookNames 확인)',
      );
    }

    final chapter = r['chapter'] as int;
    var verse = r['paragraph'] as int;
    var text = (r['korean'] as String).trim();

    // 같은 절 번호가 또 나오면(예: 아모스 2:14 세 번) 그 장의 마지막 절 다음 번호로 보정
    final chapterKey = '$code|$chapter';
    if (!used.add('$chapterKey|$verse')) {
      verse = (maxVerse[chapterKey] ?? verse) + 1;
      used.add('$chapterKey|$verse');
    }
    if (verse > (maxVerse[chapterKey] ?? 0)) maxVerse[chapterKey] = verse;

    // 개역한글 파일은 "(없음)기도와 금식이…"처럼 표시가 본문에 붙어 있습니다.
    // 소제목으로 오인되지 않게 "[없음] 기도와 금식이…"로 바꿔 둡니다.
    // (표시만 있고 본문이 없는 판본이면 "[없음]"만 남음)
    if (_omittedMark.hasMatch(text)) {
      final rest = text.replaceFirst(_omittedMark, '');
      text = rest.isEmpty ? '[없음]' : '[없음] $rest';
    }

    // 본문 앞의 "(세례를 받으시다)" 같은 소제목을 떼어 냅니다.
    String? heading;
    final m = _extractHeadings ? _headingPattern.firstMatch(text) : null;
    if (m != null) {
      heading = m.group(1)!.trim();
      text = m.group(2)!.trim();
    }

    // 시편 표제는 본문과 섞이지 않게 소제목 자리로 옮깁니다. (절 위에 작게 표시됨)
    if (code == 'PSA') {
      final t = _psalmTitlePattern.firstMatch(text);
      if (t != null) {
        heading = t.group(1)!.trim();
        text = t.group(2)!.trim();
      }
    }

    books
        .putIfAbsent(code, () => {})
        .putIfAbsent(chapter, () => [])
        .add(VerseText(chapter, verse, text, heading: heading));
  }

  // 절 번호 순으로 정렬 (번호를 보정한 절이 있어도 순서가 맞게)
  for (final chapters in books.values) {
    for (final verses in chapters.values) {
      verses.sort((a, b) => a.verse.compareTo(b.verse));
    }
  }
  return books;
}
