import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'ref_format.dart';

/// 묶음 데이터의 종류. JSON 파일 하나 = 종류 하나.
enum PassageCollection {
  /// 복음서 병행 (id 1~)
  parallel('parallel', 'assets/data/synoptic_parallels.json', 'data_version'),

  /// 신약의 구약 인용 (id 1001~)
  quotation('quotation', 'assets/data/ot_quotations.json', 'quotation_version');

  const PassageCollection(this.key, this.assetPath, this.metaKey);

  /// DB의 passage_group.collection 칸에 저장되는 이름
  final String key;
  final String assetPath;

  /// parallel_meta 표에서 이 데이터의 version을 기억하는 이름
  final String metaKey;
}

/// 병행·인용 데이터(JSON)를 SQLite에 넣는 도우미.
///
/// 사용 순서 (앱 시작 시, DB를 연 직후):
///   await ParallelImporter.createTables(db);
///   await ParallelImporter.importIfNeeded(db, PassageCollection.parallel);
///   await ParallelImporter.importIfNeeded(db, PassageCollection.quotation);
class ParallelImporter {
  ParallelImporter._();

  /// 표 3개를 만듭니다. 이미 있으면 그대로 둡니다.
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS passage_group (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        collection TEXT NOT NULL DEFAULT 'parallel',
        section INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS passage_ref (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse_start INTEGER NOT NULL,
        chapter_end INTEGER NOT NULL,
        verse_end INTEGER NOT NULL,
        doublet INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES passage_group(id)
      )
    ''');

    // 예전에 만든 표에는 없는 칸을 덧붙입니다.
    await _addColumnIfMissing(
      db,
      'passage_ref',
      'doublet',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'passage_group',
      'collection',
      "TEXT NOT NULL DEFAULT 'parallel'",
    );
    // 생애 단계와 목록 순서 (tool/assign_order.py가 JSON에 붙임)
    await _addColumnIfMissing(
      db,
      'passage_group',
      'section',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      'passage_group',
      'sort_order',
      'INTEGER NOT NULL DEFAULT 0',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ref_group ON passage_ref(group_id)',
    );

    // JSON의 version 값을 기억해 두는 표 (같은 데이터를 또 넣지 않기 위함)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parallel_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((c) => c['name'] == column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  /// JSON의 version이 DB에 저장된 것보다 높을 때만 다시 넣습니다.
  /// 다른 종류의 묶음은 건드리지 않습니다.
  /// 새로 넣었으면 true, 건너뛰었으면 false를 돌려줍니다.
  static Future<bool> importIfNeeded(
    Database db,
    PassageCollection collection,
  ) async {
    final raw = await rootBundle.loadString(collection.assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final newVersion = data['version'] as int;

    final rows = await db.query(
      'parallel_meta',
      where: 'key = ?',
      whereArgs: [collection.metaKey],
    );
    final currentVersion = rows.isEmpty
        ? 0
        : int.parse(rows.first['value'] as String);

    if (currentVersion >= newVersion) return false;

    // 넣기 전에 JSON에 실수가 없는지 검사 (잘못됐으면 여기서 멈춤)
    final groups = _parseAndValidate(data, collection);

    // 다른 종류의 묶음과 id가 겹치면 멈춤 (병행 1~, 인용 1001~)
    final others = await db.query(
      'passage_group',
      columns: ['id'],
      where: 'collection != ?',
      whereArgs: [collection.key],
    );
    final otherIds = {for (final r in others) r['id'] as int};
    for (final g in groups) {
      if (otherIds.contains(g['id'])) {
        throw FormatException(
          '${collection.assetPath}: 묶음 id ${g['id']}가 다른 데이터와 겹칩니다',
        );
      }
    }

    // 트랜잭션: 중간에 오류가 나면 전부 취소되어 DB가 반쯤 채워지는 일이 없음
    await db.transaction((txn) async {
      await txn.delete(
        'passage_ref',
        where:
            'group_id IN (SELECT id FROM passage_group WHERE collection = ?)',
        whereArgs: [collection.key],
      );
      await txn.delete(
        'passage_group',
        where: 'collection = ?',
        whereArgs: [collection.key],
      );

      final batch = txn.batch();
      for (final g in groups) {
        batch.insert('passage_group', {
          'id': g['id'],
          'title': g['title'],
          'collection': collection.key,
          // 없으면 0 (목록에서 "기타"로 맨 뒤, id 순)
          'section': (g['section'] as int?) ?? 0,
          'sort_order': (g['order'] as int?) ?? 0,
        });

        for (final r in (g['refs'] as List).cast<Map<String, dynamic>>()) {
          final chapter = r['chapter'] as int;
          batch.insert('passage_ref', {
            'group_id': g['id'],
            'book': r['book'],
            'chapter': chapter,
            'verse_start': r['verse_start'],
            // chapter_end를 안 적으면 시작 장과 같은 것으로 처리
            'chapter_end': (r['chapter_end'] as int?) ?? chapter,
            'verse_end': r['verse_end'],
            // 같은 복음서의 다른 곳에 나오는 같은 말씀이면 1
            'doublet': r['doublet'] == true ? 1 : 0,
          });
        }
      }

      batch.insert('parallel_meta', {
        'key': collection.metaKey,
        'value': '$newVersion',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await batch.commit(noResult: true);
    });

    return true;
  }

  /// JSON 내용을 검사합니다. 문제가 있으면 어느 묶음인지 알려주며 멈춥니다.
  static List<Map<String, dynamic>> _parseAndValidate(
    Map<String, dynamic> data,
    PassageCollection collection,
  ) {
    final groups = (data['groups'] as List).cast<Map<String, dynamic>>();
    final seenIds = <int>{};

    for (final g in groups) {
      final id = g['id'] as int;

      if (!seenIds.add(id)) {
        throw FormatException('중복된 묶음 id: $id');
      }
      if ((g['title'] as String).trim().isEmpty) {
        throw FormatException('묶음 $id: 제목이 비어 있습니다');
      }

      final refs = (g['refs'] as List).cast<Map<String, dynamic>>();

      for (final r in refs) {
        if (!bookNames.containsKey(r['book'])) {
          throw FormatException('묶음 $id: 알 수 없는 책 코드 ${r['book']}');
        }
      }

      // 반복 말씀(doublet)을 뺀 본문의 책들
      final mainBooks = {
        for (final r in refs)
          if (r['doublet'] != true) r['book'] as String,
      };

      switch (collection) {
        case PassageCollection.parallel:
          // 서로 다른 복음서 2권 이상에 있어야 병행
          if (mainBooks.length < 2) {
            throw FormatException('묶음 $id: 서로 다른 복음서가 2권 이상이어야 합니다');
          }
        case PassageCollection.quotation:
          // 신약 본문과 구약 본문이 모두 있어야 인용
          if (!mainBooks.any(isOldTestament) ||
              mainBooks.every(isOldTestament)) {
            throw FormatException('묶음 $id: 신약과 구약 본문이 모두 있어야 합니다');
          }
      }

      for (final r in refs) {
        if (r['doublet'] == true && !mainBooks.contains(r['book'])) {
          throw FormatException(
            '묶음 $id: 반복 말씀(${r['book']})은 같은 책의 본문도 있어야 합니다',
          );
        }
      }

      for (final r in refs) {
        final chapter = r['chapter'] as int;
        final chapterEnd = (r['chapter_end'] as int?) ?? chapter;
        final verseStart = r['verse_start'] as int;
        final verseEnd = r['verse_end'] as int;

        final rangeIsWrong =
            chapterEnd < chapter ||
            (chapterEnd == chapter && verseEnd < verseStart);
        if (rangeIsWrong) {
          throw FormatException(
            '묶음 $id: 절 범위 오류 (${r['book']} $chapter:$verseStart-$verseEnd)',
          );
        }
      }
    }
    return groups;
  }

  // ---- 화면에서 쓸 조회 함수 ----

  /// 한 종류의 묶음 목록 (생애 단계 → 순서대로).
  /// gospel_count = 이 묶음이 나오는 책 수 (반복 말씀은 세지 않음)
  /// gospels = 그 책 코드들, 쉼표로 이음 (예: "MAT,MRK,LUK", 순서는 정해지지 않음)
  static Future<List<Map<String, Object?>>> getGroups(
    Database db,
    PassageCollection collection,
  ) {
    return db.rawQuery(
      '''
      SELECT g.id, g.title, g.section, g.sort_order,
             COUNT(DISTINCT CASE WHEN r.doublet = 0 THEN r.book END) AS gospel_count,
             GROUP_CONCAT(DISTINCT CASE WHEN r.doublet = 0 THEN r.book END) AS gospels
      FROM passage_group g
      LEFT JOIN passage_ref r ON r.group_id = g.id
      WHERE g.collection = ?
      GROUP BY g.id
      ORDER BY (g.section = 0), g.section, g.sort_order, g.id
    ''',
      [collection.key],
    );
  }

  /// 한 종류에 속한 모든 구절 위치 (목록에 "마태 1:22-23 · 이사야 7:14"를 쓰기 위함)
  static Future<List<Map<String, Object?>>> getRefsOfCollection(
    Database db,
    PassageCollection collection,
  ) {
    return db.rawQuery(
      '''
      SELECT r.* FROM passage_ref r
      JOIN passage_group g ON g.id = r.group_id
      WHERE g.collection = ?
      ORDER BY r.id
    ''',
      [collection.key],
    );
  }

  /// 성경의 한 장에 걸쳐 있는 병행·인용 범위들 (성경 화면의 표시용)
  /// 각 줄: 범위(chapter, verse_start, chapter_end, verse_end) + 묶음 정보
  /// (group_id, title, collection, gospel_count = 묶음이 나오는 책 수)
  static Future<List<Map<String, Object?>>> getRefsInChapter(
    Database db,
    String book,
    int chapter,
  ) {
    return db.rawQuery(
      '''
      SELECT r.group_id, r.chapter, r.verse_start, r.chapter_end, r.verse_end,
             g.title, g.collection,
             (SELECT COUNT(DISTINCT r2.book) FROM passage_ref r2
               WHERE r2.group_id = g.id AND r2.doublet = 0) AS gospel_count
      FROM passage_ref r
      JOIN passage_group g ON g.id = r.group_id
      WHERE r.book = ? AND r.chapter <= ? AND r.chapter_end >= ?
      ORDER BY r.chapter, r.verse_start, g.collection, g.id
    ''',
      [book, chapter, chapter],
    );
  }

  /// 묶음 하나에 속한 구절 위치
  static Future<List<Map<String, Object?>>> getRefs(Database db, int groupId) {
    return db.query(
      'passage_ref',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'id',
    );
  }
}
