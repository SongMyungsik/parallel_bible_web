import 'package:flutter/material.dart';

/// 소제목으로 묶인 목록의 한 줄: 소제목이거나 항목이거나
class GroupedEntry<T> {
  const GroupedEntry.header(this.header, this.count) : item = null;
  const GroupedEntry.item(T this.item) : header = null, count = 0;

  final String? header;
  final int count; // 소제목 아래 항목 수
  final T? item;

  bool get isHeader => header != null;
}

/// 이미 정렬된 항목들을 [headerOf]가 바뀔 때마다 소제목을 넣어 한 줄로 폅니다.
List<GroupedEntry<T>> groupEntries<T>(
  List<T> items,
  String Function(T) headerOf,
) {
  final result = <GroupedEntry<T>>[];
  var i = 0;
  while (i < items.length) {
    final header = headerOf(items[i]);
    var j = i;
    while (j < items.length && headerOf(items[j]) == header) {
      j++;
    }
    result.add(GroupedEntry.header(header, j - i));
    for (var k = i; k < j; k++) {
      result.add(GroupedEntry.item(items[k]));
    }
    i = j;
  }
  return result;
}

/// 검색어가 [texts] 중 하나에 들어 있으면 true. (띄어쓰기·대소문자 무시)
bool matchesQuery(String query, List<String?> texts) {
  final q = _simplify(query);
  if (q.isEmpty) return true;
  return texts.any((t) => t != null && _simplify(t).contains(q));
}

String _simplify(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

/// 목록 위의 검색창
class ListSearchField extends StatelessWidget {
  const ListSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        // 글자가 있으면 지우기 버튼
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: '지우기',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// 목록 안의 소제목 줄 (예: "갈릴리 사역  71")
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, this.count, {super.key});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 검색 결과가 없을 때
class EmptyResult extends StatelessWidget {
  const EmptyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          '찾는 결과가 없습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
