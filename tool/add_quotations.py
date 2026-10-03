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
    # 예: ("이방의 빛을 삼아", ["ACT 13:47", "ISA 49:6"]),
    # 지난 차례들: tool/history/add_quotations_*.py
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
