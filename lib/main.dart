import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/bible_text_source.dart';
import 'data/memory_bible_text_source.dart';
import 'data/passage_data.dart';
import 'pages/main_shell.dart';
import 'pages/start_page.dart';
import 'state/app_navigation.dart';
import 'state/app_settings.dart';
import 'state/parallel_state.dart';

void main() {
  // rootBundle(JSON 읽기)을 쓰려면 꼭 필요합니다.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParallelViewerApp());
}

/// 앱을 켤 때 메모리에 올리는 데이터 (병행·인용 목록 + 성경 본문)
typedef _AppData = ({PassageData passages, MemoryBibleTextSource bible});

// ---------------------------------------------------------------
// 앱: 시작 화면에서 데이터를 불러오고, [시작하기]를 누르면 본 화면(하단 네비)으로 넘어갑니다.
// ---------------------------------------------------------------
class ParallelViewerApp extends StatefulWidget {
  const ParallelViewerApp({super.key});

  @override
  State<ParallelViewerApp> createState() => _ParallelViewerAppState();
}

class _ParallelViewerAppState extends State<ParallelViewerApp> {
  final AppSettings _settings = AppSettings();
  _AppData? _data;
  String _message = '준비하는 중…';
  Object? _error;

  /// 시작 화면에서 [시작하기]를 눌렀는지
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      // 설정 읽기 (시작 화면 색도 저장된 앱 색상으로 바뀜)
      await _settings.load();

      _setMessage('병행 · 인용 목록을 불러오는 중…');
      final passages = await PassageData.load();

      _setMessage('성경 본문을 불러오는 중… (처음 한 번은 몇 초 걸립니다)');
      final bible = await MemoryBibleTextSource.load();

      if (mounted) {
        setState(() => _data = (passages: passages, bible: bible));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _setMessage(String text) {
    if (mounted) setState(() => _message = text);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    // 설정(화면 모드·앱 색상)이 바뀌면 앱 전체 테마를 다시 그림
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        MaterialApp app(Widget home) => MaterialApp(
          title: '병행 구절 대조',
          debugShowCheckedModeBanner: false, // 우측 위 DEBUG 리본 숨김
          theme: _settings.theme(Brightness.light),
          darkTheme: _settings.theme(Brightness.dark),
          themeMode: _settings.themeMode,
          home: home,
        );

        if (data == null || !_started) {
          return app(
            StartPage(
              message: _message,
              error: _error,
              onStart: data == null
                  ? null
                  : () => setState(() => _started = true),
            ),
          );
        }

        // 화면들이 함께 쓰는 상태. MaterialApp 위에 두어야
        // 새로 여는 화면(대조 화면 등)에서도 읽을 수 있습니다.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _settings),
            // 화면끼리 주고받는 이동 요청 (대조 화면 → 성경)
            ChangeNotifierProvider(create: (_) => AppNavigation()),
            ChangeNotifierProvider(
              create: (_) => ParallelState(data.passages)..loadGroups(),
            ),
            // 본문 공급처: 메모리에 올린 성경. (화면만 확인하고 싶을 땐 SampleBibleTextSource()로 바꾸면 됩니다.)
            Provider<BibleTextSource>.value(value: data.bible),
          ],
          child: app(const MainShell()),
        );
      },
    );
  }
}
