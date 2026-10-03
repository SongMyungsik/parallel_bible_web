import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/parallel_importer.dart';
import '../data/ref_format.dart';

/// 구약 인용 하나가 인용한 첫 구약 본문의 위치 ("구약 순서" 정렬용)
class OtPosition {
  const OtPosition(this.book, this.bookIndex, this.position);

  final String book; // 책 코드 (예: ISA)
  final int bookIndex; // 성경 순서 (창세기 = 0)
  final int position; // 장*1000 + 절
}

/// 묶음 목록(복음서 병행, 구약 인용)과 구절 위치를 DB에서 읽어 화면에 전달합니다.
class ParallelState extends ChangeNotifier {
  ParallelState(this.db);

  final Database db;

  /// 복음서 병행 목록 (생애 단계 → 순서대로)
  List<Map<String, Object?>> groups = [];

  /// 구약 인용 목록 (생애 단계 → 순서대로)
  List<Map<String, Object?>> quotations = [];

  /// 묶음 id → "마태 3:13-17 · 마가 1:9-11 …" 같은 요약 (검색·목록 표시용)
  Map<int, String> parallelSummaries = {};
  Map<int, String> quotationSummaries = {};

  /// 복음서 병행 id → 그 사건의 구절 위치들 (대조표 칸용)
  Map<int, List<Map<String, Object?>>> parallelRefs = {};

  /// 구약 인용 id → 그 인용의 구절 위치들 (대조표 칸용)
  Map<int, List<Map<String, Object?>>> quotationRefs = {};

  /// 구약 인용 id → 인용한 첫 구약 본문 위치
  Map<int, OtPosition> quotationOt = {};

  /// 묶음 id → 생애 단계·책 소제목 번호 (무료 범위 판단용)
  final Map<int, int> _sections = {};

  /// 이 묶음의 section 번호. 모르는 id면 0.
  int sectionOf(int id) => _sections[id] ?? 0;

  bool loading = true;

  Future<void> loadGroups() async {
    groups = await ParallelImporter.getGroups(db, PassageCollection.parallel);
    quotations = await ParallelImporter.getGroups(
      db,
      PassageCollection.quotation,
    );

    _sections
      ..clear()
      ..addAll({
        for (final g in [...groups, ...quotations])
          g['id'] as int: g['section'] as int,
      });

    final parRefs = await ParallelImporter.getRefsOfCollection(
      db,
      PassageCollection.parallel,
    );
    parallelSummaries = _summaries(parRefs);
    parallelRefs = {};
    for (final r in parRefs) {
      parallelRefs.putIfAbsent(r['group_id'] as int, () => []).add(r);
    }

    final quoteRefs = await ParallelImporter.getRefsOfCollection(
      db,
      PassageCollection.quotation,
    );
    quotationSummaries = _summaries(quoteRefs);
    quotationRefs = {};
    for (final r in quoteRefs) {
      quotationRefs.putIfAbsent(r['group_id'] as int, () => []).add(r);
    }

    final books = bookNames.keys.toList();
    quotationOt = {};
    for (final r in quoteRefs) {
      final id = r['group_id'] as int;
      final book = r['book'] as String;
      if (!isOldTestament(book) || quotationOt.containsKey(id)) continue;
      quotationOt[id] = OtPosition(
        book,
        books.indexOf(book),
        (r['chapter'] as int) * 1000 + (r['verse_start'] as int),
      );
    }

    loading = false;
    notifyListeners();
  }

  static Map<int, String> _summaries(List<Map<String, Object?>> refs) {
    final byGroup = <int, List<Map<String, Object?>>>{};
    for (final r in refs) {
      byGroup.putIfAbsent(r['group_id'] as int, () => []).add(r);
    }
    return {for (final e in byGroup.entries) e.key: formatRefsSummary(e.value)};
  }

  Future<List<Map<String, Object?>>> getRefs(int groupId) {
    return ParallelImporter.getRefs(db, groupId);
  }

  /// 성경의 한 장에 걸친 병행·인용 범위들
  Future<List<Map<String, Object?>>> getRefsInChapter(
    String book,
    int chapter,
  ) {
    return ParallelImporter.getRefsInChapter(db, book, chapter);
  }
}
