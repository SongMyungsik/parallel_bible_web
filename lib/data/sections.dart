import 'ref_format.dart';

/// 목록을 묶는 "예수님의 생애 단계".
/// JSON의 "section" 번호와 같습니다. (번호는 tool/assign_order.py가 붙임)
const Map<int, String> lifeSections = {
  1: '탄생과 준비',
  2: '갈릴리 사역',
  3: '예루살렘으로 가는 길',
  4: '예루살렘 사역',
  5: '수난',
  6: '부활',
};

/// 복음서 밖(사도행전~요한계시록)의 구약 인용은 신약 책별로 묶습니다.
/// 번호 = 100 + 신약에서 몇 번째 책인지 (사도행전 105, 로마서 106, … 요한계시록 127)
const int bookSectionBase = 100;

String sectionName(int section) {
  final life = lifeSections[section];
  if (life != null) return life;
  final nt = bookNames.keys.skip(39).toList(); // 신약 27권
  final i = section - bookSectionBase - 1;
  if (i >= 0 && i < nt.length) return bookName(nt[i]);
  return '기타';
}
