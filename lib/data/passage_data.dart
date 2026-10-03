import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'ref_format.dart';

/// 묶음 데이터의 종류. JSON 파일 하나 = 종류 하나.
enum PassageCollection {
  /// 복음서 병행 (id 1~)
  parallel('parallel', 'assets/data/synoptic_parallels.json'),

  /// 신약의 구약 인용 (id 1001~)
  quotation('quotation', 'assets/data/ot_quotations.json');

  const PassageCollection(this.key, this.assetPath);

  /// 묶음 줄의 'collection' 칸에 들어가는 이름
  final String key;
  final String assetPath;
}

/// 병행·인용 데이터(JSON)를 메모리에 올려 두고 화면에 필요한 모양으로 꺼내 주는 곳.
///
/// 예전(앱판)에는 SQLite 표에 넣고 SQL로 찾았지만, 웹에서는 SQLite를 쓸 수 없어
/// 같은 모양의 줄(Map)을 메모리에서 만들어 돌려줍니다. 화면 코드는 그대로 씁니다.
///
///  - 묶음 줄: {id, title, collection, section, sort_order, gospel_count, gospels}
///  - 구절 줄: {id, group_id, book, chapter, verse_start, chapter_end, verse_end, doublet(0/1)}
///
/// 사용: final data = await PassageData.load();
class PassageData {
  PassageData._();

  /// 종류별 묶음 목록 (생애 단계 → 순서대로)
  final Map<PassageCollection, List<Map<String, Object?>>> _groups = {};

  /// 종류별 구절 위치 전체 (JSON에 적힌 순서)
  final Map<PassageCollection, List<Map<String, Object?>>> _refsOf = {};

  /// 묶음 id → 묶음 줄
  final Map<int, Map<String, Object?>> _groupById = {};

  /// 묶음 id → 그 묶음의 구절 위치들
  final Map<int, List<Map<String, Object?>>> _refsByGroup = {};

  /// 책 코드 → 그 책에 걸친 구절 위치들 (성경 화면의 칩용)
  final Map<String, List<Map<String, Object?>>> _refsByBook = {};

  /// 두 JSON을 읽어 검사한 뒤 메모리에 올립니다. 잘못된 곳이 있으면 FormatException.
  static Future<PassageData> load() async {
    final data = PassageData._();
    for (final c in PassageCollection.values) {
      final raw = await rootBundle.loadString(c.assetPath);
      data.add(c, jsonDecode(raw) as Map<String, dynamic>);
    }
    return data;
  }

