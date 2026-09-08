---
name: image-convert
description: 画像ファイルの形式を変換する。PNG → JPEG、JPEG → PNG、HEIC → PDF の 3 つに対応し、透過の塗り潰しと EXIF の回転タグを取りこぼさないようにする。「PNG を JPG にして」「JPG を PNG に変換」「HEIC を PDF にして」「この写真を PDF に」「画像の形式を変えて」と言われたら使う。リサイズ・トリミング・複数枚の結合は対象外。
argument-hint: <入力画像パス> [出力パス]
allowed-tools: Bash, Read
---

# image-convert

画像 1 枚の形式を変換するスキル。macOS 標準の `sips` を軸に、HEIC → PDF でだけ `img2pdf` を併用する。

## 前提

- `sips`
    - macOS 標準のコマンドで、追加インストールは要らない
- `img2pdf`（`pip install img2pdf`）
    - HEIC → PDF でだけ使う。依存として Pillow が入るので、JPEG → PNG ではその Pillow を使う

`img2pdf` が入っていなければインストールを案内する。

## 共通の進め方

1. 入力を絶対パスに解決する。
2. 出力先が省略されたら、入力と同じディレクトリに同名で拡張子だけ変えたパスを使う。
3. 出力先に既存ファイルがあれば、上書きしてよいか確認する。
4. 変換後に `sips -g pixelWidth -g pixelHeight` かファイルサイズで結果を確認し、パスと一緒に報告する。

一時ファイルはスクラッチパッドに置き、変換が終わったら消す。

## PNG → JPEG

```bash
sips -s format jpeg -s formatOptions 90 "$IN" --out "$OUT"
```

`formatOptions` は 0 から 100 の品質で、指定がなければ 90 を使う。

透過ピクセルは白で塗り潰される。背景を白以外にしたい場合はこのスキルの範囲外なので、その旨を伝える。

## JPEG → PNG

```bash
python3 - "$IN" "$OUT" <<'PY'
import sys
from PIL import Image, ImageOps
ImageOps.exif_transpose(Image.open(sys.argv[1])).save(sys.argv[2])
PY
```

ここだけ `sips` を使わない。`sips -s format png` は EXIF の回転タグを引き継がず、PNG 側にも回転を持たせる場所がないため、縦位置で撮った写真が横倒しの PNG になる。回転タグ 6 を持つ 200x100 の JPEG を変換すると、`sips` は 200x100 の PNG を出し、`ImageOps.exif_transpose` は回転をピクセルに焼き込んで 100x200 の PNG を出す。

## HEIC → PDF

```bash
TMP="<スクラッチパッドの絶対パス>/image-convert_tmp.jpg"
sips -s format jpeg -s formatOptions 90 "$IN" --out "$TMP"
img2pdf "$TMP" -o "$OUT"
command rm -f "$TMP"
```

`img2pdf` は HEIC を読めない（`cannot identify image file` で落ちる）ため、`sips` で JPEG に落としてから渡す。

一時ファイルの削除に `command` を付けるのは、`rm` が `trash` にエイリアスされていて `-f` を受け取れないため。

`img2pdf` は JPEG を再エンコードせずそのまま埋め込むので、画質が落ちるのは `sips` の JPEG 化 1 回だけになる。回転タグは `img2pdf` の既定の `--rotation auto` が読み取り、PDF のページに `/Rotate` として書き込む。

## 注意

- 変換結果はビルド成果物なので、リポジトリにコミットしない
- 対応するのは形式変換だけ。リサイズ・圧縮率の追い込み・トリミング・複数枚を 1 つの PDF にまとめる処理は含めない
- macOS 以外では `sips` がないため、このスキルは動かない
