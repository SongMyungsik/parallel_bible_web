/// 화면에 그릴 단어 하나. (띄어쓰기로 나눈 한 덩어리)
class MatchedWord {
  const MatchedWord(this.text, this.sharedBy);

  /// 원문 그대로 (문장부호 포함)
  final String text;

  /// 이 표현이 나오는 복음서 수: 1 = 이 복음서에만, 2 = 두 복음서, 3 = 세 복음서 ...
  final int sharedBy;
}

/// 여러 칸(복음서)의 본문을 비교해서 "같은 표현"을 찾아 줍니다.
///
/// 규칙: **연달아 붙은 두 단어**가 다른 칸에도 그대로(또는 거의 그대로) 나올 때만
/// 그 두 단어를 공통 표현으로 봅니다.
/// 단어 하나씩 비교하면 "때에", "하시니" 같은 흔한 말까지 전부 칠해져서
/// 비교하기 어려워지기 때문입니다.
class WordMatcher {
  WordMatcher._();

  /// [columns]\[덩어리\]\[절\] = 그 절의 본문. (덩어리 = 참조 하나)
  /// [books]\[덩어리\] = 그 덩어리가 속한 복음서 코드 (MAT, LUK ...).
  ///
  /// 같은 복음서끼리는 비교하지 않습니다.
  /// (나뉜 본문이나 한 복음서 안에서 반복된 말씀이 "두 복음서 공통"으로 칠해지지 않게)
  ///
  /// 반환값 result\[덩어리\]\[절\] = 그 절을 단어로 나눈 목록.
  static List<List<List<MatchedWord>>> analyze(
    List<List<String>> columns,
    List<String> books,
  ) {
    // 1) 칸마다 모든 절의 단어를 한 줄로 나열 (절이 바뀌어도 이어서 비교)
    final seqs = <List<_Cell>>[];
    for (final verses in columns) {
      final seq = <_Cell>[];
      for (var v = 0; v < verses.length; v++) {
        for (final raw in verses[v].split(RegExp(r'\s+'))) {
          if (raw.isEmpty) continue;
          seq.add(_Cell(v, raw, _normalize(raw)));
        }
      }
      seqs.add(seq);
    }

    // 2) 덩어리 쌍마다 "연속 두 단어"가 같은 자리를 찾아,
    //    그 자리가 나오는 다른 복음서를 모아 둠
    final foundIn = [
      for (final s in seqs) List.generate(s.length, (_) => <String>{}),
    ];

    for (var i = 0; i < seqs.length; i++) {
      for (var j = 0; j < seqs.length; j++) {
        if (books[i] == books[j]) continue;

        final a = seqs[i];
        final b = seqs[j];
        final hit = <int>{};

        for (var k = 0; k + 1 < a.length; k++) {
          for (var m = 0; m + 1 < b.length; m++) {
            if (_sameWord(a[k].key, b[m].key) &&
                _sameWord(a[k + 1].key, b[m + 1].key)) {
              hit
                ..add(k)
                ..add(k + 1);
              break; // 이 자리는 찾았으니 다음 자리로
            }
          }
        }
        for (final k in hit) {
          foundIn[i][k].add(books[j]);
        }
      }
    }

    // 3) 절별로 다시 나누어 돌려주기
    final result = <List<List<MatchedWord>>>[];
    for (var i = 0; i < seqs.length; i++) {
      final verses = List.generate(columns[i].length, (_) => <MatchedWord>[]);
      for (var k = 0; k < seqs[i].length; k++) {
        final cell = seqs[i][k];
        // 자기 복음서(1) + 같은 표현이 나오는 다른 복음서 수
        verses[cell.verse].add(MatchedWord(cell.raw, 1 + foundIn[i][k].length));
      }
      result.add(verses);
    }
    return result;
  }

  /// 한글·영문·숫자만 남깁니다. ("세례를," → "세례를")
  /// "[없음]" 같은 대괄호 표시는 본문이 아니므로 비교하지 않습니다(빈 글자).
  static String _normalize(String word) {
    if (word.startsWith('[') && word.endsWith(']')) return '';
    return word.replaceAll(RegExp(r'[^\uAC00-\uD7A3A-Za-z0-9]'), '');
  }

  /// 두 단어가 같은 말인지 판단합니다.
  /// 한국어는 조사·어미가 뒤에 붙어 모양이 바뀌므로(예: 하나님의/하나님이),
  /// 앞부분(어간)이 같으면 같은 말로 봅니다.
  static bool _sameWord(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final shorter = a.length < b.length ? a.length : b.length;
    if (shorter < 2) return false;

    var common = 0;
    while (common < shorter && a[common] == b[common]) {
      common++;
    }
    // 앞부분이 2글자 이상 같고, 짧은 쪽 단어에서 최대 1글자만 다를 때
    return common >= 2 && common >= shorter - 1;
  }
}

class _Cell {
  const _Cell(this.verse, this.raw, this.key);

  final int verse; // 몇 번째 절인지
  final String raw; // 원문 단어
  final String key; // 비교용(문장부호 뺀) 단어
}
