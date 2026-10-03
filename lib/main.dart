import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/bible_importer.dart';
import 'data/bible_text_source.dart';
import 'data/db_bible_text_source.dart';
import 'data/parallel_importer.dart';
import 'pages/main_shell.dart';
import 'pages/start_page.dart';
import 'state/app_navigation.dart';
import 'state/app_settings.dart';
import 'state/parallel_state.dart';
import 'state/purchase_state.dart';

void main() {
  // rootBundle(JSON 읽기)을 쓰려면 꼭 필요합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // Windows에서는 ffi 방식으로 sqflite를 켭니다. (Android는 기본 그대로)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ParallelViewerApp());
}

// ---------------------------------------------------------------
// 앱: 시작 화면에서 DB를 준비하고, [시작하기]를 누르면 본 화면(하단 네비)으로 넘어갑니다.
// ---------------------------------------------------------------
class ParallelViewerApp extends StatefulWidget {
  const ParallelViewerApp({super.key});

  @override
  State<ParallelViewerApp> createState() => _ParallelViewerAppState();
}

class _ParallelViewerAppState extends State<ParallelViewerApp> {
  final AppSettings _settings = AppSettings();
  Database? _db;
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
      // DB 열기 → 설정 읽기 (시작 화면 색도 저장된 앱 색상으로 바뀜)
      final dbPath = p.join(await getDatabasesPath(), 'parallel_viewer.db');
      final db = await openDatabase(dbPath);
      await _settings.load(db);

      // 표 만들기 → JSON 넣기 (바뀐 것이 있을 때만 실제로 넣음)
      _setMessage('병행 · 인용 목록을 준비하는 중…');
      await ParallelImporter.createTables(db);
      await ParallelImporter.importIfNeeded(db, PassageCollection.parallel);
      await ParallelImporter.importIfNeeded(db, PassageCollection.quotation);

      _setMessage('성경 본문을 준비하는 중… (처음 한 번은 몇 초 걸립니다)');
      await BibleImporter.createTables(db);
      await BibleImporter.importIfNeeded(db);

      if (mounted) setState(() => _db = db);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _setMessage(String text) {
    if (mounted) setState(() => _message = text);
  }

  @override
  Widget build(BuildContext context) {
    final db = _db;

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

        if (db == null || !_started) {
          return app(
            StartPage(
              message: _message,
              error: _error,
              onStart: db == null
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
            // "전체 열기" 구매 상태 (앱을 켤 때 Play 스토어에 이전 구매를 확인)
            ChangeNotifierProvider(
              create: (_) => PurchaseState(_settings)..init(),
            ),
            ChangeNotifierProvider(
              create: (_) => ParallelState(db)..loadGroups(),
            ),
            // 본문 공급처: 성경 DB. (화면만 확인하고 싶을 땐 SampleBibleTextSource()로 바꾸면 됩니다.)
            Provider<BibleTextSource>(create: (_) => DbBibleTextSource(db)),
          ],
          child: app(const MainShell()),
        );
      },
    );
  }
}
