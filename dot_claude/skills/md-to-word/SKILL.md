---
name: md-to-word
description: Markdown ファイルを、図（SVG 含む）を埋め込んだ Word（.docx）にエクスポートする。Word は SVG 表示が不安定なため、SVG を PNG に変換してから pandoc で docx を生成し、画像を確実に埋め込む。「Word にして」「docx にして」「Word でエクスポート」「Word で出力」「この資料を Word に」「export to word」と言われたら使う。
argument-hint: <.mdファイルパス> [出力先.docx]
allowed-tools: Bash, Read
---

# md-to-word

Markdown を Word（.docx）にエクスポートするスキル。図を画像として確実に埋め込む。

## 前提

- `pandoc`（`brew install pandoc`）
- `rsvg-convert`（`brew install librsvg`）— SVG を PNG に変換するため

どちらも未インストールなら案内する。SVG 図を含まない Markdown なら `rsvg-convert` は不要。

## なぜ SVG を PNG にするか

pandoc は docx に SVG をそのまま埋め込むこともできるが、Word では SVG が表示されない・崩れることが多い。PNG に変換してから埋め込むと、どの Word でも確実に表示される（hitonowa-export と同じ方針）。

## 手順

引数: `$1` = 入力 Markdown のパス。`$2` = 出力 docx のパス（省略時は入力と同じディレクトリ・同名 `.docx`）。

1. パスを絶対パスに解決する。

   ```bash
   IN="<入力.md の絶対パス>"
   DIR="$(dirname "$IN")"
   OUT="<出力.docx の絶対パス>"        # 省略時: ${IN%.md}.docx
   WORK="$DIR/.md2docx"
   /bin/rm -rf "$WORK"; mkdir -p "$WORK/images"
   ```

2. 参照されている SVG を PNG に変換する（`-z 2` で2倍解像度）。

   ```bash
   for f in "$DIR"/images/*.svg; do
     [ -e "$f" ] || continue
     base="$(basename "${f%.svg}")"
     rsvg-convert -z 2 "$f" -o "$WORK/images/$base.png"
   done
   ```

   画像ディレクトリ名が `images/` 以外なら、その名前に合わせる。

3. Markdown の画像参照を `.svg` → `.png` に置換した一時ファイルを作る。

   ```bash
   sed 's/\.svg)/.png)/g' "$IN" > "$WORK/tmp.md"
   ```

4. pandoc で docx を生成する。`--resource-path` で変換済み PNG（`$WORK`）と元の画像（`$DIR`、ラスター画像用）の両方を解決する。

   ```bash
   ( cd "$WORK" && pandoc tmp.md -o "$OUT" \
       -f markdown-implicit_figures \
       --resource-path="$WORK:$DIR" )
   ```

   - `-f markdown-implicit_figures`: 画像の alt テキストがキャプションとして出るのを止める。

5. 一時ディレクトリを削除する。

   ```bash
   /bin/rm -rf "$WORK"
   ```

   注: 環境によって `rm` がフラグ付き呼び出しを弾くことがあるため、フルパス `/bin/rm` を使う。

6. 埋め込み確認と表示。

   ```bash
   unzip -l "$OUT" | grep -c "word/media/"   # 埋め込み画像数
   open "$OUT"                                 # 必要なら開く
   ```

## 注意

- docx はビルド成果物。リポジトリにはコミットしない。
- 体裁（フォント・見出しスタイル）を細かく整えたい場合は、pandoc の `--reference-doc=<テンプレ.docx>` を使う。
- 表・見出しは pandoc 既定の Word スタイルで出力される。
- ベクターのまま図を残したいなら Word ではなく PDF（`md-to-pdf`）を使う。
