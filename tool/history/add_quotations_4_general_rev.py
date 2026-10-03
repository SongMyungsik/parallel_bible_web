# ======================================================================
# [작업 기록] 구약 인용 4차: 공동 서신·계시록 23개 (id 1182~1204) + 기존 6묶음에 더함, 1073 제목 바꿈
# 이미 데이터에 반영되었습니다. 다시 실행하지 마세요 (묶음이 중복됨). 참고용입니다.
# ======================================================================
"""구약 인용 묶음을 ot_quotations.json에 추가합니다.

실행:  python tool/add_quotations.py            (검사만: 절마다 본문 출력)
       python tool/add_quotations.py --write    (저장, 그다음 assign_order.py --write 실행)

아래 Q에 이번에 넣을 묶음을 적습니다.
  - ("제목", [신약 참조..., 구약 참조...])       → 새 묶음 (id는 지금 마지막 id 다음부터)
  - ("+1070", [참조...])                        → 이미 있는 묶음 1070에 참조를 더함
  - ("=1092", ["HAB 2:4", "HAB 2:3-4"])         → 묶음 1092의 참조 HAB 2:4를 HAB 2:3-4로 바꿈
  - ("~1070", ["새 제목"])                       → 묶음 1070의 제목을 바꿈 (id는 그대로)
  같은 책을 두 번 적으면 한 칸에 나뉜 본문으로 표시됩니다.
대조 화면의 칸은 참조 순서대로 나오므로, 저장할 때 모든 묶음에서 신약 참조를 구약 앞으로 옮깁니다.
검사: 없는 절, 신약·구약이 모두 있는지, 이미 다른 묶음에 있는 신약 참조(겹치면 경고).
저장할 때 section·order는 0으로 두므로 반드시 assign_order.py --write를 이어서 실행하세요.
한 차례 넣은 뒤에는 이 파일을 tool/history/에 복사해 두고 Q를 비웁니다.
"""
import json, os, sys

TOOL = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOL)
# 파일 모양을 똑같이 저장 (불러오면서 한글 출력 설정도 함께 됨)
from assign_order import write_json  # noqa: E402

DATA = os.path.join(os.path.dirname(TOOL), 'assets', 'data')
QUOTES = os.path.join(DATA, 'ot_quotations.json')
WRITE = '--write' in sys.argv

