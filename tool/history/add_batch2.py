# ======================================================================
# [작업 기록] 복음서 병행 2차 추가 (id 99~138) + 기존 사건에 요한복음 병행 추가
# 이미 데이터(assets/data)에 반영이 끝난 스크립트입니다. 다시 실행하지 마세요.
#  - 다시 실행하면 사건이 중복되거나, JSON의 section·order(생애 단계·순서)가 지워집니다.
#  - 새 사건을 추가할 때 "절 범위를 성경 본문과 대조해 검사하는 방법"의 참고용입니다.
#  - 인자 없이 실행하면 검사 결과만 출력합니다(--write를 붙여야 저장).
# ======================================================================
import os
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'assets', 'data') + os.sep
WRITE = '--write' in sys.argv

# 참조 표기: "BOOK ch:vs-ve", "BOOK ch:vs-ch2:ve", 앞에 "*"를 붙이면 반복 말씀(doublet)
# 같은 책을 연달아 적으면 나뉜 본문(한 칸에 이어서 표시)

NEW = [
  # --- 세 복음서 / 두 복음서 ---
  ("전도 여행을 떠나심", ["MRK 1:35-39", "LUK 4:42-44"]),
  ("많은 무리를 고치심", ["MAT 12:15-21", "MRK 3:7-12", "LUK 6:17-19"]),
  ("성령을 모독하는 죄", ["MAT 12:31-32", "MRK 3:28-30", "LUK 12:10"]),
  ("비유로 말씀하시는 이유", ["MAT 13:10-17", "MRK 4:10-12", "LUK 8:9-10"]),
  ("비유로 가르치심", ["MAT 13:34-35", "MRK 4:33-34"]),
  ("게네사렛에서 병자들을 고치심", ["MAT 14:34-36", "MRK 6:53-56"]),
  ("표적을 구하는 세대", ["MAT 16:1-4", "MRK 8:11-13"]),
  ("바리새인의 누룩", ["MAT 16:5-12", "MRK 8:14-21", "LUK 12:1"]),
  ("엘리야에 관한 질문", ["MAT 17:9-13", "MRK 9:9-13"]),
  ("작은 자를 실족하게 하는 자", ["MAT 18:6-9", "MRK 9:42-48", "LUK 17:1-2"]),
  ("맛을 잃은 소금", ["MAT 5:13", "MRK 9:49-50", "LUK 14:34-35"]),
  ("서기관들을 삼가라", ["MAT 23:1-12", "MRK 12:38-40", "LUK 20:45-47"]),
  ("깨어 있으라", ["MAT 24:42-44", "MRK 13:33-37", "LUK 12:39-40"]),
  ("부활하신 주님의 사명", ["MAT 28:16-20", "MRK 16:14-18", "LUK 24:44-49", "JHN 20:19-23"]),
  ("하늘로 올라가심", ["MRK 16:19-20", "LUK 24:50-53"]),
  # --- 마태·누가 공통 (Q 자료) ---
  ("예수 그리스도의 족보", ["MAT 1:1-17", "LUK 3:23-38"]),
  ("등경 위의 등불", ["MAT 5:14-16", "LUK 11:33"]),
  ("율법의 일점일획", ["MAT 5:17-18", "LUK 16:17"]),
  ("고발하는 자와 화해하라", ["MAT 5:25-26", "LUK 12:57-59"]),
  ("음행한 이유 없이 아내를 버리는 자", ["MAT 5:31-32", "LUK 16:18"]),
  ("보물을 하늘에 쌓아 두라", ["MAT 6:19-21", "LUK 12:33-34"]),
  ("눈은 몸의 등불", ["MAT 6:22-23", "LUK 11:34-36"]),
  ("두 주인을 섬길 수 없다", ["MAT 6:24", "LUK 16:13"]),
  ("좁은 문", ["MAT 7:13-14", "LUK 13:23-24"]),
  ("추수할 일꾼과 칠십 인 파송", ["MAT 9:37-38", "MAT 10:7-16", "LUK 10:1-12"]),
  ("제자가 선생보다 높지 못하다", ["MAT 10:24-25", "LUK 6:40"]),
  ("두려워하지 말라", ["MAT 10:26-33", "LUK 12:2-9"]),
  ("화평이 아니요 검을 주러 왔노라", ["MAT 10:34-36", "LUK 12:51-53"]),
  ("나보다 부모를 더 사랑하는 자", ["MAT 10:37-38", "LUK 14:26-27"]),
  ("고라신과 벳새다에 대한 책망", ["MAT 11:20-24", "LUK 10:13-15"]),
  ("아버지께 감사하심", ["MAT 11:25-27", "LUK 10:21-22"]),
  ("너희 눈은 복이 있도다", ["MAT 13:16-17", "LUK 10:23-24"]),
  ("더러운 귀신이 돌아옴", ["MAT 12:43-45", "LUK 11:24-26"]),
  ("시대를 분별하라", ["MAT 16:2-3", "LUK 12:54-56"]),
  ("겨자씨 한 알만한 믿음", ["MAT 17:20", "LUK 17:6"]),
  ("형제를 용서하라", ["MAT 18:15", "MAT 18:21-22", "LUK 17:3-4"]),
  ("바리새인과 서기관에게 화 있을진저", ["MAT 23:13-36", "LUK 11:37-52"]),
  ("번개 같은 인자의 날", ["MAT 24:26-28", "LUK 17:23-24", "LUK 17:37"]),
  ("노아의 때와 같이", ["MAT 24:37-41", "LUK 17:26-35"]),
  ("충성된 종과 악한 종", ["MAT 24:45-51", "LUK 12:42-46"]),
]

