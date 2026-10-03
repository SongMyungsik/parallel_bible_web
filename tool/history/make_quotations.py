# ======================================================================
# [작업 기록] 구약 인용 목록 만들기 (ot_quotations.json, id 1001~1066)
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
FIRST_ID = 1001  # 병행 사건(1~)과 겹치지 않게

# (제목, [신약 참조들..., 구약 참조들...])  같은 책을 두 번 적으면 한 칸에 나뉜 본문으로 표시
Q = [
  ("처녀가 잉태하여 (임마누엘)", ["MAT 1:22-23", "ISA 7:14"]),
  ("유대 땅 베들레헴아", ["MAT 2:5-6", "JHN 7:42", "MIC 5:2"]),
  ("애굽에서 내 아들을 불렀다", ["MAT 2:15", "HOS 11:1"]),
  ("라마에서 슬퍼하는 소리", ["MAT 2:17-18", "JER 31:15"]),
  ("광야에서 외치는 자의 소리", ["MAT 3:3", "MRK 1:3", "LUK 3:4-6", "JHN 1:23", "ISA 40:3-5"]),
  ("내 사자를 네 앞에 보내노니", ["MAT 11:10", "MRK 1:2", "LUK 7:27", "MAL 3:1"]),
  ("사람이 떡으로만 살 것이 아니요", ["MAT 4:4", "LUK 4:4", "DEU 8:3"]),
  ("저희가 손으로 너를 받들어", ["MAT 4:6", "LUK 4:10-11", "PSA 91:11-12"]),
  ("주 너의 하나님을 시험하지 말라", ["MAT 4:7", "LUK 4:12", "DEU 6:16"]),
  ("주 너의 하나님께 경배하라", ["MAT 4:10", "LUK 4:8", "DEU 6:13"]),
  ("스불론과 납달리 땅, 흑암에 앉은 백성", ["MAT 4:14-16", "ISA 9:1-2"]),
  ("주의 성령이 내게 임하셨으니", ["LUK 4:18-19", "ISA 61:1-2"]),
  ("살인하지 말라", ["MAT 5:21", "EXO 20:13"]),
  ("간음하지 말라", ["MAT 5:27", "EXO 20:14"]),
  ("이혼 증서를 줄 것이라", ["MAT 5:31", "MAT 19:7", "MRK 10:4", "DEU 24:1"]),
  ("헛 맹세를 하지 말라", ["MAT 5:33", "LEV 19:12"]),
  ("눈은 눈으로, 이는 이로", ["MAT 5:38", "EXO 21:24"]),
  ("네 이웃을 사랑하라 (산상 설교)", ["MAT 5:43", "LEV 19:18"]),
  ("우리 연약한 것을 친히 담당하시고", ["MAT 8:17", "ISA 53:4"]),
  ("나는 긍휼을 원하고 제사를 원치 아니하노라", ["MAT 9:13", "MAT 12:7", "HOS 6:6"]),
  ("사람의 원수가 자기 집안 식구리라", ["MAT 10:35-36", "LUK 12:53", "MIC 7:6"]),
  ("보라 나의 택한 종", ["MAT 12:17-21", "ISA 42:1-4"]),
  ("요나가 밤낮 사흘을 큰 물고기 뱃속에", ["MAT 12:40", "JON 1:17"]),
  ("듣기는 들어도 깨닫지 못하리라", ["MAT 13:14-15", "MRK 4:12", "LUK 8:10", "JHN 12:39-40", "ISA 6:9-10"]),
  ("내가 입을 열어 비유로 말하고", ["MAT 13:35", "PSA 78:2"]),
  ("부모를 공경하라", ["MAT 15:4", "MRK 7:10", "EXO 20:12", "EXO 21:17"]),
  ("입술로는 나를 존경하되", ["MAT 15:8-9", "MRK 7:6-7", "ISA 29:13"]),
  ("엘리야가 먼저 와서", ["MAT 17:10-11", "MRK 9:11-12", "LUK 1:17", "MAL 4:5-6"]),
  ("두세 증인의 입으로", ["MAT 18:16", "DEU 19:15"]),
  ("남자와 여자로 지으시고 둘이 한 몸이 될지니라", ["MAT 19:4-5", "MRK 10:6-8", "GEN 1:27", "GEN 2:24"]),
  ("계명을 네가 아나니", ["MAT 19:18-19", "MRK 10:19", "LUK 18:20", "EXO 20:12-16"]),
  ("시온 딸에게 이르라, 네 왕이 나귀를 타고", ["MAT 21:4-5", "JHN 12:14-15", "ZEC 9:9"]),
  ("찬송하리로다 주의 이름으로 오는 이여", ["MAT 21:9", "MRK 11:9-10", "LUK 19:38", "JHN 12:13", "PSA 118:25-26"]),
  ("주의 이름으로 오는 이여 (예루살렘 탄식)", ["MAT 23:39", "LUK 13:35", "PSA 118:26"]),
  ("내 집은 기도하는 집", ["MAT 21:13", "MRK 11:17", "LUK 19:46", "ISA 56:7", "JER 7:11"]),
  ("어린 아기와 젖먹이의 입에서", ["MAT 21:16", "PSA 8:2"]),
  ("건축자의 버린 돌", ["MAT 21:42", "MRK 12:10-11", "LUK 20:17", "PSA 118:22-23"]),
  ("형이 자식이 없이 죽으면", ["MAT 22:24", "MRK 12:19", "LUK 20:28", "DEU 25:5"]),
  ("나는 아브라함의 하나님이요", ["MAT 22:32", "MRK 12:26", "LUK 20:37", "EXO 3:6"]),
  ("마음을 다하여 하나님을 사랑하라", ["MAT 22:37-39", "MRK 12:29-31", "LUK 10:27", "DEU 6:4-5", "LEV 19:18"]),
  ("주께서 내 주께 이르시되", ["MAT 22:44", "MRK 12:36", "LUK 20:42-43", "PSA 110:1"]),
  ("멸망의 가증한 것", ["MAT 24:15", "MRK 13:14", "DAN 9:27", "DAN 12:11"]),
  ("해가 어두워지며 별들이 떨어지며", ["MAT 24:29", "MRK 13:24-25", "ISA 13:10", "ISA 34:4"]),
  ("인자가 구름을 타고 오는 것", ["MAT 24:30", "MRK 13:26", "LUK 21:27", "DAN 7:13"]),
  ("권능의 우편에 앉은 것과 하늘 구름을 타고", ["MAT 26:64", "MRK 14:62", "LUK 22:69", "PSA 110:1", "DAN 7:13"]),
  ("목자를 치리니 양들이 흩어지리라", ["MAT 26:31", "MRK 14:27", "ZEC 13:7"]),
  ("불법자의 동류로 여김을 받았다", ["LUK 22:37", "ISA 53:12"]),
  ("은 삼십", ["MAT 27:9-10", "ZEC 11:12-13"]),
  ("내 옷을 나누며", ["MAT 27:35", "MRK 15:24", "LUK 23:34", "JHN 19:23-24", "PSA 22:18"]),
  ("하나님을 신뢰하니 구원하실지라", ["MAT 27:43", "PSA 22:8"]),
  ("내 하나님이여 어찌하여 나를 버리셨나이까", ["MAT 27:46", "MRK 15:34", "PSA 22:1"]),
  ("내 영혼을 아버지 손에 부탁하나이다", ["LUK 23:46", "PSA 31:5"]),
  ("산들아 우리 위에 무너지라", ["LUK 23:30", "HOS 10:8"]),
  ("첫 태에 처음 난 남자", ["LUK 2:22-24", "EXO 13:2", "LEV 12:8"]),
  ("그 불도 꺼지지 아니하느니라", ["MRK 9:48", "ISA 66:24"]),
  ("주의 전을 사모하는 열심", ["JHN 2:17", "PSA 69:9"]),
  ("모세가 광야에서 뱀을 든 것 같이", ["JHN 3:14", "NUM 21:8-9"]),
  ("하늘에서 떡을 주어 먹게 하였다", ["JHN 6:31", "PSA 78:24"]),
  ("저희가 다 하나님의 가르치심을 받으리라", ["JHN 6:45", "ISA 54:13"]),
  ("내가 너희를 신이라 하였노라", ["JHN 10:34", "PSA 82:6"]),
  ("우리에게 들은 바를 누가 믿었나이까", ["JHN 12:38", "ISA 53:1"]),
  ("내 떡을 먹는 자가 발꿈치를 들었다", ["JHN 13:18", "PSA 41:9"]),
  ("저희가 연고 없이 나를 미워하였다", ["JHN 15:25", "PSA 69:4"]),
  ("내가 목마르다", ["JHN 19:28-29", "PSA 69:21"]),
  ("그 뼈가 하나도 꺾이지 아니하리라", ["JHN 19:36", "EXO 12:46", "PSA 34:20"]),
  ("저희가 그 찌른 자를 보리라", ["JHN 19:37", "ZEC 12:10"]),
]


