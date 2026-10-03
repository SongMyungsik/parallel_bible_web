# 병행 구절 대조 · 웹판 (parallel_bible_web)

복음서의 병행 본문과 신약이 인용한 구약 본문을 나란히 놓고, 같은 표현을 색으로 비교하는 앱의 **무료 웹판**.
사용자와는 한국어로 대화하고, 코드 주석도 쉬운 한국어로 씁니다.

## 이 프로젝트가 만들어진 이유와 결정 사항 (2026-10-03)
- 원본: `D:\flutter_apps\parallel_viewer` (GitHub `SongMyungsik/parallel_viewer`, 비공개). Play 스토어에 유료(인앱구매) 앱으로 출시 중.
  **원본은 건드리지 않음.** 이 폴더는 원본 커밋 `4a4c29f`를 `git archive`로 복사한 것(서명 키·build·git 기록 없음).
- 목적: **교회 안의 필요한 사람들(주로 교역자)** 에게 링크로 나눔. 안드로이드·아이폰 모두 브라우저로 사용, "홈 화면에 추가"로 앱처럼.
- 결정:
  1. **잠금 없이 전체 공개**: "전체 열기"(인앱구매)·코드 입력·자물쇠·안내 줄·표 보기에서 잠긴 줄 감추기를 모두 없앰.
  2. **Flutter 웹으로 빌드 → GitHub Pages**에 올림. **공개 저장소**로 해도 됨(사용자 동의, 개역한글은 저작권 만료).
  3. 폴더·저장소 이름 `parallel_bible_web` → 주소 예: `https://songmyungsik.github.io/parallel_bible_web/`
     (GitHub 계정 SongMyungsik, `gh` 로그인되어 있음. 저장소 만들기·올리기는 사용자 확인 후).
- 유료 Play 앱과 내용이 겹치므로, 링크는 교회 안에서만 나눈다는 전제(사용자가 아들과 상의).

## 진행 상황 (2026-10-03)
- ✅ 1 정리: `promo/`·`android/`·`koreanbible.csv` 삭제(windows는 확인용으로 남김). 앱 이름은 "병행 구절 대조" 그대로("웹판" 표시 안 함).
- ✅ 2 잠금 제거: 관련 파일·테스트 삭제, `in_app_purchase` 삭제.
- ✅ 3 웹 동작(방법 A): `lib/data/passage_data.dart`(병행·인용, 예전 SQL과 같은 모양의 줄을 메모리에서 만듦),
  `lib/data/memory_bible_text_source.dart`(본문), 설정은 `shared_preferences`. sqflite·path·dart:io 없음. 패키지 이름 `parallel_bible_web`.
- ✅ 4 웹 꾸미기: `web/index.html`(불러오는 화면, `web/flutter_bootstrap.js`에서 지움)·`manifest.json`, 아이콘은 `python tool/make_app_icon.py`.
  한글 글꼴은 Flutter 웹이 자동으로 Noto Sans KR을 내려받음(따로 넣지 않음).
- ⏳ 5 배포: `.github/workflows/deploy.yml` 준비됨(main에 올리면 빌드→Pages). 저장소 만들기·올리기는 사용자 확인 후.
  저장소 설정 Pages → Source: GitHub Actions.
- ⏳ 6 폰 확인·사용 안내문.
- git: 로컬 저장소만 있음(`git init`). 줄 끝 LF(`core.autocrlf false`).

## 작업 계획 (처음 세운 계획, 위 진행 상황 참고)
1. **정리**: Play·Android 출시 전용 자료 빼기 — `promo/store/`, `promo/screenshots/`, 홍보 포스터 등은 필요 없으면 지우기(사용자에게 물어보기).
   `koreanbible.csv`(예전 신약 원본, 이미 반영됨)는 지워도 됨. `android/`·`windows/` 폴더는 남겨 둬도 되고(개발 중 Windows로 확인용),
   웹만 쓸 거면 나중에 정리. 앱 이름에 "웹판" 표시를 넣을지 사용자에게 물어보기.
