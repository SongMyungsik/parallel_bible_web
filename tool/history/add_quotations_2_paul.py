# ======================================================================
# [작업 기록] 구약 인용 2차: 로마서·바울 서신 68개 (id 1092~1159) + 1068·1072에 참조 더함
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
  # 로마서
  ("의인은 믿음으로 말미암아 살리라", ["ROM 1:17", "GAL 3:11", "HAB 2:4"]),
  ("하나님의 이름이 너희로 인하여 모독을 받는도다", ["ROM 2:24", "ISA 52:5"]),
  ("주께서 주의 말씀에 의롭다 함을 얻으시고", ["ROM 3:4", "PSA 51:4"]),
  ("의인은 없나니 하나도 없으며", ["ROM 3:10-18", "PSA 14:1-3", "PSA 5:9", "PSA 140:3", "PSA 10:7", "PSA 36:1", "ISA 59:7-8"]),
  ("아브라함이 하나님을 믿으매 의로 여기신 바 되었느니라", ["ROM 4:3", "ROM 4:22", "GAL 3:6", "GEN 15:6"]),
  ("그 불법을 사하심을 받고", ["ROM 4:7-8", "PSA 32:1-2"]),
  ("내가 너를 많은 민족의 조상으로 세웠다", ["ROM 4:17-18", "GEN 15:5", "GEN 17:5"]),
  ("탐내지 말라", ["ROM 7:7", "EXO 20:17"]),
  ("종일 주를 위하여 죽임을 당케 되며", ["ROM 8:36", "PSA 44:22"]),
  ("이삭으로부터 난 자라야 네 씨라", ["ROM 9:7", "GEN 21:12"]),
  ("명년 이 때에 사라에게 아들이 있으리라", ["ROM 9:9", "GEN 18:10", "GEN 18:14"]),
  ("큰 자가 어린 자를 섬기리라", ["ROM 9:12-13", "GEN 25:23", "MAL 1:2-3"]),
  ("긍휼히 여길 자를 긍휼히 여기고", ["ROM 9:15", "EXO 33:19"]),
  ("이 일을 위하여 너를 세웠으니", ["ROM 9:17", "EXO 9:16"]),
  ("내 백성 아닌 자를 내 백성이라", ["ROM 9:25-26", "HOS 1:10", "HOS 2:23"]),
  ("남은 자만 구원을 얻으리니", ["ROM 9:27-28", "ISA 10:22-23"]),
  ("만군의 주께서 우리에게 씨를 남겨 두지 아니하셨더면", ["ROM 9:29", "ISA 1:9"]),
  ("부딪히는 돌과 거치는 반석을 시온에 두노니", ["ROM 9:33", "ROM 10:11", "ISA 8:14", "ISA 28:16"]),
  ("의를 행하는 사람은 그 의로 살리라", ["ROM 10:5", "GAL 3:12", "LEV 18:5"]),
  ("말씀이 네게 가까워 네 입에 있으며", ["ROM 10:6-8", "DEU 30:12-14"]),
  ("+1068", ["ROM 10:13"]),
  ("좋은 소식을 전하는 자들의 발이여", ["ROM 10:15", "ISA 52:7"]),
  ("주여 우리의 전하는 바를 누가 믿었나이까 (로마서)", ["ROM 10:16", "ISA 53:1"]),
  ("그 소리가 온 땅에 퍼졌고", ["ROM 10:18", "PSA 19:4"]),
  ("백성 아닌 자로써 너희를 시기나게 하며", ["ROM 10:19", "DEU 32:21"]),
  ("구하지 아니하는 자들에게 찾은 바 되고", ["ROM 10:20-21", "ISA 65:1-2"]),
  ("바알에게 무릎을 꿇지 아니한 사람 칠천", ["ROM 11:3-4", "1KI 19:10", "1KI 19:18"]),
  ("혼미한 심령과 보지 못할 눈", ["ROM 11:8", "DEU 29:4", "ISA 29:10"]),
  ("저희 밥상이 올무와 덫이 되게 하옵시고", ["ROM 11:9-10", "PSA 69:22-23"]),
  ("구원자가 시온에서 오사", ["ROM 11:26-27", "ISA 59:20-21", "ISA 27:9"]),
  ("누가 주의 마음을 알았느뇨", ["ROM 11:34-35", "1CO 2:16", "JOB 41:11", "ISA 40:13"]),
  ("원수 갚는 것이 내게 있으니", ["ROM 12:19", "DEU 32:35"]),
  ("네 원수가 주리거든 먹이고", ["ROM 12:20", "PRO 25:21-22"]),
  ("네 이웃을 네 자신과 같이 사랑하라", ["ROM 13:9", "GAL 5:14", "EXO 20:13-15", "EXO 20:17", "LEV 19:18"]),
  ("모든 무릎이 내게 꿇을 것이요", ["ROM 14:11", "PHP 2:10-11", "ISA 45:23"]),
  ("주를 비방하는 자들의 비방이 내게 미쳤나이다", ["ROM 15:3", "PSA 69:9"]),
  ("열방 중에서 주께 감사하고", ["ROM 15:9-12", "PSA 18:49", "DEU 32:43", "PSA 117:1", "ISA 11:10"]),
  ("주의 소식을 받지 못한 자들이 볼 것이요", ["ROM 15:21", "ISA 52:15"]),
  # 고린도전서
  ("지혜 있는 자들의 지혜를 멸하고", ["1CO 1:19", "ISA 29:14"]),
  ("자랑하는 자는 주 안에서 자랑하라", ["1CO 1:31", "2CO 10:17", "JER 9:24"]),
  ("눈으로 보지 못하고 귀로도 듣지 못하고", ["1CO 2:9", "ISA 64:4"]),
  ("지혜 있는 자들로 자기 궤휼에 빠지게 하시는 이", ["1CO 3:19-20", "JOB 5:13", "PSA 94:11"]),
  ("이 악한 사람은 너희 중에서 내어 쫓으라", ["1CO 5:13", "DEU 17:7"]),
  ("둘이 한 육체가 된다 (서신)", ["1CO 6:16", "EPH 5:31", "GEN 2:24"]),
  ("곡식을 밟아 떠는 소의 입에 망을 씌우지 말라", ["1CO 9:9", "1TI 5:18", "DEU 25:4"]),
  ("백성이 앉아서 먹고 마시며 일어나서 뛰논다", ["1CO 10:7", "EXO 32:6"]),
  ("땅과 거기 충만한 것이 주의 것임이니라", ["1CO 10:26", "PSA 24:1"]),
  ("다른 방언을 말하는 자와 다른 입술로", ["1CO 14:21", "ISA 28:11-12"]),
  ("만물을 저의 발 아래 두셨다", ["1CO 15:27", "PSA 8:6"]),
  ("내일 죽을 터이니 먹고 마시자", ["1CO 15:32", "ISA 22:13"]),
  ("첫 사람 아담은 산 영이 되었다", ["1CO 15:45", "GEN 2:7"]),
  ("사망이 이김의 삼킨 바 되리라", ["1CO 15:54-55", "ISA 25:8", "HOS 13:14"]),
  # 고린도후서
  ("내가 믿는 고로 말하였다", ["2CO 4:13", "PSA 116:10"]),
  ("은혜 베풀 때에 너를 듣고", ["2CO 6:2", "ISA 49:8"]),
  ("나는 저희 하나님이 되고 저희는 나의 백성이 되리라", ["2CO 6:16-18", "LEV 26:11-12", "2SA 7:14", "ISA 52:11"]),
  ("많이 거둔 자도 남지 아니하였고", ["2CO 8:15", "EXO 16:18"]),
  ("저가 흩어 가난한 자들에게 주었으니", ["2CO 9:9", "PSA 112:9"]),
  ("두세 증인의 입으로 (서신)", ["2CO 13:1", "1TI 5:19", "DEU 19:15"]),
  # 갈라디아서 (3:6, 3:11, 3:12, 5:14는 위 로마서 묶음에)
  ("+1072", ["GAL 3:8"]),
  ("율법 책에 기록된 대로 항상 행하지 아니하는 자는 저주 아래", ["GAL 3:10", "DEU 27:26"]),
  ("나무에 달린 자마다 저주 아래 있는 자라", ["GAL 3:13", "DEU 21:23"]),
  ("오직 하나를 가리켜 네 자손이라", ["GAL 3:16", "GEN 12:7", "GEN 13:15"]),
  ("잉태치 못한 자여 즐거워하라", ["GAL 4:27", "ISA 54:1"]),
  ("계집종과 그 아들을 내어 쫓으라", ["GAL 4:30", "GEN 21:10"]),
  # 에베소서·디모데후서
  ("위로 올라가실 때에 사로잡힌 자를 사로잡고", ["EPH 4:8", "PSA 68:18"]),
  ("각각 그 이웃으로 더불어 참된 것을 말하라", ["EPH 4:25", "ZEC 8:16"]),
  ("분을 내어도 죄를 짓지 말며", ["EPH 4:26", "PSA 4:4"]),
  ("네 아버지와 어머니를 공경하라 (서신)", ["EPH 6:2-3", "EXO 20:12", "DEU 5:16"]),
  ("주께서 자기 백성을 아신다", ["2TI 2:19", "NUM 16:5"]),
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
