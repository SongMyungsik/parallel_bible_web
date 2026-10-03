import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/bible_text_source.dart';
import '../data/ref_format.dart';
import '../logic/word_matcher.dart';
import '../state/app_navigation.dart';
import '../state/app_settings.dart';
import '../state/parallel_state.dart';
import '../ui/gospel_colors.dart';

/// 사건 하나를 복음서별 칸으로 나란히 보여주는 화면.
/// 넓은 화면은 칸을 나란히(칸당 폭 240 이상일 때), 좁은 화면(폰)은 탭으로 전환합니다.
/// 여러 복음서에 같이 나오는 표현은 색으로 표시합니다. (위쪽 스위치로 켜고 끔)
///
/// 한 복음서에 참조가 여러 개면 한 칸에 모읍니다.
///  - 나뉜 본문(예: 막 11:12-14, 20-25)은 이어서 보여 주고 사이에 "⋯"을 넣습니다.
///  - 반복 말씀(doublet)은 본문 아래에 "다른 곳의 같은 말씀"으로 따로 보여 줍니다.
class ParallelComparePage extends StatefulWidget {
  const ParallelComparePage({
    super.key,
    required this.groupId,
    required this.title,
    this.quotation = false,
  });

  final int groupId;
  final String title;

  /// 구약 인용 화면이면 true: 신약과 구약 사이의 같은 표현만 칠합니다.
  /// (신약 본문끼리 같은 표현은 복음서 병행 화면에서 볼 수 있으므로)
  final bool quotation;

  @override
  State<ParallelComparePage> createState() => _ParallelComparePageState();
}

/// 참조 하나: 구절 위치 + 본문들 + 절별 단어(공통 표시 정보)
class _Section {
  const _Section(this.ref, this.verses, this.words);

  final Map<String, Object?> ref;
  final List<VerseText> verses;
  final List<List<MatchedWord>> words; // words[절 순서][단어 순서]
}

/// 칸 하나 = 복음서 하나
class _ColumnData {
  _ColumnData(this.book);

  final String book;
  final List<_Section> main = []; // 본문 (나뉜 본문이면 여러 개)
  final List<_Section> doublets = []; // 다른 곳의 같은 말씀
}

/// 공통 표현에 칠할 색 (색은 ui/gospel_colors.dart에서 정합니다)
Color? _highlightColor(int sharedBy) => gospelCountColor(sharedBy);

class _ParallelComparePageState extends State<ParallelComparePage> {
  late final Future<List<_ColumnData>> _future;
  bool _highlight = true;

