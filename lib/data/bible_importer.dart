import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'ref_format.dart';

/// 성경 본문 JSON(assets)을 SQLite 표 `bible_verse`로 옮기는 도우미.
///
/// 사용 순서 (앱 시작 시, DB를 연 직후):
///   await BibleImporter.createTables(db);
///   await BibleImporter.importIfNeeded(db);
class BibleImporter {
  BibleImporter._();

  static const String assetPath = 'assets/data/koreanbible.json';

  /// 성경 데이터 파일을 바꾸면(예: 개역개정 → 개역한글) 이 숫자를 올리세요.
  /// 숫자가 올라가면 다음 실행 때 본문을 통째로 다시 넣습니다.
  /// 1 = 개역개정, 2 = 개역한글(신약), 3 = 개역한글 + "[없음]" 표기,
  /// 4 = 개역한글 구약·신약 + 시편 표제,
  /// 5 = [없음] 13절의 본문을 예전 신약 파일(koreanbible.csv)에서 채움
  static const int dataVersion = 5;

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bible_verse (
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        heading TEXT,
        text TEXT NOT NULL,
        PRIMARY KEY (book, chapter, verse)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bible_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 새로 넣었으면 true, 이미 최신이라 건너뛰었으면 false.
  static Future<bool> importIfNeeded(Database db) async {
    final rows = await db.query(
      'bible_meta',
      where: 'key = ?',
      whereArgs: ['data_version'],
    );
    final current = rows.isEmpty ? 0 : int.parse(rows.first['value'] as String);
    if (current >= dataVersion) return false;

    final raw = await rootBundle.loadString(assetPath);

    // 8MB짜리 JSON 해석은 별도 작업 공간(isolate)에서 해서 화면이 멈추지 않게 함
    final verses = await compute(_parseBible, raw);

    await db.transaction((txn) async {
      await txn.delete('bible_verse');

      final batch = txn.batch();
      for (final v in verses) {
        batch.insert('bible_verse', v);
      }
      batch.insert('bible_meta', {
        'key': 'data_version',
        'value': '$dataVersion',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });

    return true;
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

/// JSON 한 줄 = {no, book, chapter, paragraph, korean} 을
/// DB에 넣을 {book(코드), chapter, verse, heading, text} 로 바꿉니다.
List<Map<String, Object?>> _parseBible(String raw) {
  final list = jsonDecode(raw) as List;

  final used = <String>{}; // 이미 쓴 (책|장|절)
  final maxVerse = <String, int>{}; // 장별로 지금까지 나온 가장 큰 절 번호
  final rows = <Map<String, Object?>>[];

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

    rows.add({
      'book': code,
      'chapter': chapter,
      'verse': verse,
      'heading': heading,
      'text': text,
    });
  }
  return rows;
}
