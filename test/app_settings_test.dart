import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel_bible_web/state/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('저장소에 글자가 아닌 값이 있어도 멈추지 않고 기본값으로 시작', () async {
    // 같은 주소의 다른 웹앱이 같은 이름으로 숫자를 저장해 둔 경우 (폰에서 실제로 난 오류)
    SharedPreferences.setMockInitialValues({
      'app_color': 4280191205,
      'theme_mode': 2,
      'bible_book': 7,
      'bible_chapter': true,
    });
    final settings = AppSettings();
    await settings.load();
    expect(settings.appColor, AppColorOption.indigo);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.bibleBook, 'GEN');
    expect(settings.bibleChapter, 1);
  });

  test('저장한 값은 다시 읽힘', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await settings.setAppColor(AppColorOption.wine);
    await settings.setBiblePosition('MAT', 5);

    final again = AppSettings();
    await again.load();
    expect(again.appColor, AppColorOption.wine);
    expect(again.bibleBook, 'MAT');
    expect(again.bibleChapter, 5);
  });
}
