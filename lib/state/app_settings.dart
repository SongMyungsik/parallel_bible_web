import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 색상 선택지 (앱바와 하단 네비 바탕색). 서로 뚜렷이 다른 5가지만 둡니다.
/// 앱바 글자가 흰색이라 흰 글자가 잘 보이는 진한 톤만 씁니다.
/// 저장할 때는 이름(indigo 등)을 쓰므로 이미 있는 이름은 바꾸지 마세요.
enum AppColorOption {
  indigo('인디고', Colors.indigo),
  green('초록', Color(0xFF388E3C)),
  wine('와인', Color(0xFF880E4F)),
  brown('갈색', Colors.brown),
  charcoal('먹색', Color(0xFF303030));

  const AppColorOption(this.label, this.color);

  final String label;
  final Color? color;

  /// 저장된 이름으로 찾기. 예전에 있던 색(파랑·청록 등)은 같은 계열의 남은 색으로.
  static AppColorOption fromName(String? name) {
    const merged = {
      'blue': 'indigo',
      'cyan': 'indigo',
      'navy': 'indigo',
      'violet': 'indigo',
      'purple': 'indigo',
      'olive': 'green',
      'teal': 'green',
      'red': 'wine',
      'pink': 'wine',
      'orange': 'brown',
      'gold': 'brown',
      'blueGrey': 'charcoal',
      'none': 'charcoal',
    };
    final key = merged[name] ?? name;
    return values.firstWhere((c) => c.name == key, orElse: () => indigo);
  }
}

/// 마지막으로 본 대조 화면 (홈 화면의 "이어 보기"용)
class RecentView {
  const RecentView(this.id, this.title);

  final int id;
  final String title;

  String encode() => '$id|$title';

  static RecentView? decode(String? text) {
    if (text == null) return null;
    final i = text.indexOf('|');
    if (i < 0) return null;
    final id = int.tryParse(text.substring(0, i));
    return id == null ? null : RecentView(id, text.substring(i + 1));
  }
}

/// 설정 값(화면 모드, 앱 색상, 마지막으로 읽은 성경 위치)을 기억하고 저장합니다.
///
/// shared_preferences에 "이름 = 값" 형태로 저장합니다. (웹에서는 브라우저의 localStorage)
/// 같은 브라우저로 다시 열면 설정이 유지됩니다.
class AppSettings extends ChangeNotifier {
  /// 저장 이름 앞에 붙는 이 앱만의 이름표.
  /// 브라우저 저장소는 songmyungsik.github.io 주소 전체가 함께 쓰므로, 기본값('flutter.')을 쓰면
  /// 같은 주소의 다른 Flutter 웹앱이 저장한 값(예: 숫자로 된 app_color)과 섞입니다.
  /// main()에서 SharedPreferences.setPrefix(storagePrefix)로 지정합니다.
  static const String storagePrefix = 'parallel_bible_web.';

  SharedPreferences? _prefs;

  ThemeMode themeMode = ThemeMode.system;
  AppColorOption appColor = AppColorOption.indigo;

  /// 성경 화면에서 마지막으로 본 책·장
  String bibleBook = 'GEN';
  int bibleChapter = 1;

  /// 마지막으로 본 복음서 병행 / 구약 인용.
  /// 앱 전체 테마와 상관없으므로 따로 알림(ValueNotifier)을 둡니다.
  final recentParallel = ValueNotifier<RecentView?>(null);

  /// 성경 위치가 바뀔 때마다 알림 (홈 화면 "이어 읽기" 글자용)
  final biblePosition = ValueNotifier<(String, int)>(('GEN', 1));
  final recentQuotation = ValueNotifier<RecentView?>(null);

  /// 저장된 값을 읽어 옵니다. (앱 시작 때 한 번)
  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    // 글자가 아닌 값(다른 앱이 남긴 값 등)은 없는 것으로 보고 기본값을 씀
    String? read(String key) {
      final value = prefs.get(key);
      return value is String ? value : null;
    }

    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == read('theme_mode'),
      orElse: () => ThemeMode.system,
    );
    appColor = AppColorOption.fromName(read('app_color'));
    bibleBook = read('bible_book') ?? 'GEN';
    bibleChapter = int.tryParse(read('bible_chapter') ?? '') ?? 1;
    biblePosition.value = (bibleBook, bibleChapter);
    recentParallel.value = RecentView.decode(read('recent_parallel'));
    recentQuotation.value = RecentView.decode(read('recent_quotation'));

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _save('theme_mode', mode.name);
  }

  Future<void> setAppColor(AppColorOption option) async {
    appColor = option;
    notifyListeners();
    await _save('app_color', option.name);
  }

  /// 성경 위치는 자주 바뀌므로 화면을 다시 그리지 않고 저장만 합니다.
  Future<void> setBiblePosition(String book, int chapter) async {
    bibleBook = book;
    bibleChapter = chapter;
    biblePosition.value = (book, chapter);
    await _save('bible_book', book);
    await _save('bible_chapter', '$chapter');
  }

  /// 대조 화면을 열 때마다 기록합니다.
  Future<void> setRecentView({
    required bool quotation,
    required int id,
    required String title,
  }) async {
    final view = RecentView(id, title);
    if (quotation) {
      recentQuotation.value = view;
      await _save('recent_quotation', view.encode());
    } else {
      recentParallel.value = view;
      await _save('recent_parallel', view.encode());
    }
  }

  Future<void> _save(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  // ---- 테마 만들기 ----

  /// 앱바·하단 네비 바탕색. 다크 모드에서는 조금 어둡게 합니다.
  Color? barColor(Brightness brightness) {
    final c = appColor.color;
    if (c == null) return null;
    return brightness == Brightness.dark
        ? Color.lerp(c, Colors.black, 0.45)
        : c;
  }

  ThemeData theme(Brightness brightness) {
    final base = ThemeData(
      colorSchemeSeed: appColor.color ?? Colors.indigo,
      brightness: brightness,
      useMaterial3: true,
    );
    final bar = barColor(brightness);
    if (bar == null) return base;

    // 바탕색이 있는 앱바·하단 네비는 글자와 아이콘을 흰색으로
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bar,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bar,
        indicatorColor: Colors.white24,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