  @override
  void initState() {
    super.initState();
    _future = _load();

    // 홈 화면 "이어 보기"를 위해 마지막으로 본 대조 화면을 기록
    // (화면을 그리는 중에 다른 화면이 바뀌지 않게 그리기가 끝난 뒤에)
    final settings = context.read<AppSettings>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settings.setRecentView(
        quotation: widget.quotation,
        id: widget.groupId,
        title: widget.title,
      );
    });
  }

  /// 같은 표현을 비교할 때 쓰는 이름. 이름이 같은 본문끼리는 비교하지 않습니다.
  /// 병행 화면: 책마다 (마태·마가·누가끼리 비교)
  /// 인용 화면: 신약/구약 두 편으로만 나눔 (신약 ↔ 구약만 비교)
  String _matchKey(String book) {
    if (!widget.quotation) return book;
    return isOldTestament(book) ? 'OT' : 'NT';
  }

  Future<List<_ColumnData>> _load() async {
    final state = context.read<ParallelState>();
    final source = context.read<BibleTextSource>();

    final refs = await state.getRefs(widget.groupId);

    // 모든 참조의 본문을 동시에 불러옵니다.
    final versesPerRef = await Future.wait(
      refs.map(
        (r) => source.getVerses(
          book: r['book'] as String,
          chapter: r['chapter'] as int,
          verseStart: r['verse_start'] as int,
          chapterEnd: r['chapter_end'] as int,
          verseEnd: r['verse_end'] as int,
        ),
      ),
    );

    // 참조끼리 비교해서 같은 표현을 찾습니다. (같은 복음서끼리는 비교하지 않음)
    final analysis = WordMatcher.analyze(
      [
        for (final verses in versesPerRef) [for (final v in verses) v.text],
      ],
      [for (final r in refs) _matchKey(r['book'] as String)],
    );

    // 복음서별 칸으로 묶기 (JSON에 적힌 순서대로)
    final columns = <String, _ColumnData>{};
    for (var i = 0; i < refs.length; i++) {
      final book = refs[i]['book'] as String;
      final column = columns.putIfAbsent(book, () => _ColumnData(book));
      final section = _Section(refs[i], versesPerRef[i], analysis[i]);
      if (refs[i]['doublet'] == 1) {
        column.doublets.add(section);
      } else {
        column.main.add(section);
      }
    }
    return columns.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<_ColumnData>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('불러오지 못했습니다: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final columns = snap.data!;
          return Column(
            children: [
              _HighlightBar(
                on: _highlight,
                maxLevel: columns.length,
                quotation: widget.quotation,
                onChanged: (value) => setState(() => _highlight = value),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 칸 하나에 폭 240 이상을 줄 수 있으면 나란히 (3칸 720, 4칸 960)
                    final wide = constraints.maxWidth >= columns.length * 240;
                    return wide
                        ? _WideLayout(columns, _highlight)
                        : _NarrowLayout(columns, _highlight);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 본문 위 한 줄: "같은 표현 표시" 스위치 + (켜져 있을 때) 색 설명
class _HighlightBar extends StatelessWidget {
  const _HighlightBar({
    required this.on,
    required this.maxLevel,
    this.quotation = false,
    required this.onChanged,
  });

  final bool on;

  /// 이 사건에 나오는 복음서 수. 이보다 큰 색 설명은 보여 주지 않습니다.
  final int maxLevel;

  /// 구약 인용 화면이면 색 설명을 "신약·구약 같은 표현" 하나만 보여 줌
  final bool quotation;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('같은 표현 표시', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              Switch(value: on, onChanged: onChanged),
            ],
          ),
          if (on && quotation) const GospelCountLegend(2, label: '신약·구약 같은 표현'),
          if (on && !quotation)
            for (var level = maxLevel.clamp(2, 4); level >= 2; level--)
              GospelCountLegend(level),
        ],
      ),
    );
  }
}

/// 넓은 화면: 칸을 나란히
class _WideLayout extends StatelessWidget {
  const _WideLayout(this.columns, this.highlight);

  final List<_ColumnData> columns;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < columns.length; i++) {
      if (i > 0) children.add(const VerticalDivider(width: 1));
      children.add(Expanded(child: _PassageColumn(columns[i], highlight)));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// 좁은 화면: 탭으로 전환
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout(this.columns, this.highlight);

  final List<_ColumnData> columns;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: columns.length,
      child: Column(
        children: [
          TabBar(tabs: [for (final c in columns) Tab(text: bookName(c.book))]),
          Expanded(
            child: TabBarView(
              children: [for (final c in columns) _PassageColumn(c, highlight)],
            ),
          ),
        ],
      ),
    );
  }
}

/// 칸 안에 차례로 그릴 항목 하나: 절 / 나뉜 본문 사이 "⋯" / 반복 말씀 제목
class _Item {
  const _Item.verse(this.section, this.index) : doubletTitle = false;
  const _Item.gap() : section = null, index = 0, doubletTitle = false;
  const _Item.doubletTitle(this.section) : index = 0, doubletTitle = true;

  final _Section? section;
  final int index; // 절 순서
  final bool doubletTitle;
}

/// 복음서 한 칸: 위에 "마태복음 8:23-27", 아래에 절별 본문
class _PassageColumn extends StatelessWidget {
  _PassageColumn(this.data, this.highlight) : items = _buildItems(data);

