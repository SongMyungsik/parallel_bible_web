import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parallel_state.dart';
import '../state/purchase_state.dart';

/// 이 묶음을 지금 열 수 있으면 true.
/// 잠겨 있으면 "전체 열기" 안내 창을 띄우고 false를 돌려줍니다.
/// (대조 화면을 여는 모든 곳에서 먼저 부릅니다)
bool ensureOpen(BuildContext context, int groupId) {
  if (isGroupOpen(context, groupId)) return true;
  showUnlockSheet(context);
  return false;
}

/// 이 묶음을 지금 열 수 있는지 (창을 띄우지 않고 확인만)
bool isGroupOpen(BuildContext context, int groupId) {
  final purchase = context.read<PurchaseState>();
  final state = context.read<ParallelState>();
  return purchase.canOpen(id: groupId, section: state.sectionOf(groupId));
}

/// "전체 열기" 안내 창 (아래에서 올라오는 창, 하단 메뉴까지 덮음)
Future<void> showUnlockSheet(BuildContext context) {
  context.read<PurchaseState>().clearMessage();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: UnlockPanel(),
      ),
    ),
  );
}

/// "전체 열기" 내용: 설명 + [전체 열기] + [구매 복원] + 안내 문구.
/// 안내 창과 설정 화면에서 함께 씁니다.
class UnlockPanel extends StatelessWidget {
  const UnlockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseState>();
    final state = context.watch<ParallelState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = purchase.message;

    if (purchase.unlocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                '전체 기능이 열려 있습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '복음서 병행 ${state.groups.length}개 사건과 '
            '구약 인용 ${state.quotations.length}곳을 모두 볼 수 있습니다.',
          ),
        ],
      );
    }

    final price = purchase.priceLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_open, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              '전체 열기',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '복음서 병행 ${state.groups.length}개 사건과 '
          '구약 인용 ${state.quotations.length}곳을 모두 볼 수 있습니다.\n'
          '한 번 구매하면 계속 사용할 수 있습니다.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '지금은 성경 읽기 전체와 "탄생과 준비" 단계, '
          '대표 사건 몇 개를 무료로 볼 수 있습니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: purchase.busy ? null : purchase.buy,
            icon: purchase.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open),
            label: Text(price == null ? '전체 열기 구매' : '전체 열기 · $price'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: purchase.busy ? null : purchase.restore,
            child: const Text('이미 구매하셨나요? 구매 복원'),
          ),
        ),
        // 코드로 열기 (Play 검토자·선물용)
        Center(
          child: TextButton(
            onPressed: purchase.busy ? null : () => _askCode(context, purchase),
            child: const Text('코드가 있으신가요? 코드 입력'),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// [코드 입력] 창: 맞는 코드를 넣으면 결제 없이 전체가 열림
Future<void> _askCode(BuildContext context, PurchaseState purchase) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('코드 입력'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: '받으신 코드를 입력하세요',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (text) => Navigator.of(context).pop(text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('확인'),
        ),
      ],
    ),
  );
  if (code == null || code.trim().isEmpty) return;
  // 결과(열림 / 코드가 맞지 않음)는 안내 문구로 보여 줌
  await purchase.redeemCode(code);
}

/// 목록 위에 두는 한 줄 안내: "무료 미리보기 · 전체 열기" (구매하면 사라짐)
class UnlockBanner extends StatelessWidget {
  const UnlockBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<PurchaseState>().unlocked) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: () => showUnlockSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '무료 미리보기 중 · 자물쇠 항목은 전체 열기로',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              Text(
                '전체 열기',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 대조표 맨 아래 안내: 표에서는 잠긴 줄을 감추므로 "나머지 N개는 전체 열기 후"라고 알려 줌.
/// 누르면 "전체 열기" 창.
class HiddenRowsNote extends StatelessWidget {
  const HiddenRowsNote({super.key, required this.count, required this.unit});

  /// 감춘 줄 수
  final int count;

  /// 세는 말 (예: "개 사건", "곳")
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: () => showUnlockSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: scheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '나머지 $count$unit은 전체 열기 후 표에 나옵니다',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