Q = [
  # 야고보서
  ("+1124", ["JAS 2:8", "JAS 2:11"]),
  ("+1096", ["JAS 2:23"]),
  ("교만한 자를 물리치시고 겸손한 자에게 은혜를 주신다", ["JAS 4:6", "1PE 5:5", "PRO 3:34"]),
  ("사랑은 허다한 죄를 덮느니라", ["JAS 5:20", "1PE 4:8", "PRO 10:12"]),
  # 베드로전서
  ("내가 거룩하니 너희도 거룩할지어다", ["1PE 1:16", "LEV 11:44", "LEV 19:2"]),
  ("모든 육체는 풀과 같고", ["1PE 1:24-25", "ISA 40:6-8"]),
  ("+1109", ["1PE 2:6", "1PE 2:8"]),
  ("+1073", ["1PE 2:7"]),
  ("~1073", ["건축자들의 버린 돌이 머릿돌이 되었다"]),
  ("택하신 족속이요 왕 같은 제사장들이요", ["1PE 2:9", "EXO 19:5-6", "ISA 43:20-21"]),
  ("+1106", ["1PE 2:10"]),
  ("저는 죄를 범치 아니하시고 그 입에 궤사도 없으시며", ["1PE 2:22-25", "ISA 53:5-9"]),
  ("생명을 사랑하고 좋은 날 보기를 원하는 자는", ["1PE 3:10-12", "PSA 34:12-16"]),
  ("저희의 두려워함을 두려워 말며", ["1PE 3:14-15", "ISA 8:12-13"]),
  ("의인이 겨우 구원을 얻으면", ["1PE 4:18", "PRO 11:31"]),
  # 베드로후서
  ("개가 그 토하였던 것에 돌아가고", ["2PE 2:22", "PRO 26:11"]),
  ("천 년이 하루 같다", ["2PE 3:8", "PSA 90:4"]),
  ("새 하늘과 새 땅", ["2PE 3:13", "REV 21:1", "ISA 65:17"]),
  # 요한계시록 (인용 표시는 없지만 표현을 그대로 가져온 곳)
  ("구름을 타고 오시리라, 찌른 자들도 볼 터이요", ["REV 1:7", "DAN 7:13", "ZEC 12:10"]),
  ("나는 처음이요 나중이라", ["REV 1:17", "REV 22:13", "ISA 44:6"]),
  ("철장을 가지고 저희를 다스려 질그릇 깨뜨리는 것과 같이", ["REV 2:27", "REV 12:5", "REV 19:15", "PSA 2:9"]),
  ("다윗의 열쇠를 가지신 이", ["REV 3:7", "ISA 22:22"]),
  ("거룩하다 거룩하다 거룩하다", ["REV 4:8", "ISA 6:3"]),
  ("산과 바위에게 이르되 우리 위에 떨어져", ["REV 6:16", "HOS 10:8"]),
  ("다시 주리지도 아니하며, 모든 눈물을 씻기시리라", ["REV 7:16-17", "REV 21:4", "ISA 25:8", "ISA 49:10"]),
  ("무너졌도다 무너졌도다 큰 성 바벨론이여", ["REV 14:8", "REV 18:2", "ISA 21:9"]),
  ("만국이 와서 주께 경배하리이다", ["REV 15:3-4", "PSA 86:9", "JER 10:7"]),
  ("내 백성아 거기서 나와", ["REV 18:4", "JER 51:45"]),
  ("+1145", ["REV 21:3", "REV 21:7"]),
  ("해나 달의 비췸이 쓸 데 없으니", ["REV 21:23", "ISA 60:19"]),
]

# 66권 코드 (성경 순서, lib/data/ref_format.dart와 같음)
CODES = ('GEN EXO LEV NUM DEU JOS JDG RUT 1SA 2SA 1KI 2KI 1CH 2CH EZR NEH EST JOB PSA PRO ECC SNG '
         'ISA JER LAM EZK DAN HOS JOL AMO OBA JON MIC NAM HAB ZEP HAG ZEC MAL '
         'MAT MRK LUK JHN ACT ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM '
         'HEB JAS 1PE 2PE 1JN 2JN 3JN JUD REV').split()
OT = set(CODES[:39])


def parse(s):
    """"ACT 2:17-21", "PSA 16:8", "EXO 3:5-4:2" → JSON 참조, 시작 (장, 절), 끝 (장, 절)"""
    book, rng = s.split(' ')
    a, *b = rng.split('-')
    ch, vs = map(int, a.split(':'))
    if not b:
        che, ve = ch, vs
    elif ':' in b[0]:
        che, ve = map(int, b[0].split(':'))
    else:
        che, ve = ch, int(b[0])
    r = {"book": book, "chapter": ch, "verse_start": vs}
    if che != ch:
        r["chapter_end"] = che
    r["verse_end"] = ve
    return r, (ch, vs), (che, ve)


def load_bible():
    """{(코드, 장, 절): 본문}  — 파일의 책 이름은 나오는 순서대로 코드에 맞춤"""
    verses = json.load(open(os.path.join(DATA, 'koreanbible.json'), encoding='utf-8'))
    order = list(dict.fromkeys(v['book'] for v in verses))
    assert len(order) == 66, len(order)
    code = dict(zip(order, CODES))
    return {(code[v['book']], v['chapter'], v['paragraph']): v['korean'] for v in verses}


