# 矢印の意味を保証する実装

矢印がある図では、この不変条件を守る。

> すべての矢印は、凡例の行か、自分に付いたラベルの、どちらかで意味が特定できる。どちらも無い矢印は 0 本。

矢印の種類数で運用を切り替える。

| 矢印の種類数 | 必須 |
|---|---|
| 2 以上 | 凡例ブロック必須。各種類を「色」＋「線種または矢じり形状」の 2 軸以上で区別する |
| 1 | 凡例 1 行、または矢印ラベル。どちらか一方でよい |

種類数の上限は business 2 種類、engineer 4 種類（SKILL.md の「矢印の意味は必ず図の中で特定できるようにする」を参照）。超える場合は種類を減らすか図を分割する。

## マーカーライブラリ

4 形状をそのまま `<defs>` に貼る。色を変えるときは `id` を複製し、`path` の `fill` または `stroke` を書き換える（`fill="context-stroke"` は SVG2 の機能で GitHub やスライドアプリで無視されるため使わない。既存の「インライン属性で書く」方針と同じ理由）。マーカー `id` は意味ベースで命名する（例: `arrow-sync`, `arrow-async`）。線とマーカーは同じ色にする。

```xml
<defs>
  <!-- 塗り三角（同期呼び出し・データフローなど「確定した」関係向け） -->
  <marker id="arrow-filled" viewBox="0 0 10 10" refX="9" refY="5"
          markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="#475569"/>
  </marker>

  <!-- 開き矢印（非同期・依存・戻り値など「弱い」関係向け） -->
  <marker id="arrow-open" viewBox="0 0 10 10" refX="8" refY="5"
          markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M1,1 L9,5 L1,9" fill="none" stroke="#475569" stroke-width="1.5"/>
  </marker>

  <!-- 白抜き三角（継承・実装向け） -->
  <marker id="arrow-hollow-triangle" viewBox="0 0 12 10" refX="10" refY="5"
          markerWidth="9" markerHeight="8" orient="auto-start-reverse">
    <path d="M1,1 L11,5 L1,9 z" fill="#ffffff" stroke="#475569" stroke-width="1.5"/>
  </marker>

  <!-- 白抜き菱形（集約向け） -->
  <marker id="arrow-hollow-diamond" viewBox="0 0 14 10" refX="12" refY="5"
          markerWidth="10" markerHeight="8" orient="auto-start-reverse">
    <path d="M1,5 L7,1 L13,5 L7,9 z" fill="#ffffff" stroke="#475569" stroke-width="1.5"/>
  </marker>

  <!-- 塗り菱形（コンポジション向け） -->
  <marker id="arrow-filled-diamond" viewBox="0 0 14 10" refX="12" refY="5"
          markerWidth="10" markerHeight="8" orient="auto-start-reverse">
    <path d="M1,5 L7,1 L13,5 L7,9 z" fill="#475569"/>
  </marker>
</defs>
```

線側の呼び出し例（`fill="none"` は線自体に必須、マーカーとは別に書く）。

```xml
<path d="M100,100 H300" fill="none" stroke="#475569" stroke-width="2" marker-end="url(#arrow-filled)"/>
<path d="M100,160 H300" fill="none" stroke="#475569" stroke-width="2" stroke-dasharray="6 4" marker-end="url(#arrow-open)"/>
```

## 線種の具体値

| 種別 | 属性 |
|---|---|
| 実線 | 指定なし |
| 点線（軽い区別） | `stroke-dasharray="6 4"` |
| 破線（強い区別） | `stroke-dasharray="12 6"` |
| 太い実線（データフロー等の強調） | `stroke-width="4"`（2〜6px の帯に収める。8px 以上は装飾扱いで禁止） |

線種だけで区別を終わらせず、色との組み合わせで 2 軸にする（色だけで区別しないという既存原則の裏返し）。

## 凡例ブロックのテンプレート

右上または下部に配置する。薄い枠または点線枠で本体と区別する。1 行 = サンプル線 20px + ラベルテキスト、行間 22px、フォントサイズ 14px。凡例自体もはみ出し検算・重なり検算の対象。

```xml
<g>
  <!-- 凡例の外枠。本体と区別できるよう薄い色 -->
  <rect x="980" y="40" width="260" height="90" fill="#ffffff" stroke="#cbd5e1" stroke-width="1" rx="6"/>
  <text x="996" y="60" font-size="13" font-weight="700" fill="#334155">凡例</text>

  <!-- 1行目: サンプル線 + ラベル -->
  <path d="M996,80 H1026" fill="none" stroke="#2196F3" stroke-width="2" marker-end="url(#arrow-filled)"/>
  <text x="1036" y="84" font-size="14" fill="#334155">同期呼び出し</text>

  <!-- 2行目 -->
  <path d="M996,102 H1026" fill="none" stroke="#90A4AE" stroke-width="2" stroke-dasharray="6 4" marker-end="url(#arrow-open)"/>
  <text x="1036" y="106" font-size="14" fill="#334155">非同期メッセージ</text>
</g>
```

行数は 4 行程度までを目安にする。それ以上必要になる場合は矢印の種類数の上限を超えている。種類を減らすか図を分割する。

## 矢印インベントリ表

出力前チェックで、図中の全矢印をこの表に書き出して「対応先」列が全行埋まることを確認する。逆方向として、凡例の各行に対応する矢印が実在するかも確認する（使っていない凡例行は削除する）。

| # | 始点 → 終点 | 意味 | 色 | 線種 | 矢じり | 対応先（凡例行 / ラベル） |
|---|---|---|---|---|---|---|
| 1 | Web App → API | 同期呼び出し | `#2196F3` | 実線 | 塗り三角 | 凡例 1行目 |
| 2 | API → Queue | 非同期メッセージ | `#90A4AE` | 点線 | 開き矢印 | 凡例 2行目 |
