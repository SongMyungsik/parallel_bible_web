import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ref_format.dart';
import '../state/app_settings.dart';
import '../state/parallel_state.dart';
import '../state/purchase_state.dart';
import '../ui/unlock_sheet.dart';

/// 홈 화면: 앱 소개 + 성경 / 복음서 병행 / 구약 인용으로 가는 카드.
/// 카드를 누르면 직전에 보던 내용이 열립니다.
///  - 성경: 읽던 장
///  - 복음서 병행·구약 인용: 마지막으로 본 대조 화면 (본 적이 없으면 목록)
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenTab, required this.onResume});

  /// 하단 네비 탭 번호로 이동 (1 = 성경, 2 = 복음서 병행, 3 = 구약 인용)
  final ValueChanged<int> onOpenTab;

  /// 마지막으로 본 대조 화면 다시 열기 (quotation = 구약 인용이면 true)
  final void Function(bool quotation, RecentView view) onResume;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ParallelState>();
    final settings = context.read<AppSettings>();
    final unlocked = context.watch<PurchaseState>().unlocked;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('병행 구절 대조')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 앱 소개
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 앱 아이콘
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '병행 구절 대조',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '복음서의 병행 본문과 신약이 인용한 구약 본문을 '
                          '나란히 놓고 같은 표현을 색으로 비교합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 구매 전에만: 무료 미리보기 안내 → 누르면 "전체 열기" 창
          if (!unlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const UnlockBanner(),
            ),
            const SizedBox(height: 12),
          ],
          // 성경: 읽던 장 (장을 넘길 때마다 글자가 바뀜)
          ValueListenableBuilder<(String, int)>(
            valueListenable: settings.biblePosition,
            builder: (context, pos, _) => _MenuCard(
              icon: Icons.menu_book,
              title: '성경',
              subtitle: '이어 읽기: ${bookName(pos.$1)} ${pos.$2}장',
              onTap: () => onOpenTab(1),
            ),
          ),
          // 복음서 병행: 마지막으로 본 사건
          ValueListenableBuilder<RecentView?>(
            valueListenable: settings.recentParallel,
            builder: (context, recent, _) => _MenuCard(
              icon: Icons.view_column,
              title: '복음서 병행',
              subtitle:
                  '${state.groups.length}개 사건 · 마태 · 마가 · 누가 · 요한'
                  '${recent == null ? '' : '\n이어 보기: ${recent.title}'}',
              onTap: () =>
                  recent == null ? onOpenTab(2) : onResume(false, recent),
            ),
          ),
          // 구약 인용: 마지막으로 본 인용
          ValueListenableBuilder<RecentView?>(
            valueListenable: settings.recentQuotation,
            builder: (context, recent, _) => _MenuCard(
              icon: Icons.format_quote,
              title: '구약 인용',
              subtitle:
                  '${state.quotations.length}곳 · 신약이 인용한 구약 본문'
                  '${recent == null ? '' : '\n이어 보기: ${recent.title}'}',
              onTap: () =>
                  recent == null ? onOpenTab(3) : onResume(true, recent),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '성경 본문: 개역한글',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