2. **잠금 제거** — 관련 파일:
   `lib/data/free_items.dart`, `lib/state/purchase_state.dart`, `lib/ui/unlock_sheet.dart`(통째로 삭제 후보),
   `lib/pages/{main_shell,home_page,bible_page,parallel_list_page,quotation_list_page,settings_page}.dart`, `lib/main.dart`,
   `lib/data/ref_format.dart`(`formatBooksSummary`는 잠긴 항목용), `test/unlock_test.dart`.
   `ensureOpen(...)` 호출은 그냥 열기로, 목록·칩의 자물쇠와 `UnlockBanner`·`HiddenRowsNote` 제거, 검색은 구절까지 다시 허용,
   설정 탭의 "전체 열기" 카드·개발용 스위치 제거. `pubspec.yaml`에서 `in_app_purchase` 삭제.
3. **웹에서 동작하게** (가장 큰 일):
   - `sqflite`는 웹에서 안 됨. 쓰는 곳: `lib/data/{bible_importer,db_bible_text_source,parallel_importer}.dart`,
     `lib/state/{app_settings,parallel_state}.dart`, `lib/main.dart`.
   - 방법 A(권장): DB를 없애고 **JSON을 메모리에 올려 쓰기**(데이터가 읽기 전용이라 충분). 설정·읽던 위치·최근 본 것은
     `shared_preferences`(웹은 localStorage)로. `BibleTextSource` 인터페이스가 있으니 메모리용 구현을 하나 더 만들면 화면 코드는 그대로.
   - 방법 B: `sqflite_common_ffi_web`(wasm SQLite, IndexedDB 저장). 코드 변경은 적지만 설정 파일·worker 파일 배치가 필요.
   - `dart:io`(`Platform.isWindows` 등)는 웹에서 오류 → `kIsWeb` / `defaultTargetPlatform`으로 바꾸기. 쓰는 곳: `lib/main.dart`, `purchase_state.dart`(삭제 예정).
   - 성경 본문 JSON이 약 7.7MB → 첫 실행 때 내려받음. 시작 화면에 진행 표시 유지. (필요하면 나중에 줄이기: 공백 없는 JSON, 필요한 칸만)
4. **웹 꾸미기**: `web/` 폴더가 아직 없음 → `flutter create --platforms=web .` 로 만든 뒤 `web/index.html`·`manifest.json`
   (앱 이름 "병행 구절 대조", 아이콘 `assets/icon/app_icon.png`로 192·512 만들기, 테마 색), 한글 글꼴 확인.
   GitHub Pages는 하위 경로라 `flutter build web --base-href /parallel_bible_web/`.
5. **배포**: 새 **공개** 저장소 `parallel_bible_web` → GitHub Actions로 `flutter build web` 후 Pages에 올리는 작업 흐름
   (또는 `build/web`을 `gh-pages` 브랜치로). 저장소 만들기·공개 전에 사용자 확인.
6. **확인**: `flutter analyze`, `flutter test`(잠금 테스트는 삭제·수정), `flutter build web`, 로컬에서 `flutter run -d chrome`.
   폰(안드로이드 크롬·아이폰 사파리)에서 열어 보는 것은 사용자에게 부탁. 사용 안내문(링크 + "홈 화면에 추가" 방법) 만들어 주기.

## 실행·확인
```bash
flutter analyze            # 경고 0개 유지
flutter test               # test/ 아래 단위·위젯 테스트
flutter run -d chrome      # 웹으로 실행해 보기
flutter build web --base-href /parallel_bible_web/
```
- 화면 자동 클릭(마우스 제어)으로 확인하지 말 것. 사용자가 같은 PC를 쓰고 있어 다른 창을 누른 적이 있음.
  화면 배치는 위젯 테스트(폰 폭 360px에서 넘침 없는지)로 확인하고, 실제 화면은 사용자에게 확인 요청.

---
아래는 원본 앱의 설명서에서 가져온 부분입니다. (잠금·결제 관련 내용은 이 프로젝트에서 없앨 대상)

## 데이터 (assets/data)

