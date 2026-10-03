"""복음서 병행·구약 인용 목록에 '생애 단계(section)'와 '순서(order)'를 붙입니다.

실행:  python tool/assign_order.py            (결과만 보기)
       python tool/assign_order.py --write    (JSON에 저장 + version 올림)

순서 기준: 마태복음의 순서.
  - 마태복음이 있는 묶음: 그 마태 본문의 위치
  - 없는 묶음(마가·누가·요한만): 같은 사건이 마태와 함께 나오는 병행 묶음을 '다리'로 삼아
    바로 앞 다리의 마태 위치 뒤에 놓습니다. (예: 막 1:21 → 막 1:16 = 마 4:18 뒤)
    다리와 같은 장이면 절 차이만큼 뒤로 놓아 순서를 살립니다.
    (구약 인용 묶음은 같은 구약을 인용했을 뿐 같은 사건이 아니므로 다리로 쓰지 않음)
  - 아래 OVERRIDE에 적은 묶음은 그 마태 위치로 직접 놓습니다.
단계(section)는 그 마태 위치로 정합니다 (SECTIONS 참고).
복음서가 없는 구약 인용 묶음(사도행전~요한계시록)은 복음서 묶음 뒤에 신약 책 순서대로 놓고,
단계 번호는 100 + 신약에서 몇 번째 책인지 (사도행전 105, 로마서 106, … 요한계시록 127).
사건을 추가한 뒤 다시 실행하면 순서가 새로 매겨집니다. (id는 바뀌지 않음)
"""
import json, os, sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [os.path.join(ROOT, 'assets', 'data', n) for n in ('synoptic_parallels.json', 'ot_quotations.json')]
WRITE = '--write' in sys.argv

# 단계: (번호, 이름, 이 마태 위치부터)  — 위치 = 장*1000 + 절
# (단계 이름은 lib/data/sections.dart에도 같은 번호로 있습니다)
SECTIONS = [
    (1, '탄생과 준비', 0),
    (2, '갈릴리 사역', 4012),          # 마 4:12
    (3, '예루살렘으로 가는 길', 16013),  # 마 16:13 베드로의 고백
    (4, '예루살렘 사역', 21001),        # 마 21:1 입성
    (5, '수난', 26001),                # 마 26:1
    (6, '부활', 28001),                # 마 28:1
]

# 자동 계산이 어색한 묶음은 마태 위치를 직접 지정
OVERRIDE = {
    1054: 2019,     # 눅 2:22 성전에서 드림 (탄생 직후)
    1057: 4017.5,   # 요 3:14 광야의 뱀 (니고데모, 초기 사역)
    1062: 26021,    # 요 13:18 내 떡을 먹는 자 (마지막 만찬)
}

GOSPEL_BRIDGES = ['MRK', 'LUK', 'JHN']

# 신약 27권 (lib/data/sections.dart의 bookSectionBase와 같은 규칙)
NT_BOOKS = ['MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH', 'PHP', 'COL',
            '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS', '1PE', '2PE', '1JN', '2JN',
            '3JN', 'JUD', 'REV']
BOOK_SECTION_BASE = 100
# 복음서 밖 묶음의 위치 = BOOK_POS × 신약 책 번호 + 장*1000 + 절 (마태 위치보다 항상 큼)
BOOK_POS = 1_000_000


def pos(r):
    return r['chapter'] * 1000 + r['verse_start']


def first_pos(group, book):
    ps = [pos(r) for r in group['refs'] if r['book'] == book and not r.get('doublet')]
    return min(ps) if ps else None


def main():
    datas = [json.load(open(f, encoding='utf-8')) for f in FILES]
    groups = [g for d in datas for g in d['groups']]

    # 다리: 책마다 (그 책 위치, 마태 위치) 목록
    bridges = {b: [] for b in GOSPEL_BRIDGES}
    for g in datas[0]['groups']:  # 복음서 병행 묶음만
        mt = first_pos(g, 'MAT')
        if mt is None:
            continue
        for b in GOSPEL_BRIDGES:
            p = first_pos(g, b)
            if p is not None:
                bridges[b].append((p, mt))
    for b in bridges:
        bridges[b].sort()

    def key(g):
        if g['id'] in OVERRIDE:
            return (OVERRIDE[g['id']], 0, 0)
        mt = first_pos(g, 'MAT')
        if mt is not None:
            return (mt, 0, 0)
        for rank, b in enumerate(GOSPEL_BRIDGES, start=1):
            p = first_pos(g, b)
            if p is None:
                continue
            before = [(bp, m) for bp, m in bridges[b] if bp <= p]
            if not before:
                return (0, rank, p)  # 앞에 다리가 없으면 맨 앞
            bp, m = before[-1]
            # 같은 장이면 절 차이만큼 뒤로, 아니면 바로 뒤
            same_chapter = bp // 1000 == p // 1000
            return (m + (p - bp if same_chapter else 0.5), rank, p)
        # 복음서가 없으면: 가장 앞선 신약 책의 첫 위치
        nt = [(NT_BOOKS.index(r['book']) + 1, pos(r)) for r in g['refs'] if r['book'] in NT_BOOKS]
        if nt:
            no, p = min(nt)
            return (no * BOOK_POS + p, 0, 0)
        return (0, 9, 0)

    def section(mt):
        if mt >= BOOK_POS:
            return BOOK_SECTION_BASE + int(mt // BOOK_POS)
        s = 1
        for no, _, start in SECTIONS:
            if mt >= start:
                s = no
        return s

    names = dict((no, name) for no, name, _ in SECTIONS)
    names.update((BOOK_SECTION_BASE + i, b) for i, b in enumerate(NT_BOOKS, start=1))
    for d, f in zip(datas, FILES):
        ordered = sorted(d['groups'], key=lambda g: (key(g), g['id']))
        print(f'\n===== {os.path.basename(f)} =====')
        last = None
        for i, g in enumerate(ordered, start=1):
            g['section'] = section(key(g)[0])
            g['order'] = i
            if g['section'] != last:
                print(f'\n[{g["section"]}] {names[g["section"]]}')
                last = g['section']
            refs = ', '.join(f"{r['book']} {r['chapter']}:{r['verse_start']}" for r in g['refs'] if not r.get('doublet'))
            print(f'  {i:3}. (id {g["id"]}) {g["title"]}  — {refs}')

        if WRITE:
            d['version'] += 1
            write_json(f, d)
            print(f'\n저장: {os.path.basename(f)} (version {d["version"]})')


def write_json(path, d):
    """원래 파일과 같은 모양(참조 한 줄씩)으로 저장. 목록 순서는 id 순서 유지."""
    out = ['{', f'  "version": {d["version"]},', '  "groups": [']
    gs = []
    for g in d['groups']:
        lines = ['    {',
                 f'      "id": {g["id"]},',
                 f'      "title": {json.dumps(g["title"], ensure_ascii=False)},',
                 f'      "section": {g["section"]},',
                 f'      "order": {g["order"]},',
                 '      "refs": [']
        rl = ['        { ' + ', '.join(f'"{k}": {json.dumps(v)}' for k, v in r.items()) + ' }'
              for r in g['refs']]
        lines.append(',\n'.join(rl))
        lines += ['      ]', '    }']
        gs.append('\n'.join(lines))
    out.append(',\n'.join(gs))
    out += ['  ]', '}', '']
    with open(path, 'w', encoding='utf-8', newline='\n') as fp:
        fp.write('\n'.join(out))


if __name__ == '__main__':
    main()
