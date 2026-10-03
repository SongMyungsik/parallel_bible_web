import 'package:flutter/foundation.dart';

/// 성경 화면에서 열어 달라는 요청: 책·장 + 강조할 구절 범위들
class BibleTarget {
  const BibleTarget(this.book, this.chapter, this.highlight);

  final String book;
  final int chapter;

  /// 강조할 범위 (passage_ref 형태: chapter, verse_start, chapter_end, verse_end)
  final List<Map<String, Object?>> highlight;
}

/// 화면끼리 주고받는 이동 요청.
/// 대조 화면에서 "성경에서 보기"를 누르면 여기에 요청을 남기고,
///  - 하단 네비 틀(MainShell)은 성경 탭으로 바꾸고
///  - 성경 화면(BiblePage)은 요청을 꺼내 그 장을 열고 구절을 강조합니다.
class AppNavigation extends ChangeNotifier {
  BibleTarget? _bibleTarget;

  void openBible(BibleTarget target) {
    _bibleTarget = target;
    notifyListeners();
  }

  /// 요청이 있으면 꺼내고 비웁니다. (한 번만 처리되게)
  BibleTarget? takeBibleTarget() {
    final t = _bibleTarget;
    _bibleTarget = null;
    return t;
  }
}
