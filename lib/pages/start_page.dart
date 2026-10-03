import 'package:flutter/material.dart';

import 'settings_page.dart' show appVersion;

/// 앱을 켜면 나오는 시작 화면.
///  - 위에서부터: 그림(원 안에 펼친 책과 ⇄ 화살표) · 앱 이름 · 소개 · 본문 판본 · [시작하기] · 교회 로고 · 버전
///    (교회 로고는 Play 스토어 앱과 구분하기 위한 웹판 표시)
///  - 데이터를 준비하는 동안에는 [시작하기] 자리에 "준비하는 중…"을 보여 주고,
///    준비가 끝나면([onStart]가 생기면) 버튼이 나타납니다.
///  - 바탕: 앱 색상을 옅게 푼 파스텔 그라데이션 (다크 모드에서는 어두운 톤)
class StartPage extends StatelessWidget {
  const StartPage({super.key, required this.message, this.error, this.onStart});

  /// 지금 하고 있는 일 (예: "성경 본문을 준비하는 중…")
  final String message;

  /// 준비 중 오류가 나면 그 내용
  final Object? error;

  /// 준비가 끝나면 [시작하기]를 눌렀을 때 할 일. null이면 아직 준비 중.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    return Scaffold(
      // 그라데이션이 상태바 아래까지 깔리도록 SafeArea 바깥에 둠
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: startGradient(scheme)),
        child: SafeArea(
          // 화면이 낮아도(가로 모드 등) 넘치지 않게 스크롤, 높으면 가운데 정렬
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 폰 브라우저(주소창 때문에 화면이 낮음)에서도 스크롤 없이 한 화면에 들어오게
                    // 그림·간격을 작게 잡음
                    const StartEmblem(size: 100),
                    const SizedBox(height: 20),
                    Text(
                      '병행 구절 대조',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '복음서의 병행 본문과\n'
                      '신약이 인용한 구약 본문을\n'
                      '나란히 놓고 같은 표현을\n'
                      '색으로 비교합니다.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '성경 본문 : 개역한글',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 20),
                    // 버튼 자리: 준비 중 / 오류 / 시작하기
                    SizedBox(height: 64, child: Center(child: _action(theme))),
                    const SizedBox(height: 20),
                    const ChurchLogo(),
                    const SizedBox(height: 12),
                    Text(
                      'Parallel_Bible   ver. $appVersion',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(ThemeData theme) {
    final muted = theme.colorScheme.onSurfaceVariant;
    if (error != null) {
      return Text(
        '준비하지 못했습니다.\n$error',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final start = onStart;
    if (start == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      );
    }
    return OutlinedButton(
      onPressed: start,
      style: OutlinedButton.styleFrom(
        // 그라데이션 위에서 또렷하게: 옅은 바탕
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
        minimumSize: const Size(180, 52),
        shape: const StadiumBorder(),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      child: const Text('시작하기'),
    );
  }
}

/// 교회 로고 (assets/images/church_logo.png, 바탕이 투명하고 글자가 검정).
/// 다크 모드에서는 검정 글자가 묻히지 않게 밝은 둥근 바탕 위에 둡니다.
class ChurchLogo extends StatelessWidget {
  const ChurchLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final logo = Image.asset(
      'assets/images/church_logo.png',
      width: 150,
      semanticLabel: '광은교회',
    );
    if (!dark) return logo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: logo,
      ),
    );
  }
}

/// 시작 화면 바탕: 왼쪽 위(앱 색상 계열) → 가운데(밝게) → 오른쪽 아래(보조 색 계열).
/// 색은 테마의 옅은 색(container)을 써서 라이트에서는 파스텔, 다크에서는 어두운 톤이 됩니다.
LinearGradient startGradient(ColorScheme scheme) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(scheme.surface, scheme.primaryContainer, 0.9)!,
      Color.lerp(scheme.surface, scheme.primaryContainer, 0.25)!,
      Color.lerp(scheme.surface, scheme.tertiaryContainer, 0.9)!,
    ],
    stops: const [0, 0.5, 1],
  );
}

/// 시작 화면 맨 위 그림: 원 안에 펼친 책, 그 위에 ⇄ 화살표.
/// 선은 앱 색상(primary)이라 설정의 앱 색상·다크 모드를 따라 바뀝니다.
/// 양쪽 페이지의 같은 줄은 같은 색 (앱 아이콘처럼 "같은 표현을 같은 색으로").
class StartEmblem extends StatelessWidget {
  const StartEmblem({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _EmblemPainter(
        line: scheme.primary,
        page: scheme.primaryContainer.withValues(alpha: 0.5),
        // 원 안을 옅게 채워 그라데이션 바탕 위에서도 그림이 또렷하게
        fill: scheme.surface.withValues(alpha: 0.75),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter({required this.line, required this.page, required this.fill});

  final Color line;
  final Color page;
  final Color fill;

  // 양쪽 페이지 줄 색 (색 규칙의 파랑·초록·보라)
  static const _rowColors = [Colors.blue, Colors.green, Colors.purple];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s); // 0~1 좌표 → 화면 좌표

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 바깥 원 (안쪽을 옅게 채운 뒤 테두리)
    canvas.drawCircle(p(0.5, 0.5), s * 0.47, Paint()..color = fill);
    canvas.drawCircle(p(0.5, 0.5), s * 0.47, stroke);

    // 펼친 책: 가운데 등(0.5)에서 양쪽으로 살짝 휜 두 페이지
    Path pagePath(double side) {
      // side = -1 왼쪽, +1 오른쪽
      double x(double dx) => 0.5 + side * dx;
      return Path()
        ..moveTo(p(0.5, 0.47).dx, p(0.5, 0.47).dy)
        ..quadraticBezierTo(
          p(x(0.13), 0.41).dx,
          p(x(0.13), 0.41).dy,
          p(x(0.27), 0.45).dx,
          p(x(0.27), 0.45).dy,
        )
        ..lineTo(p(x(0.27), 0.73).dx, p(x(0.27), 0.73).dy)
        ..quadraticBezierTo(
          p(x(0.13), 0.69).dx,
          p(x(0.13), 0.69).dy,
          p(0.5, 0.75).dx,
          p(0.5, 0.75).dy,
        )
        ..close();
    }

    for (final side in [-1.0, 1.0]) {
      final path = pagePath(side);
      canvas.drawPath(path, Paint()..color = page);
      canvas.drawPath(path, stroke);
    }

    // 페이지의 글줄: 같은 높이의 줄은 양쪽이 같은 색
    final row = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _rowColors.length; i++) {
      final y = 0.53 + i * 0.065;
      row.color = _rowColors[i].withValues(alpha: 0.8);
      canvas.drawLine(p(0.29, y), p(0.44, y + 0.012), row);
      canvas.drawLine(p(0.56, y + 0.012), p(0.71, y), row);
    }

    // ⇄ 화살표: 위는 오른쪽, 아래는 왼쪽
    void arrow(double y, double from, double to) {
      canvas.drawLine(p(from, y), p(to, y), stroke);
      final dir = to > from ? -1.0 : 1.0; // 화살촉이 뒤로 벌어지는 방향
      canvas.drawLine(p(to, y), p(to + dir * 0.05, y - 0.04), stroke);
      canvas.drawLine(p(to, y), p(to + dir * 0.05, y + 0.04), stroke);
    }

    arrow(0.22, 0.37, 0.63);
    arrow(0.32, 0.63, 0.37);
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.line != line || old.page != page || old.fill != fill;
}