  final _ColumnData data;
  final bool highlight;
  final List<_Item> items;

  static List<_Item> _buildItems(_ColumnData data) {
    final items = <_Item>[];
    for (var s = 0; s < data.main.length; s++) {
      if (s > 0) items.add(const _Item.gap());
      final section = data.main[s];
      for (var i = 0; i < section.verses.length; i++) {
        items.add(_Item.verse(section, i));
      }
    }
    for (final section in data.doublets) {
      items.add(_Item.doubletTitle(section));
      for (var i = 0; i < section.verses.length; i++) {
        items.add(_Item.verse(section, i));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 칸 머리: 구절 위치 + 성경에서 보기 (눌러도 같은 동작)
        InkWell(
          onTap: () => _openInBible(context, data.main),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatRefs([for (final s in data.main) s.ref]),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _bibleButton(context, data.main),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              if (item.section == null) return _gap(theme);
              if (item.doubletTitle) {
                return _doubletTitle(context, theme, item.section!);
              }
              return _verse(theme, item.section!, item.index);
            },
          ),
        ),
      ],
    );
  }

  /// 나뉜 본문 사이: 건너뛴 부분이 있다는 표시
  Widget _gap(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '⋯',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// 성경 탭에서 이 본문이 있는 장을 열고 범위를 강조합니다.
  /// (나뉜 본문이면 첫 범위의 장을 열고, 같은 장의 다른 범위도 함께 강조)
  static void _openInBible(BuildContext context, List<_Section> sections) {
    final refs = [for (final s in sections) s.ref];
    final first = refs.first;
    context.read<AppNavigation>().openBible(
      BibleTarget(first['book'] as String, first['chapter'] as int, refs),
    );
  }

  static Widget _bibleButton(BuildContext context, List<_Section> sections) {
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined, size: 20),
      tooltip: '성경에서 앞뒤 문맥 보기',
      visualDensity: VisualDensity.compact,
      onPressed: () => _openInBible(context, sections),
    );
  }

  /// 반복 말씀 앞 제목: "다른 곳의 같은 말씀 · 누가복음 14:27"
  Widget _doubletTitle(
    BuildContext context,
    ThemeData theme,
    _Section section,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '다른 곳의 같은 말씀 · ${formatRef(section.ref)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          _bibleButton(context, [section]),
        ],
      ),
    );
  }

  Widget _verse(ThemeData theme, _Section section, int i) {
    final v = section.verses[i];
    // 장이 넘어가는 구절이면 절 번호 앞에 장도 붙임 (예: 8:23)
    final spansChapters = section.ref['chapter'] != section.ref['chapter_end'];
    final label = spansChapters ? '${v.chapter}:${v.verse}' : '${v.verse}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소제목이 있는 절이면 본문 위에 작게 표시
          if (v.heading != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                v.heading!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                ..._wordSpans(section.words[i]),
              ],
            ),
            // 본문은 굵게 (성경 화면과 같게)
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 단어들을 색칠한 글자 조각으로 바꿉니다.
  List<InlineSpan> _wordSpans(List<MatchedWord> words) {
    final spans = <InlineSpan>[];

    for (var k = 0; k < words.length; k++) {
      final w = words[k];
      final bg = highlight ? _highlightColor(w.sharedBy) : null;

      spans.add(
        TextSpan(
          text: w.text,
          style: bg == null ? null : TextStyle(backgroundColor: bg),
        ),
      );

      if (k < words.length - 1) {
        // 이웃 단어도 같은 색이면 사이 띄어쓰기도 칠해서 한 덩어리로 보이게 함
        final joined = bg != null && words[k + 1].sharedBy == w.sharedBy;
        spans.add(
          TextSpan(
            text: ' ',
            style: joined ? TextStyle(backgroundColor: bg) : null,
          ),
        );
      }
    }
    return spans;
  }
}
