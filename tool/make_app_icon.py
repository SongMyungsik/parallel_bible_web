"""앱 아이콘 만들기: 펼친 성경의 양쪽 페이지를 같은 색 줄로 대조하는 모습.

실행:  python tool/make_app_icon.py
       python tool/make_app_icon.py --store   (Play 스토어용 512 아이콘만: promo/store/icon_512.png)
만드는 파일:
  - assets/icon/app_icon.png               (앱 안: 스플래시·홈 화면)
  - android/app/src/main/res/mipmap-*/ic_launcher.png            (옛 Android용)
  - android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (Android 8+ 적응형 아이콘 앞면)
  - android/app/src/main/res/drawable/ic_launcher_background.xml (적응형 아이콘 바탕)
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  - windows/runner/resources/app_icon.ico
디자인을 바꾸려면 아래 색·좌표를 고친 뒤 다시 실행하세요.
"""
import io
import os
import sys

from PIL import Image, ImageDraw

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 2048  # 크게 그린 뒤 줄여서 가장자리를 매끄럽게

# 색
TOP = (57, 73, 171)       # 인디고
BOTTOM = (0, 137, 123)    # 청록
PAGE = (255, 255, 255)
COVER = (26, 35, 94)
LINE = (176, 190, 197)
MARKS = [(206, 147, 216), (129, 199, 132), (100, 181, 246)]  # 보라·초록·파랑 (앱의 네/세/두 복음서 색)


def gradient_bg(size, radius):
    """둥근 네모 + 위→아래 그라데이션"""
    grad = Image.new('RGB', (1, size))
    for y in range(size):
        t = y / (size - 1)
        grad.putpixel((0, y), tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    grad = grad.resize((size, size))
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    img.paste(grad, (0, 0), mask)
    return img


def curve(x0, y0, x1, y1, lift, n=40):
    """(x0,y0)→(x1,y1) 사이를 위로 살짝 휜 선의 점들 (페이지 윗/아랫단)"""
    pts = []
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t - lift * 4 * t * (1 - t)
        pts.append((x, y))
    return pts


def draw_symbol(img, scale=1.0, cx=S / 2, cy=S / 2 + 60):
    """펼친 책 + 대조 줄 + ⇄ 화살표. scale=1이면 2048 캔버스 기준 크기."""
    d = ImageDraw.Draw(img)

    def P(x, y):  # 가운데 기준 좌표 → 캔버스 좌표
        return (cx + (x - 1024) * scale, cy + (y - 1024) * scale)

    spine_top, spine_bot = 700, 1560
    outer_l, outer_r = 300, 1748
    top_outer, bot_outer = 640, 1500

    # 표지(책 뒤 그림자)
    cover = [P(outer_l - 40, top_outer + 40)] \
        + [P(x, y) for x, y in curve(outer_l - 40, bot_outer + 60, 1024, spine_bot + 60, 50)] \
        + [P(x, y) for x, y in curve(1024, spine_bot + 60, outer_r + 40, bot_outer + 60, 50)] \
        + [P(outer_r + 40, top_outer + 40)]
    d.polygon(cover, fill=COVER)

    # 왼쪽·오른쪽 페이지 (양쪽 모두 윗단·아랫단이 위로 살짝 휨)
    for ox in (outer_l, outer_r):
        top = curve(ox, top_outer, 1024, spine_top, 70)
        bot = curve(1024, spine_bot, ox, bot_outer, 50)
        page = [P(x, y) for x, y in top] + [P(x, y) for x, y in bot]
        d.polygon(page, fill=PAGE)

    # 가운데 접힌 선
    d.line([P(1024, spine_top), P(1024, spine_bot)], fill=(207, 216, 220), width=int(14 * scale))

    # 본문 줄 (양쪽 같은 높이의 줄 일부를 같은 색으로 칠함 = 대조)
    rows = [800, 910, 1020, 1130, 1240, 1350]
    marked = {0: MARKS[0], 2: MARKS[1], 4: MARKS[2]}
    h = 50
    for i, y in enumerate(rows):
        color = marked.get(i, LINE)
        for x0, x1 in ((outer_l + 110, 1024 - 90), (1024 + 90, outer_r - 110)):
            # 짧은 줄을 섞어 글처럼 보이게
            if i == 5:
                x1 = x0 + (x1 - x0) * 0.6
            a, b = P(x0, y - h / 2), P(x1, y + h / 2)
            d.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=h * scale / 2, fill=color)

    # ⇄ 양방향 화살표 (책 위)
    y1, y2 = 400, 520
    w = int(44 * scale)
    d.line([P(720, y1), P(1300, y1)], fill=PAGE, width=w)
    d.polygon([P(1380, y1), P(1270, y1 - 80), P(1270, y1 + 80)], fill=PAGE)
    d.line([P(748, y2), P(1328, y2)], fill=PAGE, width=w)
    d.polygon([P(668, y2), P(778, y2 - 80), P(778, y2 + 80)], fill=PAGE)


def full_icon(size):
    """바탕 포함 아이콘"""
    img = gradient_bg(S, radius=int(S * 0.22))
    draw_symbol(img, scale=0.92)
    return img.resize((size, size), Image.LANCZOS)


def foreground(size):
    """Android 적응형 아이콘 앞면: 108dp 중 가운데 66dp 안에 들어가게 작게"""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw_symbol(img, scale=0.62)
    return img.resize((size, size), Image.LANCZOS)


def store_icon(size=512):
    """Play 스토어 등록용: 모서리를 깎지 않은 꽉 찬 정사각형 (둥근 모양은 Play가 입힘), 알파 없음"""
    img = gradient_bg(S, radius=0)
    draw_symbol(img, scale=0.92)
    return img.convert('RGB').resize((size, size), Image.LANCZOS)


def save(img, *path):
    p = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print('저장', os.path.relpath(p, ROOT))


def main():
    # python tool/make_app_icon.py --store → 스토어용 512 아이콘만 (promo/store/icon_512.png)
    if '--store' in sys.argv:
        save(store_icon(512), 'promo', 'store', 'icon_512.png')
        return

    big = full_icon(1024)
    save(big, 'assets', 'icon', 'app_icon.png')

    res = ('android', 'app', 'src', 'main', 'res')
    for name, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        save(full_icon(px), *res, f'mipmap-{name}', 'ic_launcher.png')
        save(foreground(px * 108 // 48), *res, f'mipmap-{name}', 'ic_launcher_foreground.png')

    def write(text, *path):
        p = os.path.join(ROOT, *path)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        print('저장', os.path.relpath(p, ROOT))

    hex_ = lambda c: '#FF%02X%02X%02X' % c
    write(f'''<?xml version="1.0" encoding="utf-8"?>
<!-- 앱 아이콘 바탕 (tool/make_app_icon.py가 만듦) -->
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:angle="270"
        android:startColor="{hex_(TOP)}"
        android:endColor="{hex_(BOTTOM)}" />
</shape>
''', *res, 'drawable', 'ic_launcher_background.xml')
    write('''<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+ 적응형 아이콘 (tool/make_app_icon.py가 만듦) -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''', *res, 'mipmap-anydpi-v26', 'ic_launcher.xml')

    ico = full_icon(256)
    p = os.path.join(ROOT, 'windows', 'runner', 'resources', 'app_icon.ico')
    ico.save(p, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print('저장', os.path.relpath(p, ROOT))


if __name__ == '__main__':
    main()