  /// JSON 하나(종류 하나)를 넣습니다. (테스트에서 직접 부를 수 있게 공개)
  void add(PassageCollection collection, Map<String, dynamic> json) {
    // 넣기 전에 JSON에 실수가 없는지 검사 (잘못됐으면 여기서 멈춤)
    final groups = _parseAndValidate(json, collection);

    // 다른 종류의 묶음과 id가 겹치면 멈춤 (병행 1~, 인용 1001~)
    for (final g in groups) {
      if (_groupById.containsKey(g['id'])) {
        throw FormatException(
          '${collection.assetPath}: 묶음 id ${g['id']}가 다른 데이터와 겹칩니다',
        );
      }
    }

    final groupRows = <Map<String, Object?>>[];
    final refRows = <Map<String, Object?>>[];
    var refId = _refsByGroup.values.fold<int>(0, (n, l) => n + l.length);

    for (final g in groups) {
      final id = g['id'] as int;
      final refs = <Map<String, Object?>>[];
      for (final r in (g['refs'] as List).cast<Map<String, dynamic>>()) {
        final chapter = r['chapter'] as int;
        refs.add({
          'id': ++refId,
          'group_id': id,
          'book': r['book'] as String,
          'chapter': chapter,
          'verse_start': r['verse_start'] as int,
          // chapter_end를 안 적으면 시작 장과 같은 것으로 처리
          'chapter_end': (r['chapter_end'] as int?) ?? chapter,
          'verse_end': r['verse_end'] as int,
          // 같은 복음서의 다른 곳에 나오는 같은 말씀이면 1
          'doublet': r['doublet'] == true ? 1 : 0,
        });
      }

      // 이 묶음이 나오는 책들 (반복 말씀은 세지 않음)
      final books = <String>{
        for (final r in refs)
          if (r['doublet'] == 0) r['book'] as String,
      };
      final row = <String, Object?>{
        'id': id,
        'title': g['title'] as String,
        'collection': collection.key,
        // 없으면 0 (목록에서 "기타"로 맨 뒤, id 순)
        'section': (g['section'] as int?) ?? 0,
        'sort_order': (g['order'] as int?) ?? 0,
        'gospel_count': books.length,
        // 책 코드들, 쉼표로 이음 (예: "MAT,MRK,LUK")
        'gospels': books.join(','),
      };

      groupRows.add(row);
      refRows.addAll(refs);
      _groupById[id] = row;
      _refsByGroup[id] = refs;
      for (final r in refs) {
        _refsByBook.putIfAbsent(r['book'] as String, () => []).add(r);
      }
    }

    // 생애 단계 → 순서 → id (단계 0 = 기타는 맨 뒤)
    groupRows.sort((a, b) {
      final sa = a['section'] as int, sb = b['section'] as int;
      if ((sa == 0) != (sb == 0)) return sa == 0 ? 1 : -1;
      final c1 = sa.compareTo(sb);
      if (c1 != 0) return c1;
      final c2 = (a['sort_order'] as int).compareTo(b['sort_order'] as int);
      if (c2 != 0) return c2;
      return (a['id'] as int).compareTo(b['id'] as int);
    });

    _groups[collection] = groupRows;
    _refsOf[collection] = refRows;
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

  /// 한 종류의 묶음 목록 (생애 단계 → 순서대로)
  List<Map<String, Object?>> groups(PassageCollection collection) =>
      _groups[collection] ?? const [];

  /// 한 종류에 속한 모든 구절 위치 (목록에 "마태 1:22-23 · 이사야 7:14"를 쓰기 위함)
  List<Map<String, Object?>> refsOfCollection(PassageCollection collection) =>
      _refsOf[collection] ?? const [];

  /// 묶음 하나에 속한 구절 위치 (JSON에 적힌 순서 = 칸 순서)
  List<Map<String, Object?>> refs(int groupId) =>
      _refsByGroup[groupId] ?? const [];

  /// 성경의 한 장에 걸쳐 있는 병행·인용 범위들 (성경 화면의 표시용)
  /// 각 줄: 범위(chapter, verse_start, chapter_end, verse_end) + 묶음 정보
  /// (group_id, title, collection, gospel_count = 묶음이 나오는 책 수)
  List<Map<String, Object?>> refsInChapter(String book, int chapter) {
    final rows = [
      for (final r in _refsByBook[book] ?? const <Map<String, Object?>>[])
        if ((r['chapter'] as int) <= chapter &&
            (r['chapter_end'] as int) >= chapter)
          {
            'group_id': r['group_id'],
            'chapter': r['chapter'],
            'verse_start': r['verse_start'],
            'chapter_end': r['chapter_end'],
            'verse_end': r['verse_end'],
            'title': _groupById[r['group_id']]!['title'],
            'collection': _groupById[r['group_id']]!['collection'],
            'gospel_count': _groupById[r['group_id']]!['gospel_count'],
          },
    ];
    // 장 → 시작 절 → 병행 먼저(parallel < quotation) → 묶음 id
    int cmp(Map<String, Object?> a, Map<String, Object?> b, String key) =>
        (a[key] as Comparable).compareTo(b[key]);
    rows.sort((a, b) {
      for (final key in ['chapter', 'verse_start', 'collection', 'group_id']) {
        final c = cmp(a, b, key);
        if (c != 0) return c;
      }
      return 0;
    });
    return rows;
  }
}
