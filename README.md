# 병행 구절 대조 · 웹판

복음서의 병행 본문과 신약이 인용한 구약 본문을 나란히 놓고, 같은 표현을 색으로 비교합니다. (개역한글)

- 주소: https://songmyungsik.github.io/parallel_bible_web/
- 안드로이드(크롬)·아이폰(사파리)에서 열고 "홈 화면에 추가"하면 앱처럼 쓸 수 있습니다.

## 개발
```bash
flutter analyze
flutter test
flutter run -d chrome
flutter build web --base-href /parallel_bible_web/
```
`main` 브랜치에 올리면 GitHub Actions(`.github/workflows/deploy.yml`)가 빌드해서 GitHub Pages에 올립니다.