| 파일 | 내용 |
|---|---|
| `koreanbible.json` | 성경 본문 **개역한글** 전체 66권 31,102절. 형식 `{no, book(한글 이름), chapter, paragraph, korean}` |
| `synoptic_parallels.json` | 복음서 병행 138개 (id 1~138) |
| `ot_quotations.json` | 신약의 구약 인용 204개: 복음서 66개 (id 1001~1066), 사도행전 25개 (1067~1091), 바울 서신 67개 (1092~1158), 히브리서 23개 (1159~1181), 공동 서신·계시록 23개 (1182~1204) |

- 개역개정은 저작권 문제로 쓰지 않음. 개역한글만 사용.
- 본문 가공(읽을 때 `lib/data/memory_bible_text_source.dart`에서):
  - `(없음)…` 표시 → `[없음] …` (사본에 따라 없는 절, 예: 마 17:21). 13절의 본문은 예전 신약 파일 `koreanbible.csv`에서 채움.
  - 시편 1절 앞 `[다윗의 시…]` 표제 → 소제목(heading)으로 분리.
  - 개역한글은 소제목이 없고 괄호가 본문의 일부이므로 괄호 소제목 떼기는 꺼 둠(`_extractHeadings = false`).
  - 책 이름 별칭: `애가`, `요한1서`~`요한3서`도 인식 (`lib/data/ref_format.dart`).
  - 원본 파일에서 스바냐 장 번호 오류(2·3장이 1·2장으로 적힘)를 고쳐 둠.
- 묶음 JSON 형식:
  ```json
  { "id": 1, "title": "예수님의 세례", "section": 1, "order": 3,
    "refs": [ { "book": "MAT", "chapter": 3, "verse_start": 13, "verse_end": 17 }, ... ] }
  ```
  - 장이 넘어가면 `"chapter_end"`. 같은 책을 두 번 적으면 **나뉜 본문**(한 칸에 `⋯`로 이어 표시).
  - `"doublet": true` = 같은 복음서 안의 **반복 말씀**(칸 아래 "다른 곳의 같은 말씀").
  - 병행은 서로 다른 복음서 2권 이상, 인용은 신약·구약이 모두 있어야 함(가져올 때 검사).
  - `section`: 1~6 = 예수님 생애 단계(복음서), 105~127 = 100 + 신약 책 번호(사도행전 105 … 요한계시록 127). `lib/data/sections.dart`.
  - 복음서 밖에서 같은 구약을 인용하면 서신끼리는 한 묶음(예: 롬 4:3·갈 3:6 → 창 15:6). 복음서 묶음(사건)에는 섞지 않음.
  - id는 바꾸지 않음(홈의 "이어 보기", 성경 칩이 id로 연결됨).

### ⚠ 데이터를 고칠 때 반드시
- 웹판은 DB 없이 켤 때마다 JSON을 읽으므로 고치면 바로 반영됨. `"version"`은 도구(assign_order.py)가 올리는 대로 둠(원본 앱과 맞추기용).
- 본문 가공은 `lib/data/memory_bible_text_source.dart`의 `parseBible`.
- 사건·인용을 추가한 뒤 `python tool/assign_order.py --write` → 생애 단계(section)와 순서(order)를 다시 매기고 version도 올려 줌.
  인자 없이 실행하면 단계별 목록만 출력(검토용).
- 새 절 범위는 성경 본문과 대조해 검사 후 넣을 것 (`tool/history/`의 스크립트 방식 참고: 시작·끝 절 본문을 출력해 제목과 맞는지 확인).
- 구약 인용 추가: `tool/add_quotations.py`의 `Q`에 적고 실행(검사) → `--write` → `assign_order.py --write`.
  `("+id", [...])` 참조 더하기, `("=id", [옛, 새])` 참조 바꾸기, `("~id", [제목])` 제목 바꾸기. 저장할 때 신약 참조를 구약 앞으로 정리(칸 순서 = 참조 순서). 넣은 뒤 `tool/history/`에 복사하고 `Q`를 비움.
- `assign_order.py --write`는 두 JSON의 version을 모두 올리므로, 바뀌지 않은 파일은 `git checkout`으로 되돌림.

## 코드 구조 (lib/)

