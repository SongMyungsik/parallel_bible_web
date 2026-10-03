import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/bible_text_source.dart';
import '../data/ref_format.dart';
import '../state/app_navigation.dart';
import '../state/app_settings.dart';
import '../state/parallel_state.dart';
import '../state/purchase_state.dart';
import '../ui/gospel_colors.dart';
import '../ui/unlock_sheet.dart';
import 'parallel_compare_page.dart';

/// 성경 읽기 화면.
///  - 위쪽: 구약/신약 버튼, 책 이름·장 드롭다운
///  - 가운데: 그 장의 본문
///  - 아래 좌우: 이전 장 / 다음 장 버튼 (책 끝에서는 앞뒤 책으로 넘어감)
/// 마지막으로 본 책·장은 설정에 저장되어 다음에 그 자리에서 시작합니다.
///
/// 병행·인용과 연결:
///  - 병행·인용 범위가 시작하는 절 위에 칩을 붙이고, 누르면 대조 화면을 엽니다.
///  - 대조 화면에서 "성경에서 보기"를 누르면 이 화면이 그 장을 열고 범위를 강조합니다.
class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

/// 절 위에 붙는 병행·인용 표시 하나
class _Mark {
  const _Mark(this.groupId, this.title, this.quotation, this.gospelCount);

  final int groupId;
  final String title;
  final bool quotation; // true = 구약 인용, false = 복음서 병행
  final int gospelCount; // 병행이면 몇 복음서인지 (칩 색)
}

/// 한 장의 본문 + 절 번호별 표시
class _ChapterData {
  const _ChapterData(this.verses, this.marks);

  final List<VerseText> verses;
  final Map<int, List<_Mark>> marks;
}

class _BiblePageState extends State<BiblePage> {
  /// 책 코드 → 장 수 (본문이 있는 책만, 성경 순서)
  Map<String, int> _chapters = {};
  late String _book;
  late int _chapter;
  Future<_ChapterData>? _data;

  /// 대조 화면에서 넘어왔을 때 강조할 범위들 (직접 장을 바꾸면 지워짐)
  List<Map<String, Object?>> _highlight = const [];

  /// 강조한 첫 절로 스크롤하기 위한 표식
  final GlobalKey _firstHighlightKey = GlobalKey();
  bool _scrollPending = false;