# 기존 묶음에 참조 덧붙이기 (id → 참조들). 같은 책 참조 바로 뒤, 없으면 맨 뒤에 넣음
ADD = {
  # 요한복음 병행
  1: ["JHN 1:29-34"],                 # 예수님의 세례
  7: ["JHN 6:1-15"],                  # 오천 명을 먹이심
  8: ["JHN 6:66-69"],                 # 베드로의 신앙 고백
  11: ["JHN 1:19-28"],                # 세례 요한의 전파
  33: ["JHN 6:16-21"],                # 물 위를 걸으심
  49: ["JHN 12:12-19"],               # 예루살렘에 들어가심
  50: ["JHN 2:13-22"],                # 성전을 깨끗하게 하심
  63: ["JHN 11:47-53"],               # 예수님을 죽이려는 모의
  64: ["JHN 12:1-8"],                 # 베다니에서 향유를 부음
  67: ["JHN 13:21-30"],               # 배반할 자를 예고하심
  69: ["JHN 13:36-38"],               # 베드로의 부인을 예고하심
  71: ["JHN 18:1-11"],                # 잡히심
  72: ["JHN 18:19-24"],               # 공회 앞에서 심문받으심
  73: ["JHN 18:15-18", "JHN 18:25-27"],  # 베드로가 예수님을 부인함 (나뉜 본문)
  74: ["JHN 18:28-38"],               # 빌라도 앞에 서심
  75: ["JHN 18:39-40", "JHN 19:4-16"],   # 바라바와 사형 선고 (나뉜 본문)
  76: ["JHN 19:1-3"],                 # 군인들이 희롱함
  77: ["JHN 19:17-27"],               # 십자가에 못 박히심
  78: ["JHN 19:28-30"],               # 예수님의 죽으심
  79: ["JHN 19:38-42"],               # 무덤에 장사되심
  80: ["JHN 20:1-10"],                # 빈 무덤
  89: ["JHN 4:46-54"],                # 백부장의 종을 고치심 (왕의 신하의 아들)
  # 공관복음 보완
  47: ["LUK 22:24-27"],               # 야고보와 요한의 요청 ↔ 누가의 "누가 크냐" 논쟁
  87: ["*MAT 12:33-35"],              # 열매로 나무를 앎 (마태 안의 반복 말씀)
}

NAMES = {'MAT': '마태복음', 'MRK': '마가복음', 'LUK': '누가복음', 'JHN': '요한복음'}


def parse(s):
    doublet = s.startswith('*')
    book, rng = s.lstrip('*').split(' ')
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
    if doublet:
        r["doublet"] = True
    return r, (book, ch, vs), (book, che, ve)


bible = {}
for v in json.load(open(ROOT + 'koreanbible.json', encoding='utf-8')):
    bible.setdefault((v['book'], v['chapter'], v['paragraph']), v['korean'])

errors = 0


def check(s):
    global errors
    r, start, end = parse(s)
    for key in (start, end):
        if (NAMES[key[0]], key[1], key[2]) not in bible:
            print('   !! 없는 절:', s, key)
            errors += 1
    t0 = bible.get((NAMES[start[0]], start[1], start[2]), '')[:32]
    t1 = bible.get((NAMES[end[0]], end[1], end[2]), '')[-22:]
    print(f'   {s:18} | {t0} … {t1}')
    return r


data = json.load(open(ROOT + 'synoptic_parallels.json', encoding='utf-8'))
by_id = {g['id']: g for g in data['groups']}
titles = {g['title'] for g in data['groups']}

for gid, refs in ADD.items():
    g = by_id[gid]
    print(f'[{gid}] {g["title"]} (+)')
    for s in refs:
        r = check(s)
        same = [i for i, x in enumerate(g['refs']) if x['book'] == r['book']]
        g['refs'].insert(same[-1] + 1 if same else len(g['refs']), r)

next_id = max(by_id) + 1
for title, refs in NEW:
    if title in titles:
        print('중복 제목:', title)
        errors += 1
    print(f'[{next_id}] {title}')
    data['groups'].append({"id": next_id, "title": title, "refs": [check(s) for s in refs]})
    next_id += 1

print('오류', errors, '/ 전체', len(data['groups']))

if WRITE and errors == 0:
    data['version'] += 1
    out = ['{', f'  "version": {data["version"]},', '  "groups": [']
    gs = []
    for g in data['groups']:
        lines = ['    {', f'      "id": {g["id"]},',
                 f'      "title": {json.dumps(g["title"], ensure_ascii=False)},',
                 '      "refs": [']
        rl = ['        { ' + ', '.join(f'"{k}": {json.dumps(v)}' for k, v in r.items()) + ' }'
              for r in g['refs']]
        lines.append(',\n'.join(rl))
        lines += ['      ]', '    }']
        gs.append('\n'.join(lines))
    out.append(',\n'.join(gs))
    out += ['  ]', '}', '']
    open(ROOT + 'synoptic_parallels.json', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('저장 완료, version =', data['version'])