def texts(bible, book, start, end):
    out, (c, v) = [], start
    while (c, v) <= end:
        if (book, c, v) in bible:
            out.append(f'{v} {bible[(book, c, v)]}')
            v += 1
        elif (book, c + 1, 1) in bible and c < end[0]:
            c, v = c + 1, 1
        else:
            break
    return out


def main():
    bible = load_bible()
    data = json.load(open(QUOTES, encoding='utf-8'))
    by_id = {g['id']: g for g in data['groups']}
    next_id = max(by_id) + 1

    # 이미 들어 있는 신약 참조 (겹침 경고용)
    used = {}
    for g in data['groups']:
        for r in g['refs']:
            if r['book'] not in OT:
                used.setdefault(r['book'], []).append((r, g['id']))

    errors = 0
    for title, refs in Q:
        if title.startswith('~'):
            gid = int(title[1:])
            print(f'\n[{gid}의 제목 바꿈] {by_id[gid]["title"]} → {refs[0]}')
            by_id[gid]['title'] = refs[0]
            continue
        if title.startswith('='):
            gid = int(title[1:])
            old, new = (parse(s)[0] for s in refs)
            print(f'\n[{gid}의 참조 바꿈] {by_id[gid]["title"]}: {refs[0]} → {refs[1]}')
            group_refs = by_id[gid]['refs']
            if old not in group_refs:
                print('   !! 바꿀 참조가 묶음에 없음')
                errors += 1
                continue
            _, start, end = parse(refs[1])
            for c, v in (start, end):
                if (new['book'], c, v) not in bible:
                    print('   !! 없는 절:', refs[1], (c, v))
                    errors += 1
            for t in texts(bible, new['book'], start, end):
                print(f'        {t}')
            group_refs[group_refs.index(old)] = new
            continue
        if title.startswith('+'):
            gid = int(title[1:])
            print(f'\n[{gid}에 더함] {by_id[gid]["title"]}')
        else:
            gid = next_id
            next_id += 1
            print(f'\n[{gid}] {title}')
        parsed = []
        for s in refs:
            r, start, end = parse(s)
            if r['book'] not in CODES:
                print('   !! 모르는 책:', s)
                errors += 1
                continue
            for c, v in (start, end):
                if (r['book'], c, v) not in bible:
                    print('   !! 없는 절:', s, (c, v))
                    errors += 1
            for u, uid in used.get(r['book'], []):
                a = (u['chapter'], u['verse_start'])
                b = (u.get('chapter_end', u['chapter']), u['verse_end'])
                if start <= b and a <= end and uid != gid:
                    print(f'   ?? {s}: 이미 묶음 {uid}에 있음 ({by_id[uid]["title"]})')
            print(f'   {s}')
            for t in texts(bible, r['book'], start, end):
                print(f'        {t}')
            parsed.append(r)

        if title.startswith('+'):
            by_id[gid]['refs'] += parsed
            books = [r['book'] for r in by_id[gid]['refs']]
        else:
            by_id[gid] = {"id": gid, "title": title, "section": 0, "order": 0, "refs": parsed}
            data['groups'].append(by_id[gid])
            books = [r['book'] for r in parsed]
        if not any(b in OT for b in books) or all(b in OT for b in books):
            print('   !! 신약과 구약이 모두 있어야 함')
            errors += 1

    # 신약 참조를 구약 앞으로 (같은 편 안에서는 적은 순서 그대로)
    for g in data['groups']:
        moved = sorted(g['refs'], key=lambda r: r['book'] in OT)
        if moved != g['refs']:
            print(f'순서 정리: [{g["id"]}] {g["title"]}')
            g['refs'] = moved

    print(f'\n오류 {errors}개 / 묶음 {len(data["groups"])}개')
    if WRITE:
        if errors:
            print('오류가 있어 저장하지 않았습니다.')
            return
        write_json(QUOTES, data)
        print('저장했습니다. 이어서: python tool/assign_order.py --write')


if __name__ == '__main__':
    main()
