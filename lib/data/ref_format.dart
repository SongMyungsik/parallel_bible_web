/// 책 코드 → 화면에 보여줄 한글 이름 (66권, 성경 순서)
/// 병행 구절 JSON과 DB는 모두 이 코드(MAT, MRK ...)를 씁니다.
const Map<String, String> bookNames = {
  'GEN': '창세기',
  'EXO': '출애굽기',
  'LEV': '레위기',
  'NUM': '민수기',
  'DEU': '신명기',
  'JOS': '여호수아',
  'JDG': '사사기',
  'RUT': '룻기',
  '1SA': '사무엘상',
  '2SA': '사무엘하',
  '1KI': '열왕기상',
  '2KI': '열왕기하',
  '1CH': '역대상',
  '2CH': '역대하',
  'EZR': '에스라',
  'NEH': '느헤미야',
  'EST': '에스더',
  'JOB': '욥기',
  'PSA': '시편',
  'PRO': '잠언',
  'ECC': '전도서',
  'SNG': '아가',
  'ISA': '이사야',
  'JER': '예레미야',
  'LAM': '예레미야애가',
  'EZK': '에스겔',
  'DAN': '다니엘',
  'HOS': '호세아',
  'JOL': '요엘',
  'AMO': '아모스',
  'OBA': '오바댜',
  'JON': '요나',
  'MIC': '미가',
  'NAM': '나훔',
  'HAB': '하박국',
  'ZEP': '스바냐',
  'HAG': '학개',
  'ZEC': '스가랴',
  'MAL': '말라기',
  'MAT': '마태복음',
  'MRK': '마가복음',
  'LUK': '누가복음',
  'JHN': '요한복음',
  'ACT': '사도행전',
  'ROM': '로마서',
  '1CO': '고린도전서',
  '2CO': '고린도후서',
  'GAL': '갈라디아서',
  'EPH': '에베소서',
  'PHP': '빌립보서',
  'COL': '골로새서',
  '1TH': '데살로니가전서',
  '2TH': '데살로니가후서',
  '1TI': '디모데전서',
  '2TI': '디모데후서',
  'TIT': '디도서',
  'PHM': '빌레몬서',
  'HEB': '히브리서',
  'JAS': '야고보서',
  '1PE': '베드로전서',
  '2PE': '베드로후서',
  '1JN': '요한일서',
  '2JN': '요한이서',
  '3JN': '요한삼서',
  'JUD': '유다서',
  'REV': '요한계시록',
};

/// 한글 이름 → 코드 (성경 데이터를 DB에 넣을 때 사용)
/// 판본마다 책 이름 표기가 조금 달라서 다른 표기도 함께 받습니다.
final Map<String, String> _codeByName = {
  for (final e in bookNames.entries) e.value: e.key,
  '애가': 'LAM',
  '요한1서': '1JN',
  '요한2서': '2JN',
  '요한3서': '3JN',
};

String? codeFromBookName(String name) => _codeByName[name.trim()];

String bookName(String code) => bookNames[code] ?? code;

/// 구약 책 코드 (bookNames의 앞 39권)
final Set<String> _oldTestament = bookNames.keys.take(39).toSet();

/// 구약이면 true (예: ISA → true, MAT → false)
bool isOldTestament(String code) => _oldTestament.contains(code);

/// 책 약자 (표처럼 좁은 칸에 씀). 예: ISA → 사, MAT → 마
const Map<String, String> bookAbbr = {
  'GEN': '창',
  'EXO': '출',
  'LEV': '레',
  'NUM': '민',
  'DEU': '신',
  'JOS': '수',
  'JDG': '삿',
  'RUT': '룻',
  '1SA': '삼상',
  '2SA': '삼하',
  '1KI': '왕상',
  '2KI': '왕하',
  '1CH': '대상',
  '2CH': '대하',
  'EZR': '스',
  'NEH': '느',
  'EST': '에',
  'JOB': '욥',
  'PSA': '시',
  'PRO': '잠',
  'ECC': '전',
  'SNG': '아',
  'ISA': '사',
  'JER': '렘',
  'LAM': '애',
  'EZK': '겔',
  'DAN': '단',
  'HOS': '호',
  'JOL': '욜',
  'AMO': '암',
  'OBA': '옵',
  'JON': '욘',
  'MIC': '미',
  'NAM': '나',
  'HAB': '합',
  'ZEP': '습',
  'HAG': '학',
  'ZEC': '슥',
  'MAL': '말',
  'MAT': '마',
  'MRK': '막',
  'LUK': '눅',
  'JHN': '요',
  'ACT': '행',
  'ROM': '롬',
  '1CO': '고전',
  '2CO': '고후',
  'GAL': '갈',
  'EPH': '엡',
  'PHP': '빌',
  'COL': '골',
  '1TH': '살전',
  '2TH': '살후',
  '1TI': '딤전',
  '2TI': '딤후',
  'TIT': '딛',
  'PHM': '몬',
  'HEB': '히',
  'JAS': '약',
  '1PE': '벧전',
  '2PE': '벧후',
  '1JN': '요일',
  '2JN': '요이',
  '3JN': '요삼',
  'JUD': '유',
  'REV': '계',
};

