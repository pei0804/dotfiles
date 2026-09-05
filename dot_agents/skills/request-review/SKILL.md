---
description: |
  PR のレビュー依頼を投げる前に、PR タイトル・本文と実際の diff の整合性を整えてから
  draft を外し、レビュアーをアサインするスキル。draft で着手して実装が転がった結果、
  タイトル・本文が古いままレビューに回るのを防ぐのが目的。
  「レビュー投げて」「レビューお願い」「レビュー依頼して」「ready for review」
  「draft 外して」「PR#123 にレビュアー指定して」「○○さんにレビュー依頼」
  などと言われたときに使う。
  注意: PR 新規作成は pr スキル、レビューコメントへの返信は review-response スキル、
  マージは merge-pr スキルを使う。このスキルは「draft → ready for review への遷移」専用。
argument-hint: "<pr-number-or-url> [reviewer]"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Read
---

# レビュー依頼

draft PR を「レビューに投げられる状態」に整えてから ready for review にし、
レビュアーをアサインする。

## なぜこのスキルがあるか

PR は draft で作って iterate するので、最初に書いた title / body と最終的な diff が
ズレることが多い。そのままレビュー依頼を投げるとレビュアーが間違ったメンタルモデルで
diff を読みはじめてしまい、レビューの精度が落ちる。

このスキルは「依頼を投げる」という宣言点で **必ず** 整合性を確認し、ズレていれば
直してから依頼する。レビュアーに渡す前の最後の身だしなみチェックだと思えばいい。

## インプット

- PR 番号 または URL（必須）
  - 引数未指定の場合、まず `gh pr view --json number,url` でカレントブランチに
    紐づく PR を探す。見つからなければユーザーに確認する
- reviewer（任意）
  - 引数で渡されなかった場合、「誰にレビュー依頼しますか？」と確認する
  - 既にレビュー依頼済みの reviewer を再依頼する場合もありうる（後述）

## 手順

### 1. PR の現状を把握する

以下を取得する:

```bash
gh pr view <number> --json number,title,body,isDraft,headRefName,baseRefName,url,reviewRequests,reviews,mergeable,commits
gh pr diff <number>
```

把握すべきこと:

- タイトル
- 本文
- draft かどうか
- 既にレビュー依頼されている reviewer 一覧（`reviewRequests`）
- 既にレビュー済みの人（`reviews`）
- diff の中身（追加/削除されたファイル、機能、振る舞い）
- コミットの並び（`commits` の messages から、PR が辿った歴史を読む）

### 2. タイトル・本文と diff の整合性をチェックする

整合性チェックの観点は以下。

#### 2a. タイトルチェック

- diff の中身を一行で要約したとき、現タイトルと食い違っていないか
- スコープがズレていないか（例: 「○○の修正」と書いてあるが実際には refactor も含む）
- 70 文字以内に収まっているか

#### 2b. 本文チェック

pr スキルが定めている本文テンプレート（背景 / 実現する機能 / レビュー観点）に従って、
以下を確認する:

- `Closes #N` が冒頭にあるか。なければ親 Issue を特定して追加する
- `## 背景`: 解こうとしている問題が今の diff で解こうとしているものと一致するか
- `## 実現する機能`: 書かれている機能が実際に diff で実装されているか / 逆に diff に
  あって本文に書かれていない機能がないか
- `## レビュー観点`: 観点が今の実装に対して妥当か。古い設計案への観点が残っていないか

##### アンチパターン（紛れ込んでいたら直す）

pr スキルと同じ。本文に以下が混入していたら除去を提案する:

- 変更ファイルの箇条書き（「新規: xxx.py / 更新: yyy.sql」）
- 関数名・クラス名・行番号への依存記述
- 「A を B に変更した」という変更の要約
- `/blob/main/...` ベースの GitHub リンク（パーマリンク = コミット SHA ベースに直す）

#### 2c. 何もミスマッチがなかったら

「タイトル・本文は実装と整合しています」と一行報告して、3. に進む。

#### 2d. ミスマッチがあったら

before / after をユーザーに見せて承認を取る。タイトルと本文は別々に提示する。例:

```
## タイトルの提案

  before: feat: add user table
  after:  feat: add user table と posts テーブルの初期 schema

## 本文の提案

  --- before
  +++ after
  @@
  ...
```

ユーザーが「OK」「タイトルだけ直して」「本文のここはそのままで」など個別に判断する余地を
残す。勝手に push 編集しない。

承認が取れたら、以下で更新する:

```bash
gh pr edit <number> \
  --title "新しいタイトル" \
  --body "$(cat <<'EOF'
新しい本文
EOF
)"
```

### 3. draft を外す

`isDraft: true` なら ready for review にする:

```bash
gh pr ready <number>
```

既に ready なら何もしない（その旨だけ報告）。

### 4. レビュアーをアサインする

引数で reviewer が指定されていればそれを使う。されていなければユーザーに聞く。

#### 4a. 既存の reviewRequests / reviews を踏まえる

- 既に同じ人にレビュー依頼が入っている → 二重依頼にならないよう何もしない
  （ただしユーザーが明示的に「再依頼」と言った場合は `--remove-reviewer` →
  `--add-reviewer` で再依頼する）
- 既にその人がレビュー済み（approve でも changes_requested でも） → 「修正後の
  再レビュー依頼ですか？」と確認してから `--add-reviewer` する

#### 4b. アサイン

```bash
gh pr edit <number> --add-reviewer <username>
```

複数指定する場合はカンマ区切り。

### 5. Project Status を In review に更新する（設定があるリポジトリのみ）

`~/.agents/skills/request-review/config.json` を読む。ファイルがなければこのステップを飛ばす。
PR のリポジトリが `repo` と一致する場合のみ、`Closes #N` で特定した Issue の
Project ステータスを `In review` に更新する。

config.json の形式:

```json
{
  "repo": "<owner>/<repo>",
  "org": "<organization login>",
  "project_number": 0,
  "project_id": "<project id>",
  "status_field_id": "<status field id>",
  "in_review_option_id": "<option id>"
}
```

```bash
ITEM_ID=$(gh api graphql -f query='
{
  organization(login: "<org>") {
    projectV2(number: <project_number>) {
      items(first: 100) {
        nodes {
          id
          content { ... on Issue { number } }
        }
      }
    }
  }
}' --jq '.data.organization.projectV2.items.nodes[] | select(.content.number == <ISSUE_NUMBER>) | .id')

gh project item-edit \
  --project-id <project_id> \
  --id "$ITEM_ID" \
  --field-id <status_field_id> \
  --single-select-option-id <in_review_option_id>
```

既に `In review` 以降のステータスならそのままにする（後退させない）。

### 6. 結果を報告する

以下をまとめて報告する:

- PR の URL
- タイトル・本文を更新したか（更新した場合は要点だけ）
- draft → ready にしたか
- アサインした reviewer
- Project Status を更新したか（config.json があるリポジトリの場合）

## 注意事項

- **ユーザーの承認なしに勝手に title / body を編集しない**。整合性チェックで
  ズレを見つけたら必ず before/after を見せる
- diff が大きすぎて全部読み切れない場合、`gh pr diff <number> --name-only` で
  ファイル一覧だけ取って、コミットメッセージとファイル一覧から実態を組み立てる
- `mergeable` が `CONFLICTING` になっていたら、レビューに投げる前に conflict
  解消が必要なことをユーザーに伝える（このスキルでは解消はやらない）
