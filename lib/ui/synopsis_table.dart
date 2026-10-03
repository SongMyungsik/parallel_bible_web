import 'package:flutter/material.dart';

import '../data/ref_format.dart';
import 'gospel_colors.dart';

/// 대조표의 열: 사건 | 마가 | 마태 | 누가 | 요한 (마가복음을 앞에 두는 일반적인 대조표 순서)
const List<String> synopsisColumns = ['MRK', 'MAT', 'LUK', 'JHN'];

/// 칸 너비 비율: 사건 제목 칸을 넓게
const int _titleFlex = 32;
const int _refFlex = 17;

/// 표 맨 위의 열 이름 줄
class SynopsisHeaderRow extends StatelessWidget {
  const SynopsisHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: _titleFlex,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('사건', style: style),
            ),
          ),
          for (final code in synopsisColumns)
            Expanded(
              flex: _refFlex,
              child: Text(
                bookName(code).replaceAll('복음', ''),
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// 대조표 한 줄: 번호·사건 제목 + 복음서별 장:절
class SynopsisRow extends StatelessWidget {
  const SynopsisRow({
    super.key,
    required this.order,
    required this.title,
    required this.gospelCount,
    required this.refs,
    required this.onTap,
    this.locked = false,
  });

  final int order;
  final String title;
  final int gospelCount;
  final List<Map<String, Object?>> refs;
  final VoidCallback onTap;

  /// 전체 열기를 구매해야 열리는 줄이면 제목 뒤에 자물쇠 표시
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refColor = gospelCountTextColor(gospelCount, theme.brightness);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            // 왼쪽 띠 = 몇 복음서에 나오는지 (목록의 동그라미와 같은 색)
            left: BorderSide(
              color:
                  gospelCountColor(gospelCount, alpha: 0.8) ??
                  Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _titleFlex,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$order ',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      TextSpan(text: title),
                      if (locked)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            for (final code in synopsisColumns)
              Expanded(flex: _refFlex, child: _cell(theme, code, refColor)),
          ],
        ),
      ),
    );
  }

  /// 한 복음서 칸: 본문 범위 + (반복 말씀은 괄호로 한 줄 더)
  Widget _cell(ThemeData theme, String code, Color color) {
    final main = [
      for (final r in refs)
        if (r['book'] == code && r['doublet'] != 1) r,
    ];
    final doublets = [
      for (final r in refs)
        if (r['book'] == code && r['doublet'] == 1) r,
    ];
    if (main.isEmpty && doublets.isEmpty) return const SizedBox.shrink();

    final style = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
      height: 1.4,
    );
    return Column(
      children: [
        if (main.isNotEmpty)
          Text(formatRanges(main), style: style, textAlign: TextAlign.center),
        if (doublets.isNotEmpty)
          Text(
            '(${formatRanges(doublets)})',
            style: style?.copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// 구약 인용 대조표: 인용 | 신약 | 구약
// ---------------------------------------------------------------

const int _quoteTitleFlex = 36;
const int _quoteRefFlex = 32;

/// 구약 인용 표 맨 위의 열 이름 줄
class QuotationHeaderRow extends StatelessWidget {
  const QuotationHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: _quoteTitleFlex,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('인용', style: style),
            ),
          ),
          Expanded(
            flex: _quoteRefFlex,
            child: Text('신약', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: _quoteRefFlex,
            child: Text('구약', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// 구약 인용 표 한 줄: 번호·제목 + 신약 구절들 + 구약 구절들 (책마다 한 줄, 약자로)
class QuotationRow extends StatelessWidget {
  const QuotationRow({
    super.key,
    required this.order,
    required this.title,
    required this.refs,
    required this.onTap,
    this.locked = false,
  });

  final int order;
  final String title;
  final List<Map<String, Object?>> refs;
  final VoidCallback onTap;

  /// 전체 열기를 구매해야 열리는 줄이면 제목 뒤에 자물쇠 표시
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nt = [
      for (final r in refs)
        if (!isOldTestament(r['book'] as String)) r,
    ];
    final ot = [
      for (final r in refs)
        if (isOldTestament(r['book'] as String)) r,
    ];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _quoteTitleFlex,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$order ',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      TextSpan(text: title),
                      if (locked)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 신약은 파랑 계열, 구약은 갈색 계열 글자
            Expanded(
              flex: _quoteRefFlex,
              child: _lines(theme, formatAbbrLines(nt), _ntColor(theme)),
            ),
            Expanded(
              flex: _quoteRefFlex,
              child: _lines(theme, formatAbbrLines(ot), _otColor(theme)),
            ),
          ],
        ),
      ),
    );
  }

  static Color _ntColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? Colors.lightBlue.shade200
      : Colors.blue.shade800;

  static Color _otColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? Colors.orange.shade200
      : Colors.brown.shade600;

  Widget _lines(ThemeData theme, List<String> lines, Color color) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
      height: 1.4,
    );
    return Column(
      children: [
        for (final line in lines)
          Text(line, style: style, textAlign: TextAlign.center),
      ],
    );
  }
}
