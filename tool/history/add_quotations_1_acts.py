# ======================================================================
# [작업 기록] 구약 인용 1차: 사도행전 25개 (id 1067~1091)
# 이미 데이터에 반영되었습니다. 다시 실행하지 마세요 (묶음이 중복됨). 참고용입니다.
# ======================================================================
"""구약 인용 묶음을 ot_quotations.json에 추가합니다.

실행:  python tool/add_quotations.py            (검사만: 절마다 본문 출력)
       python tool/add_quotations.py --write    (저장, 그다음 assign_order.py --write 실행)

아래 Q에 이번에 넣을 묶음을 적습니다.
  - ("제목", [신약 참조..., 구약 참조...])       → 새 묶음 (id는 지금 마지막 id 다음부터)
  - ("+1070", [참조...])                        → 이미 있는 묶음 1070에 참조를 더함
  같은 책을 두 번 적으면 한 칸에 나뉜 본문으로 표시됩니다.
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
  ("그 직분을 타인이 취하게 하소서", ["ACT 1:20", "PSA 69:25", "PSA 109:8"]),
  ("내 영으로 모든 육체에게 부어 주리니", ["ACT 2:17-21", "JOL 2:28-32"]),
  ("내가 항상 내 앞에 계신 주를 뵈었음이여", ["ACT 2:25-28", "ACT 13:35", "PSA 16:8-11"]),
  ("주께서 내 주에게 말씀하시기를 (오순절 설교)", ["ACT 2:34-35", "PSA 110:1"]),
  ("나 같은 선지자 하나를 세울 것이니", ["ACT 3:22-23", "ACT 7:37", "DEU 18:15-19", "LEV 23:29"]),
  ("땅 위의 모든 족속이 너의 씨를 인하여 복을 받으리라", ["ACT 3:25", "GEN 12:3", "GEN 22:18"]),
  ("건축자의 버린 돌 (공회 앞에서)", ["ACT 4:11", "PSA 118:22"]),
  ("어찌하여 열방이 분노하며", ["ACT 4:25-26", "PSA 2:1-2"]),
  ("네 고향과 친척을 떠나", ["ACT 7:3", "GEN 12:1"]),
  ("그 씨가 다른 땅에 나그네 되리니", ["ACT 7:6-7", "GEN 15:13-14", "EXO 3:12"]),
  ("요셉을 알지 못하는 새 임금", ["ACT 7:18", "EXO 1:8"]),
  ("누가 너를 관원과 재판장으로 세웠느냐", ["ACT 7:27-28", "ACT 7:35", "EXO 2:14"]),
  ("네 발에 신을 벗으라", ["ACT 7:32-34", "EXO 3:5-10"]),
  ("우리를 인도할 신들을 만들라", ["ACT 7:40", "EXO 32:1", "EXO 32:23"]),
  ("몰록의 장막과 신 레판의 별", ["ACT 7:42-43", "AMO 5:25-27"]),
  ("하늘은 나의 보좌요 땅은 나의 발등상이니", ["ACT 7:49-50", "ISA 66:1-2"]),
  ("사지로 가는 양과 같이", ["ACT 8:32-33", "ISA 53:7-8"]),
  ("내 마음에 합한 사람 다윗", ["ACT 13:22", "1SA 13:14", "PSA 89:20"]),
  ("너는 내 아들이라 오늘 너를 낳았다", ["ACT 13:33", "PSA 2:7"]),
  ("다윗의 거룩하고 미쁜 은사", ["ACT 13:34", "ISA 55:3"]),
  ("보라 멸시하는 사람들아 놀라고 망하라", ["ACT 13:40-41", "HAB 1:5"]),
  ("이방의 빛을 삼아", ["ACT 13:47", "ISA 49:6"]),
  ("다윗의 무너진 장막을 다시 지으며", ["ACT 15:16-17", "AMO 9:11-12"]),
  ("너희 백성의 관원을 비방치 말라", ["ACT 23:5", "EXO 22:28"]),
  ("듣기는 들어도 깨닫지 못하리라 (로마에서)", ["ACT 28:26-27", "ISA 6:9-10"]),
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

    print(f'\n오류 {errors}개 / 묶음 {len(data["groups"])}개')
    if WRITE:
        if errors:
            print('오류가 있어 저장하지 않았습니다.')
            return
        write_json(QUOTES, data)
        print('저장했습니다. 이어서: python tool/assign_order.py --write')


if __name__ == '__main__':
    main()
