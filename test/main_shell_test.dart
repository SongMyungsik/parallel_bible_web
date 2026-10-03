import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_bible_web/data/bible_text_source.dart';
import 'package:parallel_bible_web/data/memory_bible_text_source.dart';
import 'package:parallel_bible_web/data/passage_data.dart';
import 'package:parallel_bible_web/pages/main_shell.dart';
import 'package:parallel_bible_web/state/app_navigation.dart';
import 'package:parallel_bible_web/state/app_settings.dart';
import 'package:parallel_bible_web/state/parallel_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 실제 데이터로 본 화면을 띄우고 모든 탭과 대조 화면을 열어 봄.
/// 폰 폭(360px)에서 넘침(overflow) 같은 오류가 없어야 합니다. (잠금이 없어 모두 열림)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PassageData passages;
  late MemoryBibleTextSource bible;

  setUpAll(() async {
    passages = await PassageData.load();
    bible = await MemoryBibleTextSource.load();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => AppNavigation()),
          ChangeNotifierProvider(
            create: (_) => ParallelState(passages)..loadGroups(),
          ),
          Provider<BibleTextSource>.value(value: bible),
        ],
        child: MaterialApp(
          theme: settings.theme(Brightness.light),
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('모든 탭을 열어도 오류 없음, 자물쇠 없음', (tester) async {
    await pumpShell(tester);
    expect(find.text('병행 구절 대조'), findsWidgets);

    for (final tab in ['성경', '복음서병행', '구약인용', '설정', '홈']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab 탭');
      expect(find.byIcon(Icons.lock_outline), findsNothing, reason: '$tab 탭');
    }
    // 설정 탭에 "전체 열기"가 없어야 함
    await tester.tap(find.text('설정').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정').at(1)); // 위쪽 탭의 "설정"
    await tester.pumpAndSettle();
    expect(find.text('전체 열기'), findsNothing);
    expect(find.text('화면 모드'), findsOneWidget);
  });

  testWidgets('복음서 병행·구약 인용: 예전에 잠겨 있던 항목도 바로 대조 화면이 열림', (tester) async {
    await pumpShell(tester);

    // 병행: 표 보기에서도 모든 사건(감춘 줄 없음)
    await tester.tap(find.text('복음서병행').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('표'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    // 검색으로 구절 찾기 (예전엔 잠긴 사건은 구절로 못 찾았음)
    await tester.enterText(find.byType(TextField), '누가 9');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);

    // 인용: 사도행전 이후(예전엔 잠김) 하나 열기
    await tester.tap(find.text('구약인용').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '로마서');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
