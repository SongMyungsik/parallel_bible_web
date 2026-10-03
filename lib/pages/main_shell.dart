import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_navigation.dart';
import '../state/app_settings.dart';
import '../ui/unlock_sheet.dart';

import 'bible_page.dart';
import 'home_page.dart';
import 'parallel_compare_page.dart';
import 'parallel_list_page.dart';
import 'quotation_list_page.dart';
import 'settings_page.dart';

/// 하단 네비(홈 / 성경 / 복음서병행 / 구약인용 / 설정)가 있는 본 화면.
///
/// 탭마다 자기 화면 쌓기(Navigator)를 따로 가집니다.
/// 그래서 목록에서 대조 화면을 열어도 하단 네비 위쪽에 열리고,
/// 하단 네비는 계속 보입니다. (폰 아래쪽 시스템 바에 본문이 가려지지 않음)
/// 탭을 바꿔도 각 탭에서 보던 화면은 그대로 유지됩니다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// 탭별 화면 쌓기
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());

  late final AppNavigation _navigation;

  @override
  void initState() {
    super.initState();
    // 대조 화면에서 "성경에서 보기"를 누르면 성경 탭으로 전환
    _navigation = context.read<AppNavigation>();
    _navigation.addListener(_onNavigation);
  }

  @override
  void dispose() {
    _navigation.removeListener(_onNavigation);
    super.dispose();
  }

  /// AppNavigation의 알림은 "성경에서 보기" 요청뿐이므로 알림이 오면 항상 성경 탭으로.
  /// (요청 내용은 성경 화면이 꺼내 가므로 여기서는 탭만 바꿈)
  void _onNavigation() {
    // 성경 탭 위에 열려 있던 화면(대조 화면 등)은 닫고 본문이 보이게
    _navigators[1].currentState?.popUntil((route) => route.isFirst);
    setState(() => _index = 1);
  }

  /// 복음서병행(2)·구약인용(3) 탭은 누를 때마다 목록부터 보여 줌
  static const _listTabs = {2, 3};

  void _open(int index) {
    if (index == _index || _listTabs.contains(index)) {
      // 지금 탭을 한 번 더 누르거나 목록 탭을 누르면 그 탭의 첫 화면(목록)으로
      _navigators[index].currentState?.popUntil((route) => route.isFirst);
    }
    if (index != _index) setState(() => _index = index);
  }

  /// 홈의 "이어 보기": 목록 탭으로 가서 마지막으로 본 대조 화면을 목록 위에 엶
  /// (뒤로 가면 목록이 나옴)
  void _resume(bool quotation, RecentView view) {
    final index = quotation ? 3 : 2;
    final navigator = _navigators[index].currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
    setState(() => _index = index);
    // 잠긴 묶음이면(구매 전) 목록만 보여 주고 "전체 열기" 안내
    if (!ensureOpen(context, view.id)) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ParallelComparePage(
          groupId: view.id,
          title: view.title,
          quotation: quotation,
        ),
      ),
    );
  }

  /// 뒤로 가기: 탭 안에서 연 화면 닫기 → 홈 탭으로 → 앱 종료 순서
  void _back() {
    final navigator = _navigators[_index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (_index != 0) {
      setState(() => _index = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  Widget _tab(int index, Widget firstPage) {
    return Navigator(
      key: _navigators[index],
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => firstPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _tab(0, HomePage(onOpenTab: _open, onResume: _resume)),
            _tab(1, const BiblePage()),
            _tab(2, const ParallelListPage()),
            _tab(3, const QuotationListPage()),
            _tab(4, const SettingsPage()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _open,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: '성경',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_column_outlined),
              selectedIcon: Icon(Icons.view_column),
              label: '복음서병행',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_quote_outlined),
              selectedIcon: Icon(Icons.format_quote),
              label: '구약인용',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