/// 책마다 한 줄씩 "약자 장:절" 목록 (적힌 순서대로)
/// 예: [사 56:7, 렘 7:11], [마 5:31, 19:7 / 막 10:4 → "마 5:31, 19:7", "막 10:4"]
List<String> formatAbbrLines(List<Map<String, Object?>> refs) {
  final byBook = <String, List<Map<String, Object?>>>{};
  for (final r in refs) {
    byBook.putIfAbsent(r['book'] as String, () => []).add(r);
  }
  return [
    for (final e in byBook.entries)
      '${bookAbbr[e.key] ?? e.key} ${formatRanges(e.value)}',
  ];
}

/// 복음서 짧은 이름 (성경 순서)
const Map<String, String> _gospelShortNames = {
  'MAT': '마태',
  'MRK': '마가',
  'LUK': '누가',
  'JHN': '요한',
};

/// "LUK,MAT,MRK" 같은 코드 목록을 성경 순서로 정렬해 "마태 · 마가 · 누가"로 바꿉니다.
String formatGospelList(String? codes) {
  if (codes == null || codes.isEmpty) return '';
  final set = codes.split(',').toSet();
  return [
    for (final e in _gospelShortNames.entries)
      if (set.contains(e.key)) e.value,
  ].join(' · ');
}

/// 구절 위치 하나를 "마태복음 8:23-27" 형태의 글자로 바꿉니다.
/// 장이 넘어가면 "8:23-9:2", 한 절이면 "13:33"처럼 표시합니다.
String formatRef(Map<String, Object?> r) => formatRefs([r]);

/// 같은 책의 구절 위치 여러 개를 한 줄로 묶습니다.
/// 예: "마가복음 11:12-14, 20-25", "누가복음 9:23-27, 14:27"
/// [short]이면 복음서는 짧은 이름을 씁니다. (예: "마태 1:22-23")
String formatRefs(List<Map<String, Object?>> refs, {bool short = false}) {
  final code = refs.first['book'] as String;
  final book = short
      ? (_gospelShortNames[code] ?? bookName(code))
      : bookName(code);
  return '$book ${formatRanges(refs)}';
}

/// 책 이름 없이 장:절 범위만 (대조표 칸용)
/// 예: "11:12-14, 20-25", "8:34-9:1", "13:33"
String formatRanges(List<Map<String, Object?>> refs) {
  final parts = <String>[];
  Object? lastChapter;

  for (final r in refs) {
    final ch = r['chapter'];
    final chEnd = r['chapter_end'] ?? ch;
    final vs = r['verse_start'];
    final ve = r['verse_end'];

    // 앞 범위와 같은 장에서 시작하면 장 번호를 생략
    final start = ch == lastChapter ? '$vs' : '$ch:$vs';
    final String range;
    if (ch != chEnd) {
      range = '$start-$chEnd:$ve';
    } else if (vs == ve) {
      range = start;
    } else {
      range = '$start-$ve';
    }
    parts.add(range);
    lastChapter = chEnd;
  }
  return parts.join(', ');
}

/// 묶음의 구절 위치 전체를 한 줄로 요약합니다. (책 순서는 적힌 순서대로)
/// 예: "마태 1:22-23 · 이사야 7:14", "마태 5:31, 19:7 · 마가 10:4 · 신명기 24:1"
String formatRefsSummary(List<Map<String, Object?>> refs) {
  final byBook = <String, List<Map<String, Object?>>>{};
  for (final r in refs) {
    byBook.putIfAbsent(r['book'] as String, () => []).add(r);
  }
  return [
    for (final list in byBook.values) formatRefs(list, short: true),
  ].join(' · ');
}

/// 장·절 없이 책 이름만 요약합니다. (잠긴 항목: 어느 책인지만 보여 주고 구절은 숨김)
/// 예: "마태 · 이사야", "로마서 · 갈라디아서 · 하박국"
String formatBooksSummary(List<Map<String, Object?>> refs) {
  final codes = <String>{for (final r in refs) r['book'] as String};
  return [
    for (final code in codes) _gospelShortNames[code] ?? bookName(code),
  ].join(' · ');
}
