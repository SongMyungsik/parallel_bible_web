import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ref_format.dart';
import '../data/sections.dart';
import '../state/parallel_state.dart';
import '../state/purchase_state.dart';
import '../ui/grouped_list.dart';
import '../ui/synopsis_table.dart';
import '../ui/unlock_sheet.dart';
import 'parallel_compare_page.dart';

/// 신약의 구약 인용 목록.
///  - 신약 순서: 복음서 인용은 예수님의 생애 단계별, 사도행전부터는 신약 책별 소제목
///  - 구약 순서: 인용된 구약 책별 소제목 (창세기 → 말라기)
///  - 위쪽 검색창: 제목·구절로 찾기 (예: "이사야", "시편 22")
///  - [목록 | 표] 전환: 표는 "인용 | 신약 | 구약" 대조표 (책 이름은 약자)
/// 제목 아래에 "마태 1:22-23 · 이사야 7:14"처럼 인용한 곳과 인용된 곳을 보여 줍니다.
class QuotationListPage extends StatefulWidget {
  const QuotationListPage({super.key});

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  final _search = TextEditingController();
  String _query = '';

  /// true = 구약 순서, false = 신약 순서
  bool _byOldTestament = false;

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
      for (final g in state.quotations)
        // 잠긴 인용은 제목과 책 이름으로만 찾음 (구절로는 찾지 못하게)
        if (matchesQuery(_query, [
          g['title'] as String,
          isOpen(g)
              ? state.quotationSummaries[g['id']]
              : formatBooksSummary(state.quotationRefs[g['id']] ?? const []),
        ]))
          g,
    ];
    // 표에는 장·절이 모두 나오므로, 표 보기에서는 열린 인용만 보여 줌 (목록 보기는 자물쇠로 표시)
    var items = _table ? found.where(isOpen).toList() : found;
    final hidden = found.length - items.length;

    final List<GroupedEntry<Map<String, Object?>>> entries;
    if (_byOldTestament) {
      // 인용된 첫 구약 본문의 성경 순서로 정렬, 책마다 소제목
      OtPosition? ot(Map<String, Object?> g) => state.quotationOt[g['id']];
      items = [...items]
        ..sort((a, b) {
          final x = ot(a), y = ot(b);
          final c = (x?.bookIndex ?? 99).compareTo(y?.bookIndex ?? 99);
          if (c != 0) return c;
          return (x?.position ?? 0).compareTo(y?.position ?? 0);
        });
      entries = groupEntries(items, (g) {
        final o = ot(g);
        return o == null ? '기타' : bookName(o.book);
      });
    } else {
      entries = groupEntries(items, (g) => sectionName(g['section'] as int));
    }

    return Scaffold(
      appBar: AppBar(title: Text('구약 인용 (${state.quotations.length})')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ListSearchField(
                    controller: _search,
                    hint: '제목·구절 찾기 (예: 이사야, 시편 22)',
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      // 정렬: 신약 순서 / 구약 순서
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('신약 순서')),
                            ButtonSegment(value: true, label: Text('구약 순서')),
                          ],
                          selected: {_byOldTestament},
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          onSelectionChanged: (s) =>
                              setState(() => _byOldTestament = s.first),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 보기: 목록 / 표 (좁은 폭이라 아이콘만)
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.view_list),
                            tooltip: '목록으로 보기',
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.table_chart_outlined),
                            tooltip: '표로 보기',
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
                    ],
                  ),
                ),
                const UnlockBanner(),
                const Divider(height: 1),
                if (_table) const QuotationHeaderRow(),
                Expanded(
                  child: entries.isEmpty && hidden == 0
                      ? const EmptyResult()
                      : ListView.builder(
                          // 표에서 감춘 줄이 있으면 맨 아래에 안내 한 줄
                          itemCount: entries.length + (hidden > 0 ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == entries.length) {
                              return HiddenRowsNote(count: hidden, unit: '곳');
                            }
                            final e = entries[i];
                            if (e.isHeader) {
                              return SectionHeader(e.header!, e.count);
                            }
                            final g = e.item!;
                            final locked = !isOpen(g);
                            return _table
                                ? _row(context, state, g, locked)
                                : _tile(context, theme, state, g, locked);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _openCompare(BuildContext context, int id, String title) {
    // 잠긴 인용이면 대조 화면 대신 "전체 열기" 안내
    if (!ensureOpen(context, id)) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ParallelComparePage(groupId: id, title: title, quotation: true),
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
    return QuotationRow(
      order: g['sort_order'] as int,
      title: title,
      refs: state.quotationRefs[id] ?? const [],
      locked: locked,
      onTap: () => _openCompare(context, id, title),
    );
  }

  Widget _tile(
    BuildContext context,
    ThemeData theme,
    ParallelState state,
    Map<String, Object?> g,
    bool locked,
  ) {
    final id = g['id'] as int;
    final title = g['title'] as String;
    return Column(
      children: [
        ListTile(
          // 번호는 신약 순서 (정렬을 바꾸거나 검색해도 그대로)
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: Text('${g['sort_order']}'),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // 어디서 어디를 인용했는지 작은 글씨로.
          // 잠긴 인용은 구절을 숨기고 책 이름만 (예: "로마서 · 하박국")
          subtitle: Text(
            locked
                ? formatBooksSummary(state.quotationRefs[id] ?? const [])
                : state.quotationSummaries[id] ?? '',
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