  late final AppNavigation _navigation;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _book = settings.bibleBook;
    _chapter = settings.bibleChapter;
    _navigation = context.read<AppNavigation>();
    _navigation.addListener(_onNavigation);
    _loadChapterCounts();
  }

  @override
  void dispose() {
    _navigation.removeListener(_onNavigation);
    super.dispose();
  }

  /// 대조 화면에서 "성경에서 보기" 요청이 왔을 때
  void _onNavigation() {
    final target = _navigation.takeBibleTarget();
    if (target == null) return;
    if (_chapters.isEmpty) {
      // 아직 준비 중이면 위치만 기억해 두고, 준비가 끝나면 그 장을 엶
      _book = target.book;
      _chapter = target.chapter;
      _highlight = target.highlight;
      return;
    }
    _go(target.book, target.chapter, highlight: target.highlight);
  }

  Future<void> _loadChapterCounts() async {
    final counts = await context.read<BibleTextSource>().chapterCounts();
    if (!mounted) return;
    setState(() {
      // bookNames 순서(창세기 → 요한계시록)로 정렬
      _chapters = {
        for (final code in bookNames.keys)
          if (counts.containsKey(code)) code: counts[code]!,
      };
      // 저장된 위치가 이상하면 첫 책 1장으로
      if (!_chapters.containsKey(_book) || _chapter > _chapters[_book]!) {
        _book = _chapters.keys.first;
        _chapter = 1;
      }
    });
    _go(_book, _chapter, highlight: _highlight);
  }

  /// 책·장을 바꾸고 본문을 불러옵니다.
  void _go(
    String book,
    int chapter, {
    List<Map<String, Object?>> highlight = const [],
  }) {
    setState(() {
      _book = book;
      _chapter = chapter;
      _highlight = highlight;
      _scrollPending = highlight.isNotEmpty;
      _data = _loadChapter(book, chapter);
    });
    context.read<AppSettings>().setBiblePosition(book, chapter);
  }

  Future<_ChapterData> _loadChapter(String book, int chapter) async {
    final versesFuture = context.read<BibleTextSource>().getVerses(
      book: book,
      chapter: chapter,
      verseStart: 1,
      chapterEnd: chapter,
      verseEnd: 999,
    );
    final refs = await context.read<ParallelState>().getRefsInChapter(
      book,
      chapter,
    );

    // 범위가 이 장에서 시작하는 절에 표시 (앞 장에서 이어지면 1절)
    // 같은 묶음이 한 장에 여러 번 걸리면(나뉜 본문 등) 처음 한 번만
    final marks = <int, List<_Mark>>{};
    final seen = <int>{};
    for (final r in refs) {
      final groupId = r['group_id'] as int;
      if (!seen.add(groupId)) continue;
      final verse = r['chapter'] == chapter ? r['verse_start'] as int : 1;
      marks
          .putIfAbsent(verse, () => [])
          .add(
            _Mark(
              groupId,
              r['title'] as String,
              r['collection'] == 'quotation',
              r['gospel_count'] as int,
            ),
          );
    }
    return _ChapterData(await versesFuture, marks);
  }

  bool _isHighlighted(VerseText v) {
    final key = v.chapter * 1000 + v.verse;
    for (final r in _highlight) {
      if (r['book'] != _book) continue;
      final start = (r['chapter'] as int) * 1000 + (r['verse_start'] as int);
      final end = (r['chapter_end'] as int) * 1000 + (r['verse_end'] as int);
      if (key >= start && key <= end) return true;
    }
    return false;
  }

  List<String> get _books => _chapters.keys.toList();

  /// 이전 장 (책의 1장이면 앞 책의 마지막 장). 맨 앞이면 null.
  (String, int)? get _prev {
    if (_chapter > 1) return (_book, _chapter - 1);
    final i = _books.indexOf(_book);
    if (i <= 0) return null;
    final prevBook = _books[i - 1];
    return (prevBook, _chapters[prevBook]!);
  }

  /// 다음 장 (책의 마지막 장이면 다음 책 1장). 맨 끝이면 null.
  (String, int)? get _next {
    if (_chapter < (_chapters[_book] ?? 0)) return (_book, _chapter + 1);
    final i = _books.indexOf(_book);
    if (i < 0 || i >= _books.length - 1) return null;
    return (_books[i + 1], 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 구매하면 칩의 자물쇠가 바로 사라지도록 구매 상태를 지켜봄
    context.watch<PurchaseState>();
    final prev = _prev;
    final next = _next;

    return Scaffold(
      appBar: AppBar(title: const Text('성경')),
      body: _chapters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _controls(theme),
                const Divider(height: 1),
                Expanded(child: _verseList(theme)),
              ],
            ),
      // 좌우 장 이동 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _chapters.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _moveButton(
                    icon: Icons.chevron_left,
                    tooltip: '이전 장',
                    heroTag: 'bible_prev',
                    target: prev,
                  ),
                  _moveButton(
                    icon: Icons.chevron_right,
                    tooltip: '다음 장',
                    heroTag: 'bible_next',
                    target: next,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _moveButton({
    required IconData icon,
    required String tooltip,
    required String heroTag,
    required (String, int)? target,
  }) {
    // 더 갈 곳이 없으면 버튼을 흐리게 하고 눌러도 반응하지 않게 함
    return Opacity(
      opacity: target == null ? 0.3 : 1,
      child: FloatingActionButton.small(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: target == null ? null : () => _go(target.$1, target.$2),
        child: Icon(icon),
      ),
    );
  }

  /// 위쪽 선택 영역: 구약/신약 버튼 + 책·장 드롭다운
  Widget _controls(ThemeData theme) {
    final oldTestament = isOldTestament(_book);
    final booksHere = _books
        .where((b) => isOldTestament(b) == oldTestament)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('구약')),
                ButtonSegment(value: false, label: Text('신약')),
              ],
              selected: {oldTestament},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                if (s.first == oldTestament) return;
                // 구약/신약을 바꾸면 그쪽 첫 책 1장으로
                final first = _books.firstWhere(
                  (b) => isOldTestament(b) == s.first,
                );
                _go(first, 1);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 책 이름 (파스텔 파랑 상자)
              Expanded(
                child: _dropdownBox<String>(
                  color: _bookBoxColor,
                  value: _book,
                  items: [
                    for (final b in booksHere)
                      DropdownMenuItem(value: b, child: Text(bookName(b))),
                  ],
                  onChanged: (b) {
                    if (b != null && b != _book) _go(b, 1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 장 (파스텔 초록 상자)
              SizedBox(
                width: 110,
                child: _dropdownBox<int>(
                  color: _chapterBoxColor,
                  value: _chapter,
                  items: [
                    for (var c = 1; c <= (_chapters[_book] ?? 1); c++)
                      DropdownMenuItem(value: c, child: Text('$c장')),
                  ],
                  onChanged: (c) {
                    if (c != null && c != _chapter) _go(_book, c);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 드롭다운 상자 바탕색 (파스텔 톤). 다크 모드에서도 같은 색을 쓰고 글자는 진하게 둡니다.
  static const Color _bookBoxColor = Color(0xFFD6E8FA); // 파스텔 파랑
  static const Color _chapterBoxColor = Color(0xFFD5F0DE); // 파스텔 초록
  static const Color _boxTextColor = Color(0xFF1F2A37);

  /// 둥근 상자 모양의 드롭다운. 펼친 메뉴도 같은 바탕색입니다.
  Widget _dropdownBox<T>({
    required Color color,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color.lerp(color, Colors.black, 0.15)!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 420,
          dropdownColor: color,
          borderRadius: BorderRadius.circular(10),
          iconEnabledColor: _boxTextColor,
          style: const TextStyle(
            color: _boxTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _verseList(ThemeData theme) {
    return FutureBuilder<_ChapterData>(
      // 장이 바뀌면 목록을 새로 만들어 맨 위부터 보이게 함
      key: ValueKey('$_book$_chapter'),
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('불러오지 못했습니다: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;

        // 대조 화면에서 넘어왔으면 강조한 첫 절이 보이게 스크롤
        if (_scrollPending) {
          _scrollPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final target = _firstHighlightKey.currentContext;
            if (target != null) {
              Scrollable.ensureVisible(
                target,
                alignment: 0.1,
                duration: const Duration(milliseconds: 300),
              );
            }
          });
        }

        // 한 장은 많아야 176절이라 한꺼번에 그려도 충분히 빠릅니다.
        // (한꺼번에 그려야 강조한 절로 바로 스크롤할 수 있음)
        var firstHighlight = true;
        return SingleChildScrollView(
          // 아래쪽은 장 이동 버튼에 가리지 않게 여유를 둠
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${bookName(_book)} $_chapter장',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final v in data.verses)
                Builder(
                  builder: (context) {
                    final highlighted = _isHighlighted(v);
                    final key = highlighted && firstHighlight
                        ? _firstHighlightKey
                        : null;
                    if (highlighted) firstHighlight = false;
                    return _verseTile(
                      theme,
                      v,
                      data.marks[v.verse] ?? const [],
                      highlighted,
                      key,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _verseTile(
    ThemeData theme,
    VerseText v,
    List<_Mark> marks,
    bool highlighted,
    Key? key,
  ) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이 절에서 시작하는 병행·인용 (누르면 대조 화면)
        if (marks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final m in marks) _markChip(theme, m)],
            ),
          ),
        // 시편 표제 같은 소제목
        if (v.heading != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              v.heading!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        // 대조 화면에서 넘어온 범위는 옅은 바탕 + 왼쪽 띠로 강조
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: highlighted
              ? const EdgeInsets.fromLTRB(8, 2, 4, 2)
              : EdgeInsets.zero,
          decoration: highlighted
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${v.verse} ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // 본문은 굵게
                TextSpan(
                  text: v.text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 17, height: 1.7),
          ),
        ),
      ],
    );
  }

  /// 병행·인용 칩. 병행은 목록과 같은 색(두/세/네 복음서), 인용은 보조색.
  Widget _markChip(ThemeData theme, _Mark m) {
    final color = m.quotation
        ? theme.colorScheme.secondaryContainer
        : gospelCountColor(m.gospelCount, alpha: 0.35);
    return ActionChip(
      // 잠긴 묶음(전체 열기 전)은 자물쇠로 표시
      avatar: Icon(
        !isGroupOpen(context, m.groupId)
            ? Icons.lock_outline
            : (m.quotation ? Icons.format_quote : Icons.view_column),
        size: 16,
      ),
      label: Text('${m.quotation ? '인용' : '병행'} · ${m.title}'),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: color,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      tooltip: m.quotation ? '구약 인용 대조 보기' : '복음서 병행 대조 보기',
      onPressed: () {
        // 잠긴 묶음이면 대조 화면 대신 "전체 열기" 안내
        if (!ensureOpen(context, m.groupId)) return;
        // 성경 탭 안에서 대조 화면을 엶 (뒤로 가면 읽던 자리로)
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ParallelComparePage(
              groupId: m.groupId,
              title: m.title,
              quotation: m.quotation,
            ),
          ),
        );
      },
    );
  }
}