- `main.dart`: 시작 화면에서 데이터 준비(설정 → 병행·인용 → 성경 본문을 메모리에) → [시작하기]를 누르면 `MainShell`.
- `pages/start_page.dart`: 앱 켤 때 시작 화면(사용자 스케치대로: 그림 · 이름 · 소개 · 개역한글 · [시작하기] · 버전).
  그림 `StartEmblem`은 코드로 그림(원 + 펼친 책 + ⇄, 앱 색상 따름). 준비 중에는 버튼 자리에 진행 표시. 버전은 `settings_page.dart`의 `appVersion`.
- `pages/main_shell.dart`: 하단 네비 5탭(홈/성경/복음서병행/구약인용/설정). **탭마다 Navigator**를 따로 둠 → 대조 화면도 하단 네비 위에 열림.
  복음서병행·구약인용 탭을 누르면 항상 목록으로. 뒤로 가기: 탭 안 화면 닫기 → 홈 → 종료.
- `pages/parallel_compare_page.dart`: 대조 화면. 칸 = 책. `quotation: true`면 신약↔구약만 비교. 칸 머리 📖 → 성경 탭에서 문맥 보기.
- `pages/bible_page.dart`: 성경 읽기(구약/신약, 책·장 드롭다운, 좌우 장 이동). 병행·인용 시작 절에 칩 → 대조 화면. 대조 화면에서 넘어오면 범위 강조.
- `pages/parallel_list_page.dart`, `quotation_list_page.dart`: 생애 단계 소제목 + 검색 + `[목록 | 표]` 대조표. 인용은 `신약 순서 | 구약 순서` 전환(신약 순서 = 복음서는 생애 단계, 사도행전부터는 책별 소제목).
- `pages/home_page.dart`: 카드 → 직전 내용(읽던 장, 마지막으로 본 대조 화면).
- `pages/settings_page.dart`: `앱 정보 | 설정` 탭. 화면 모드(시스템/라이트/다크), 앱 색상 5가지(인디고·초록·와인·갈색·먹색, 예전 색 이름은 `fromName`에서 같은 계열로 바꿈).
- `logic/word_matcher.dart`: **연속 두 단어**가 서로 다른 책에 나오면 공통 표현. 한국어 조사 차이는 앞부분 일치로 허용. `[없음]` 같은 대괄호 표시는 비교 안 함.
- `data/passage_data.dart`: JSON → 메모리(묶음 줄·구절 줄, 검사 포함). `PassageCollection.parallel / quotation`.
- `data/memory_bible_text_source.dart`: 성경 본문 JSON → 메모리 (`BibleTextSource` 구현).
- `state/`: `ParallelState`(목록), `AppSettings`(설정·최근 본 것, `shared_preferences` = 웹은 localStorage), `AppNavigation`(대조 화면 → 성경 이동 요청).
- `ui/`: `gospel_colors.dart`(색 규칙), `grouped_list.dart`(소제목·검색), `synopsis_table.dart`(대조표). 

## 색 규칙
- 몇 복음서 공통인지: **네 = 보라, 세 = 초록, 두 = 파랑** (`ui/gospel_colors.dart` 한 곳에서 정의).
  본문 글자 배경은 옅게(alpha 0.22), 목록 동그라미는 진하게(0.6).
- 인용 화면: 신약·구약 같은 표현 = 파랑. 대조표 글자: 신약 파랑, 구약 갈색.
- 앱바·하단 네비 글자는 흰색 → 앱 색상은 흰 글자 대비 4.5 이상인 진한 톤만.

## 도구 (tool/)
- `assign_order.py`: 생애 단계·순서 매기기 (위 참고). 마태 순서 기준, 없으면 병행 묶음을 다리로 위치 계산, 어색한 곳은 `OVERRIDE`.
- `make_app_icon.py`: 앱 아이콘(펼친 성경 양쪽 페이지의 같은 줄을 같은 색으로) → assets, web(favicon·192·512·maskable·apple-touch-icon), Windows ico 생성.
- `history/`: 이미 반영된 데이터 생성 스크립트(다시 실행 금지, 참고용).

