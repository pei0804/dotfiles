#!/usr/bin/env python3
"""契約書 docx の検査用エクスポート。標準ライブラリのみで動く。

出力するもの
- 本文テキスト（変更履歴を反映した状態。挿入テキストは含み、削除テキストは含まない）
- 変更履歴（挿入・削除）の残存件数
- コメントの一覧（著者・日付・本文）
- 条マップ（「第◯条」見出しと行番号。版間の条番号ずれの追跡に使う）
- 表記の注意箇所（半角の鉤括弧・句点・中黒、半角数字の条項参照）

使い方
  python3 extract_docx.py <file.docx>                  # レポートを標準出力へ
  python3 extract_docx.py <file.docx> --text-out FILE  # 本文テキストを保存（版間 diff 用）
"""
import re
import sys
import zipfile
from xml.etree import ElementTree as ET

W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


def para_text(p):
    s = ''
    for n in p.iter():
        if n.tag == W + 't':          # 通常テキスト（w:ins 配下も含む）
            s += n.text or ''
        elif n.tag == W + 'tab':
            s += '\t'
        elif n.tag == W + 'br':
            s += '\n'
        # w:delText（削除された文字列）は拾わない = 変更履歴を反映した見た目になる
    return s


def body_lines(doc):
    body = doc.find(W + 'body')
    out = []
    for el in body:
        if el.tag == W + 'p':
            out.append(para_text(el))
        elif el.tag == W + 'tbl':
            for tr in el.findall(W + 'tr'):
                cells = [' '.join(para_text(p) for p in tc.findall(W + 'p'))
                         for tc in tr.findall(W + 'tc')]
                out.append(' | '.join(cells))
    return out


def highlights(doc):
    """蛍光ペン（w:highlight）が付いた箇所。相手方の「要確認」マーカーとして残っていることがある。"""
    found = []
    for p in doc.iter(W + 'p'):
        marked = ''
        for r in p.iter(W + 'r'):  # w:ins（変更履歴の挿入）配下の run も拾う
            rpr = r.find(W + 'rPr')
            if rpr is not None and rpr.find(W + 'highlight') is not None:
                marked += ''.join(t.text or '' for t in r.findall(W + 't'))
        if marked:
            found.append((marked, para_text(p)))
    return found


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    path = args[0]
    text_out = None
    if '--text-out' in args:
        text_out = args[args.index('--text-out') + 1]

    z = zipfile.ZipFile(path)
    doc = ET.fromstring(z.read('word/document.xml'))
    lines = body_lines(doc)

    ins = len(doc.findall('.//' + W + 'ins'))
    dels = len(doc.findall('.//' + W + 'del'))

    comments = []
    if 'word/comments.xml' in z.namelist():
        c = ET.fromstring(z.read('word/comments.xml'))
        for cm in c.findall(W + 'comment'):
            author = cm.get(W + 'author', '')
            date = cm.get(W + 'date', '')
            text = ''.join(t.text or '' for t in cm.iter(W + 't'))
            comments.append((author, date, text))

    marks = highlights(doc)

    print(f'file: {path}')
    clean = ins + dels == 0 and not comments and not marks
    print(f'変更履歴: 挿入 {ins} 件 / 削除 {dels} 件')
    print(f'コメント: {len(comments)} 件')
    print(f'ハイライト: {len(marks)} 箇所')
    for marked, context in marks:
        print(f'  - 「{marked}」 … {context.strip()[:60]}')
    print(f'クリーン判定: {"クリーン（締結版にできる状態）" if clean else "残存あり（締結版にする前に反映・削除が必要）"}')
    for a, d, t in comments:
        print(f'  - {a} {d}: {t}')

    print('\n条マップ:')
    for i, line in enumerate(lines, 1):
        m = re.match(r'^\s*(第[0-9０-９一二三四五六七八九十百]+条)\s*(（[^）]*）)?', line)
        # 見出しとみなす条件: 条名の直後に（見出し）が付くか、行自体が短い。
        # 「第８条に定める提供物件の…」のような文中参照を拾わないため。
        if m and (m.group(2) or len(line.strip()) <= 20):
            print(f'  {i:4d}  {m.group(1)}{m.group(2) or ""}')

    print('\n表記の注意箇所:')
    hits = 0
    for i, line in enumerate(lines, 1):
        for pat, label in [(r'[｢｣｡･]', '半角記号'),
                           (r'第[0-9]+条|第[0-9]+項|第[0-9]+号', '条項参照が半角数字')]:
            if re.search(pat, line):
                hits += 1
                print(f'  {i:4d}  [{label}] {line.strip()[:60]}')
                break
    if hits == 0:
        print('  なし')

    if text_out:
        with open(text_out, 'w') as f:
            f.write('\n'.join(lines) + '\n')
        print(f'\n本文テキスト: {text_out} に保存（{len(lines)} 行）')


if __name__ == '__main__':
    main()
