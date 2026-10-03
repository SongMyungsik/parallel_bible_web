import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ref_format.dart';
import '../data/sections.dart';
import '../state/parallel_state.dart';
import '../state/purchase_state.dart';
import '../ui/gospel_colors.dart';
import '../ui/grouped_list.dart';
import '../ui/synopsis_table.dart';
import '../ui/unlock_sheet.dart';
import 'parallel_compare_page.dart';

/// 복음서 병행 사건 목록.
///  - 예수님의 생애 단계(탄생과 준비 → … → 부활)별 소제목으로 묶어 순서대로 보여 줌
///  - 위쪽 검색창: 제목·복음서 이름·구절로 찾기 (예: "세례", "누가 9")
///  - 번호 동그라미 색 = 몇 복음서에 나오는지, 제목 아래 = 어떤 복음서인지
///  - [목록 | 표] 전환: 표는 "사건 | 마가 | 마태 | 누가 | 요한" 대조표
class ParallelListPage extends StatefulWidget {
  const ParallelListPage({super.key});

  @override
  State<ParallelListPage> createState() => _ParallelListPageState();
}

class _ParallelListPageState extends State<ParallelListPage> {
  /// 번호 동그라미 색의 진하기 (본문 글자 배경보다 조금 진하게)
  static const double _avatarAlpha = 0.6;

  final _search = TextEditingController();
  String _query = '';

  /// true = 대조표로 보기
  bool _table = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ParallelState>();
    // 구매하면 자물쇠가 바로 사라지도록 구매 상태도 지켜봄
    final purchase = context.watch<PurchaseState>();
    final theme = Theme.of(context);

    bool isOpen(Map<String, Object?> g) =>
        purchase.canOpen(id: g['id'] as int, section: g['section'] as int);

    final found = [
      for (final g in state.groups)
        // 잠긴 사건은 제목과 복음서 이름으로만 찾음 (구절로는 찾지 못하게)
        if (matchesQuery(_query, [
          g['title'] as String,
          formatGospelList(g['gospels'] as String?),
          if (isOpen(g)) state.parallelSummaries[g['id']],
        ]))
          g,
    ];
    // 표에는 장·절이 모두 나오므로, 표 보기에서는 열린 사건만 보여 줌 (목록 보기는 자물쇠로 표시)
    final items = _table ? found.where(isOpen).toList() : found;
    final hidden = found.length - items.length;
    final entries = groupEntries(
      items,
      (g) => sectionName(g['section'] as int),
    );

    return Scaffold(
      appBar: AppBar(title: Text('복음서 병행 (${state.groups.length})')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ListSearchField(
                    controller: _search,
                    hint: '제목·구절 찾기 (예: 세례, 누가 9)',
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                // 목록/표 전환 + 색 설명
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.view_list),
                            label: Text('목록'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.table_chart_outlined),
                            label: Text('표'),
                          ),
                        ],
                        selected: {_table},
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (s) =>
                            setState(() => _table = s.first),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            for (final count in [4, 3, 2])
                              GospelCountLegend(
                                count,
                                alpha: _avatarAlpha,
                                label: '$count복음서',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const UnlockBanner(),
                const Divider(height: 1),
                if (_table) const SynopsisHeaderRow(),
                Expanded(
                  child: entries.isEmpty && hidden == 0
                      ? const EmptyResult()
                      : ListView.builder(
                          // 표에서 감춘 줄이 있으면 맨 아래에 안내 한 줄
                          itemCount: entries.length + (hidden > 0 ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == entries.length) {
                              return HiddenRowsNote(
                                count: hidden,
                                unit: '개 사건',
                              );
                            }
                            final e = entries[i];
                            if (e.isHeader) {
                              return SectionHeader(e.header!, e.count);
                            }
                            final g = e.item!;
                            final locked = !isOpen(g);
                            return _table
                                ? _row(context, state, g, locked)
                                : _tile(context, theme, g, locked);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _openCompare(BuildContext context, int id, String title) {
    // 잠긴 사건이면 대조 화면 대신 "전체 열기" 안내
    if (!ensureOpen(context, id)) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParallelComparePage(groupId: id, title: title),
      ),
    );
  }

  /// 대조표 한 줄
  Widget _row(
    BuildContext context,
    ParallelState state,
    Map<String, Object?> g,
    bool locked,
  ) {
    final id = g['id'] as int;
    final title = g['title'] as String;
    return SynopsisRow(
      order: g['sort_order'] as int,
      title: title,
      gospelCount: g['gospel_count'] as int,
      refs: state.parallelRefs[id] ?? const [],
      locked: locked,
      onTap: () => _openCompare(context, id, title),
    );
  }

  Widget _tile(
    BuildContext context,
    ThemeData theme,
    Map<String, Object?> g,
    bool locked,
  ) {
    final id = g['id'] as int;
    final title = g['title'] as String;
    final count = g['gospel_count'] as int;
    return Column(
      children: [
        ListTile(
          // 몇 복음서에 나오는 사건인지 동그라미 색으로 구분
          // 번호는 생애 순서 (검색해도 그대로)
          leading: CircleAvatar(
            backgroundColor: gospelCountColor(count, alpha: _avatarAlpha),
            // 라이트·다크 모드 모두 읽히는 글자색
            foregroundColor: theme.colorScheme.onSurface,
            child: Text('${g['sort_order']}'),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // 어떤 복음서에 나오는지 작은 글씨로 (예: 마태 · 마가 · 누가)
          subtitle: Text(
            formatGospelList(g['gospels'] as String?),
            style: theme.textTheme.bodySmall,
          ),
          trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
          onTap: () => _openCompare(context, id, title),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