def parse(s):
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
    return r, (book, ch, vs), (book, che, ve)


# 코드 → 파일의 책 이름
NAMES = {
 'GEN':'창세기','EXO':'출애굽기','LEV':'레위기','NUM':'민수기','DEU':'신명기','PSA':'시편',
 'ISA':'이사야','JER':'예레미야','DAN':'다니엘','HOS':'호세아','JON':'요나','MIC':'미가',
 'ZEC':'스가랴','MAL':'말라기','MAT':'마태복음','MRK':'마가복음','LUK':'누가복음','JHN':'요한복음',
}
bible = {}
for v in json.load(open(ROOT + 'koreanbible.json', encoding='utf-8')):
    bible[(v['book'], v['chapter'], v['paragraph'])] = v['korean']

errors = 0
groups = []
for i, (title, refs) in enumerate(Q):
    gid = FIRST_ID + i
    print(f'[{gid}] {title}')
    parsed = []
    for s in refs:
        r, start, end = parse(s)
        for key in (start, end):
            if (NAMES[key[0]], key[1], key[2]) not in bible:
                print('   !! 없는 절:', s, key)
                errors += 1
        # 짧은 범위는 전체 본문, 긴 범위는 앞뒤만
        texts = []
        c, v = start[1], start[2]
        while (c, v) <= (end[1], end[2]) and (NAMES[r['book']], c, v) in bible:
            texts.append(bible[(NAMES[r['book']], c, v)])
            v += 1
            if (NAMES[r['book']], c, v) not in bible and c < end[1]:
                c, v = c + 1, 1
        t = ' / '.join(texts)
        print(f'   {s:16} | {t[:150]}')
        parsed.append(r)
    groups.append({"id": gid, "title": title, "refs": parsed})

print('오류', errors, '/ 묶음', len(groups))

if WRITE and errors == 0:
    out = ['{', '  "version": 1,', '  "groups": [']
    gs = []
    for g in groups:
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
    open(ROOT + 'ot_quotations.json', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print('저장 완료')
