import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_settings.dart';
import '../state/parallel_state.dart';
import '../state/purchase_state.dart';
import '../ui/gospel_colors.dart';
import '../ui/unlock_sheet.dart';

/// 앱 버전 (pubspec.yaml의 version과 맞춰 주세요)
const String appVersion = '1.0.0';

/// 설정 화면. 위쪽 탭(좌우로 밀어서도 이동)으로 두 쪽을 나눕니다.
///  - 앱 정보: 앱 설명, 기능 안내, 본문 판본, 버전
///  - 설정: 전체 열기(구매), 화면 모드, 앱 색상
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 앱바에 바탕색이 있으면 탭 글자도 앱바 글자색(흰색)으로
    final barText = theme.appBarTheme.foregroundColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          bottom: TabBar(
            labelColor: barText,
            unselectedLabelColor: barText?.withValues(alpha: 0.7),
            indicatorColor: barText,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: '앱 정보'),
              Tab(icon: Icon(Icons.tune), text: '설정'),
            ],
          ),
        ),
        body: const TabBarView(children: [_AppInfoTab(), _OptionsTab()]),
      ),
    );
  }
}

/// 구역 제목 (예: "화면 모드")
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// "앱 정보" 쪽
class _AppInfoTab extends StatelessWidget {
  const _AppInfoTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ParallelState>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '병행 구절 대조',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '복음서의 병행 본문과 신약이 인용한 구약 본문을 나란히 놓고 '
                  '비교하는 앱입니다. 여러 본문에 함께 나오는 표현은 색으로 표시됩니다.',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.view_column,
                  title: '복음서 병행 · ${state.groups.length}개 사건',
                  body: '같은 사건을 기록한 복음서 본문을 나란히 보여 줍니다.',
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      for (final count in [4, 3, 2]) GospelCountLegend(count),
                    ],
                  ),
                ),
                _InfoRow(
                  icon: Icons.format_quote,
                  title: '구약 인용 · ${state.quotations.length}곳',
                  body:
                      '복음서부터 요한계시록까지, 신약이 인용한 구약 본문을 함께 보여 주고, '
                      '신약과 구약 사이의 같은 표현을 표시합니다.',
                ),
                const _InfoRow(
                  icon: Icons.menu_book,
                  title: '성경',
                  body: '구약·신약 전체 본문을 장별로 읽을 수 있습니다.',
                ),
                const _InfoRow(
                  icon: Icons.info_outline,
                  title: '[없음] 표시',
                  body: '일부 사본에는 없는 절입니다. (예: 마 17:21)',
                ),
                const Divider(height: 24),
                const _KeyValue('성경 본문', '개역한글'),
                const _KeyValue('버전', appVersion),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "설정" 쪽: 전체 열기(구매), 화면 모드, 앱 색상
class _OptionsTab extends StatelessWidget {
  const _OptionsTab();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final purchase = context.watch<PurchaseState>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ---- 전체 열기 (구매 · 구매 복원 · 구매 상태) ----
        const _SectionTitle('전체 열기'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(padding: EdgeInsets.all(16), child: UnlockPanel()),
          ),
        ),
        // Play 결제가 없는 기기(Windows 등 개발용)에서만: 잠금을 직접 바꿔 화면 확인
        if (!purchase.storeSupported)
          SwitchListTile(
            title: const Text('개발용: 전체 열림'),
            subtitle: const Text('이 기기에는 Play 결제가 없어 직접 바꿉니다.'),
            value: purchase.unlocked,
            onChanged: purchase.setUnlockedForDev,
          ),

        // ---- 화면 모드 ----
        const _SectionTitle('화면 모드'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('시스템'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('라이트'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('다크'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
        ),

        // ---- 앱 색상 ----
        const _SectionTitle('앱 색상 (앱바 · 하단 메뉴)'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in AppColorOption.values)
                _ColorChoice(
                  option: option,
                  selected: settings.appColor == option,
                  onTap: () => settings.setAppColor(option),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 앱 색상 선택 동그라미 하나
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = option.color ?? theme.colorScheme.surfaceContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check,
                      color: option.color == null
                          ? theme.colorScheme.onSurface
                          : Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(option.label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(value),
        ],
      ),
    );
  }
}
