import 'package:flutter/material.dart';

/// "몇 복음서에 나오는가"를 나타내는 색. 목록 화면과 대조 화면이 함께 씁니다.
/// 네 복음서 = 보라, 세 복음서 = 초록, 두 복음서 = 파랑, 한 곳뿐 = 색 없음(null).
///
/// [alpha]는 투명도입니다. 글자 배경은 옅게(0.22), 목록의 동그라미는 조금 진하게 씁니다.
Color? gospelCountColor(int count, {double alpha = 0.22}) {
  if (count >= 4) return Colors.purple.withValues(alpha: alpha);
  if (count == 3) return Colors.green.withValues(alpha: alpha);
  if (count == 2) return Colors.blue.withValues(alpha: alpha);
  return null;
}

/// 같은 뜻의 "글자색" (대조표의 구절 글자). 라이트는 진하게, 다크는 밝게.
Color gospelCountTextColor(int count, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  if (count >= 4) return dark ? Colors.purple.shade200 : Colors.purple.shade700;
  if (count == 3) return dark ? Colors.green.shade300 : Colors.green.shade800;
  return dark ? Colors.blue.shade300 : Colors.blue.shade800;
}

/// 색 설명에 쓰는 이름: 4 → "네 복음서 공통"
String gospelCountLabel(int count) {
  const names = {4: '네', 3: '세', 2: '두'};
  return '${names[count]} 복음서 공통';
}

/// 색 설명 한 칸: 작은 색 네모 + 이름
class GospelCountLegend extends StatelessWidget {
  const GospelCountLegend(
    this.count, {
    super.key,
    this.alpha = 0.22,
    this.label,
  });

  final int count;
  final double alpha;

  /// 설명 글자를 바꾸고 싶을 때 (없으면 "세 복음서 공통" 같은 기본 이름)
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: gospelCountColor(count, alpha: alpha),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label ?? gospelCountLabel(count),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
