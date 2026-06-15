---
name: md-to-pdf
description: Markdown ファイルを、図（SVG 含む）を埋め込んだ体裁の整った PDF にエクスポートする。pandoc で self-contained HTML 化し、Chrome ヘッドレスで PDF 印刷する。見出し階層を整え、図の alt テキストがキャプションとして出ないようにする。「PDF にして」「PDF 化」「PDF でエクスポート」「PDF で出力」「この資料を PDF に」「export to pdf」と言われたら使う。
argument-hint: <.mdファイルパス> [出力先.pdf]
allowed-tools: Bash, Read
---

# md-to-pdf

Markdown を PDF にエクスポートするスキル。`docs/` の検討メモなど、SVG 図や表を含む Markdown を、体裁を整えた PDF にする。

## 前提

- `pandoc`（`brew install pandoc`）
- Google Chrome（`/Applications/Google Chrome.app`）

どちらも未インストールなら案内する。

## 手順

引数: `$1` = 入力 Markdown のパス。`$2` = 出力 PDF のパス（省略時は入力と同じディレクトリ・同名 `.pdf`）。

1. パスを絶対パスに解決し、入力ファイルのあるディレクトリで作業する（相対画像パスを解決するため）。

2. pandoc で self-contained HTML を生成する。

   ```bash
   IN="<入力.md の絶対パス>"
   DIR="$(dirname "$IN")"
   OUT="<出力.pdf の絶対パス>"        # 省略時: ${IN%.md}.pdf
   HDR="$HOME/.claude/skills/md-to-pdf/assets/pandoc-header.html"
   TMP="$DIR/.md-to-pdf_tmp.html"

   cd "$DIR" && pandoc "$IN" -o "$TMP" \
     --standalone --embed-resources \
     -f markdown-implicit_figures \
     --include-in-header="$HDR"
   ```

   - `--embed-resources`: SVG/画像を base64 で HTML に埋め込む（self-contained 化）。
   - `-f markdown-implicit_figures`: 画像の alt テキストが `figcaption` として大きく出るのを止める。
   - `--include-in-header`: 見出し階層・表・画像幅を整える同梱 CSS（`assets/pandoc-header.html`）を適用する。

3. Chrome ヘッドレスで PDF 印刷する。

   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless=new --disable-gpu --no-pdf-header-footer \
     --print-to-pdf="$OUT" "file://$TMP"
   ```

4. 一時 HTML を削除する。

   ```bash
   rm -f "$TMP"
   ```

5. 生成した PDF を Read で 1〜2 ページ確認し（日本語・図・表が崩れていないか）、必要なら `open "$OUT"` で開く。

## 注意

- PDF はビルド成果物。リポジトリにはコミットしない（`git add` の対象に含めない）。
- frontmatter の `title` は表紙見出しとして中央に出る。本文先頭の `#` 見出しとは別物。
- 体裁を変えたいときは `assets/pandoc-header.html` の CSS を編集する。
- Windows/Linux では Chrome の実行パスを環境に合わせて変える。
