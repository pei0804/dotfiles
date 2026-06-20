---
name: close-issue
description: |
  GitHub Issue をクローズする前に、紐づく PR（マージ済み・参照）の実態からタイトルと本文を実際にやったこと通りに更新し、完了サマリのコメントを残してから close する。
  着手後にスコープが広がった・方針が変わった Issue ほど、当初のタイトル・本文と成果物がズレている。クローズ済み Issue は永続的な記録なので、PR を真実の基準にして実態に直してから閉じる。
  「issue をクローズして」「#123 終わったから閉じて」「この issue 完了にして」「done #123」「issue 閉じといて」「実態に合わせてクローズ」「やったこと反映してクローズ」などと言われたら使う。
  リポジトリは問わない（カレントリポジトリから自動解決する）。
  Issue の新規起票や、PR のマージそのものには使わない。
argument-hint: "[#N | issue の URL]"
allowed-tools: Bash, AskUserQuestion, Read
---

# Issue を実態に合わせてからクローズする

クローズした Issue はその後ずっと残る記録になる。着手後にスコープが広がったり方針が変わったりすると、当初書いたタイトル・本文と実際にやったことがズレたまま閉じられ、後から読む人（人間も AI も）を誤解させる。

このスキルは、Issue を閉じる前に **紐づく PR を真実の基準** にしてタイトル・本文を実態通りに直し、なぜそう直したかをコメントで残してから close するまでを一気にやる。

PR が真実なのは、Issue が「これからやること（計画）」を書くのに対し、PR は「実際に変更したもの（成果物）」を記録するから。両者がズレていたら、PR 側が起きたことの事実。

## 動作原則

- PR・コミットが裏づける事実だけを書く。Issue 本文の古い計画や、PR にない推測で埋めない
- スコープが変わっていたら、それを隠さず「当初計画からの変更点」として明記する。ズレを正直に残すのがこのスキルの価値
- タイトル・本文を更新したら必ず確認を取ってから適用する。実態の解釈が割れる余地があるため
- Project ボードの Status 更新はリポジトリ固有の運用なので、このスキルでは扱わない。専用スキル（例: このリポの `/issue done`）がある場合はそちらに任せる旨を最後に伝える

## Step 1: 対象 Issue とリポジトリの解決

`$ARGUMENTS` から Issue 番号（`#N` / `N`）または Issue の URL を取り出す。

リポジトリは、URL が渡されていればそこから owner/repo を取る。なければカレントディレクトリから解決する:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

Issue の現状を取得する:

```bash
gh issue view "$N" --repo "$REPO" \
  --json number,title,body,state,labels,url,stateReason
```

- すでに `CLOSED` の場合: 「すでにクローズ済み」と伝えたうえで、タイトル・本文の実態反映だけ行うか確認する。クローズ/マージ時にズレを直すのは閉じた後でも有効
- Issue が見つからない場合: 番号・リポジトリを確認して止まる

## Step 2: 紐づく PR を漏れなく集める

PR と Issue の紐付けは2経路ある。両方を取って番号で重複排除する。

- `closedByPullRequestsReferences`: `Closes #N` などでこの Issue をクローズした PR
- `timelineItems` の `CROSS_REFERENCED_EVENT`: `Part of #N` など、クローズはしないが参照している PR

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: N) {
      closedByPullRequestsReferences(first: 20, includeClosedPrs: true) {
        nodes { number title state url }
      }
      timelineItems(first: 50, itemTypes: [CROSS_REFERENCED_EVENT]) {
        nodes {
          ... on CrossReferencedEvent {
            source { ... on PullRequest { number title state url } }
          }
        }
      }
    }
  }
}' --jq '{closedBy: .data.repository.issue.closedByPullRequestsReferences.nodes, crossRef: [.data.repository.issue.timelineItems.nodes[].source | select(. != {})]}'
```

`OWNER` / `REPO` / `N` は Step 1 の値で置換する。

集めた PR は **MERGED を優先** する。OPEN や CLOSED（未マージ）の PR は実態の一部かどうか怪しいので、扱いをユーザーに確認する。

紐づく PR が1件もない場合: PR ベースで実態を再構成できない。これは「成果物なしでクローズ」（取り下げ・not planned）の可能性が高い。Step 3〜4 を飛ばし、Step 5 で「なぜ閉じるか」を確認して not planned でクローズする方に切り替える。

## Step 3: 実際にやったことを再構成する

各 PR の中身を読む。タイトル・本文・コミットが、実際に何が変わったかを語る。

```bash
gh pr view "$P" --repo "$REPO" --json number,title,body,state,url,mergedAt
gh pr view "$P" --repo "$REPO" --json commits --jq '.commits[].messageHeadline'
```

ファイル単位の変更範囲が必要なら:

```bash
gh pr diff "$P" --repo "$REPO" --name-only
```

ここで押さえること:

1. 実際に行われた変更の要約（PR ごと）
2. Issue 当初の計画との差分。スコープが広がった/削られた、アプローチが変わった、据え置いた判断
3. PR をまたいで分割実施されている場合は、その分割構造（どの PR が何を担ったか）

## Step 4: ズレを検出して更新案を作る

現在の Issue タイトル・本文と、Step 3 で再構成した実態を突き合わせる。

**タイトル**: 実態と食い違っていれば直す。Issue が表す成果物を素直に表す表現にする。食い違っていなければ変えない。

**本文**: 次の構成で組み立てる。

- 背景: なぜこの Issue が必要だったか（元の背景が正しければ活かす）
- 実施内容: 実際にやったことを PR ごとにまとめる。各 PR を `#番号` で参照する
- 当初計画からの変更点: スコープや方針がズレていれば、当初計画と実態を対比して明記する（差分が小さければ省略可）
- 完了サマリ: 最終的に何が達成され、何を据え置いたかを数行で

PR・コミットが裏づけない記述は入れない。

## Step 5: 確認 → 更新 → コメント → クローズ

更新案（新タイトルと新本文）をユーザーに提示し、適用してよいか確認する。

確認が取れたら止めずに一気に実行する。本文は一時ファイルに書き出して `--body-file` で渡す（ヒアドキュメントだと本文中のバッククォートやコマンド置換が壊れることがある）。

```bash
# 本文を一時ファイルに用意してから
gh issue edit "$N" --repo "$REPO" \
  --title "新しいタイトル" \
  --body-file /path/to/new-body.md
```

なぜ更新したかをコメントで残す。本文の diff だけでは経緯が追えないため:

```bash
gh issue comment "$N" --repo "$REPO" --body "$(cat <<'EOF'
## 更新内容

実態に合わせてタイトル・本文を更新した。

- {変更点1}
- {変更点2}

関連 PR: #XXXX / #YYYY
EOF
)"
```

クローズする:

```bash
gh issue close "$N" --repo "$REPO" --reason completed
```

紐づく PR が無く取り下げる場合は、なぜ閉じるかを1コメント残してから:

```bash
gh issue close "$N" --repo "$REPO" --reason "not planned"
```

## Step 6: 報告

- Issue 番号・新タイトル・URL
- close 済みであること（reason: completed / not planned）
- 反映に使った PR の番号
- Project ボードの Status を別途更新したい場合は、そのリポジトリ専用のスキル（例: `/issue done`）を使うよう案内する
