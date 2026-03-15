# errors.Is と errors.As、結局どっちを使えばいいのか

## はじめに

この記事で扱うこと：

- `errors.Is` と `errors.As` の違いと使い分け
- それぞれが必要になる具体的な場面
- よくある間違いパターンと、なぜそれがダメなのか

扱わないこと：

- エラーハンドリングの基本（`if err != nil` の書き方レベル）
- サードパーティのエラーライブラリ（`pkg/errors` など）

前提知識：Goを半年くらい書いていて、`fmt.Errorf` や `%w` でエラーをラップしたことがある人向け。

**動機：** Goのエラーハンドリングで `errors.Is` と `errors.As` を「なんとなく」使い分けている人は多いと思う。自分もそうだった。でも「なんとなく」だと、エラーがラップされた途端に判定が壊れて本番で痛い目を見る。この記事では、両者の違いを具体的なコードで体感してもらいたい。

## 背景：Go 1.13 でエラーハンドリングが変わった

Go 1.13 以前、エラーの比較はシンプルだった。

```go
if err == sql.ErrNoRows {
    // 見つからなかった
}
```

これで十分だった時代がある。しかし Go 1.13 で `fmt.Errorf("%w", err)` によるエラーラッピングが導入されて、話が変わった。

```go
func GetUser(id int) (*User, error) {
    user, err := db.QueryUser(id)
    if err != nil {
        return nil, fmt.Errorf("GetUser(id=%d): %w", id, err)
    }
    return user, nil
}
```

こうやってコンテキストを付与するのは良いプラクティスだ。だが、ラップされたエラーは `==` では比較できなくなる。

## よくある間違い：`==` でラップされたエラーを比較する

まず、壊れるコードを見てみよう。

```go
func main() {
    _, err := GetUser(999)
    if err == sql.ErrNoRows {
        fmt.Println("ユーザーが見つかりません")
    } else if err != nil {
        fmt.Println("予期しないエラー:", err)
    }
}
```

出力：

```
予期しないエラー: GetUser(id=999): sql: no rows in result set
```

`sql.ErrNoRows` のはずなのに、`==` 比較が `false` になる。`GetUser` がエラーを `fmt.Errorf("%w", ...)` でラップしたため、返ってきたエラーは `sql.ErrNoRows` そのものではなく、それを内包した別のエラー値だからだ。

これが本番コードで起きると、「ユーザーが見つからない」という正常系の分岐に入らず、500エラーとしてログに出続けるという地味に厄介な障害になる。

## errors.Is：「このエラー（またはその原因）は、特定の値と一致するか？」

`errors.Is` はエラーチェーンを辿って、指定した値と一致するエラーがあるかを調べる。

```go
func main() {
    _, err := GetUser(999)
    if errors.Is(err, sql.ErrNoRows) {
        fmt.Println("ユーザーが見つかりません")
    } else if err != nil {
        fmt.Println("予期しないエラー:", err)
    }
}
```

出力：

```
ユーザーが見つかりません
```

`errors.Is` はエラーが何重にラップされていても、チェーンを辿って `sql.ErrNoRows` を見つけてくれる。

```go
// 3重にラップされていても大丈夫
err := fmt.Errorf("handler: %w",
    fmt.Errorf("service: %w",
        fmt.Errorf("repository: %w", sql.ErrNoRows)))

errors.Is(err, sql.ErrNoRows) // true
```

### errors.Is を使う場面

**「どのエラーか」を値で判別したいとき。**

典型的な使い方：

```go
// センチネルエラー（パッケージレベルで定義されたエラー値）との比較
if errors.Is(err, sql.ErrNoRows) { ... }
if errors.Is(err, os.ErrNotExist) { ... }
if errors.Is(err, context.Canceled) { ... }
if errors.Is(err, context.DeadlineExceeded) { ... }
```

ポイントは、比較対象が **特定のエラー値（センチネルエラー）** であること。「このエラーは `sql.ErrNoRows` か？」という Yes/No の質問に答えるのが `errors.Is` だ。

## errors.As：「このエラー（またはその原因）は、特定の型か？ 中身を取り出したい」

`errors.As` はエラーチェーンを辿って、指定した **型** に一致するエラーを探し、見つかったらその値を取り出す。

まず、カスタムエラー型を定義する場面を考えよう。

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed: %s - %s", e.Field, e.Message)
}

func ValidateAge(age int) error {
    if age < 0 || age > 150 {
        return &ValidationError{
            Field:   "age",
            Message: fmt.Sprintf("must be between 0 and 150, got %d", age),
        }
    }
    return nil
}
```

このエラーを受け取る側で、エラーの詳細情報（どのフィールドが不正か）を取り出したい。ここで `errors.As` が登場する。

```go
func HandleRequest(age int) {
    err := ValidateAge(age)
    if err != nil {
        var ve *ValidationError
        if errors.As(err, &ve) {
            // ve に ValidationError の値が入っている
            fmt.Printf("フィールド %q が不正: %s\n", ve.Field, ve.Message)
            return
        }
        // ValidationError 以外のエラー
        fmt.Println("予期しないエラー:", err)
    }
}
```

もちろん、ラップされていても動く。

```go
func CreateUser(name string, age int) error {
    if err := ValidateAge(age); err != nil {
        return fmt.Errorf("CreateUser: %w", err)
    }
    return nil
}

func main() {
    err := CreateUser("Alice", -5)

    var ve *ValidationError
    if errors.As(err, &ve) {
        fmt.Printf("フィールド: %s, メッセージ: %s\n", ve.Field, ve.Message)
        // フィールド: age, メッセージ: must be between 0 and 150, got -5
    }
}
```

### errors.As を使う場面

**「どの種類のエラーか」を型で判別し、かつエラーの詳細情報を取り出したいとき。**

典型的な使い方：

```go
// カスタムエラー型の詳細を取得
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Println("操作:", pathErr.Op)
    fmt.Println("パス:", pathErr.Path)
}

// DNSエラーの詳細を取得
var dnsErr *net.DNSError
if errors.As(err, &dnsErr) {
    fmt.Println("一時的なエラー?:", dnsErr.Temporary())
}
```

## よくある間違いパターン

### 間違い 1：errors.As で値の比較をしようとする

```go
// これは意味がない
var target = sql.ErrNoRows
if errors.As(err, &target) { ... }
```

`sql.ErrNoRows` はただの `error` インターフェースを満たす値であり、構造体ポインタではない。`errors.As` は型マッチングなので、`error` インターフェース型でマッチさせると、あらゆるエラーにマッチしてしまう。センチネルエラーとの比較には `errors.Is` を使うこと。

### 間違い 2：型アサーションで済ませてしまう

```go
// ラップされたエラーで壊れる
if ve, ok := err.(*ValidationError); ok {
    fmt.Println(ve.Field)
}
```

`err` が直接 `*ValidationError` ならこれで動く。しかし `fmt.Errorf("...: %w", err)` でラップされた瞬間に `ok` が `false` になる。型アサーションはエラーチェーンを辿らない。

これも本番で起きやすい。開発中はエラーをラップしていないから動くが、あとからログ改善のためにラップを追加した途端、既存の型アサーションが全部壊れる。

### 間違い 3：errors.Is で型を判別しようとする

```go
// これはコンパイルエラーにはならないが、期待通りに動かない
if errors.Is(err, &ValidationError{}) {
    // ValidationError かどうかを判定したいのに...
}
```

`errors.Is` は **値の一致** を調べる。`&ValidationError{}` はゼロ値の `ValidationError` なので、フィールドの値まで含めた比較になる。型で判別したいなら `errors.As` を使う。

## 使い分け早見表

| やりたいこと | 使うもの | 例 |
|---|---|---|
| 特定のエラー値か判定したい | `errors.Is` | `errors.Is(err, sql.ErrNoRows)` |
| 特定のエラー型か判定したい | `errors.As` | `errors.As(err, &pathErr)` |
| エラーの詳細情報を取り出したい | `errors.As` | `errors.As(err, &ve)` で `ve.Field` を参照 |
| `==` の代わり | `errors.Is` | `err == target` を `errors.Is(err, target)` に |
| 型アサーションの代わり | `errors.As` | `err.(*T)` を `errors.As(err, &t)` に |

覚え方としては：

- **Is** = 同一性の確認（**この値**か？）
- **As** = 型の変換（**この型**か？ 中身をくれ）

## 実装上の注意：カスタムエラー型を作るときの落とし穴

カスタムエラー型で `Is` メソッドや `Unwrap` メソッドを実装すると、`errors.Is` / `errors.As` の挙動をカスタマイズできる。これは便利だが、落とし穴もある。

### Unwrap の実装

エラーを内包するカスタムエラー型を作る場合、`Unwrap()` を実装しないとチェーンが途切れる。

```go
type AppError struct {
    Code    int
    Message string
    Err     error // 元のエラー
}

func (e *AppError) Error() string {
    return fmt.Sprintf("[%d] %s: %v", e.Code, e.Message, e.Err)
}

// これがないと errors.Is / errors.As がチェーンを辿れない
func (e *AppError) Unwrap() error {
    return e.Err
}
```

`Unwrap` を実装し忘れると、`AppError` でラップしたエラーに対して `errors.Is(err, sql.ErrNoRows)` が `false` を返すようになる。`fmt.Errorf("%w", ...)` は自動的に `Unwrap` を実装してくれるが、自前の構造体では明示的に書く必要がある。

### Go 1.20 以降：複数のエラーをラップ

Go 1.20 で `fmt.Errorf` に複数の `%w` を使えるようになった。

```go
err := fmt.Errorf("multiple issues: %w and %w", err1, err2)
```

この場合、`errors.Is` と `errors.As` は両方のチェーンを探索する。自前で実装する場合は `Unwrap() []error` を返すようにする。

```go
func (e *MultiError) Unwrap() []error {
    return e.Errs
}
```

## 本番コードでの使い方のパターン

実際のWebアプリケーションでよくあるパターンを示す。

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := extractID(r)
    user, err := h.userService.FindByID(r.Context(), id)
    if err != nil {
        // 値で判定：センチネルエラー
        if errors.Is(err, context.Canceled) {
            // クライアントが接続を切った。ログは出すがアラートは不要
            log.Info("client disconnected", "id", id)
            return
        }
        if errors.Is(err, sql.ErrNoRows) {
            http.Error(w, "user not found", http.StatusNotFound)
            return
        }

        // 型で判定：エラーの詳細情報が欲しい
        var pgErr *pgconn.PgError
        if errors.As(err, &pgErr) {
            log.Error("database error",
                "code", pgErr.Code,
                "message", pgErr.Message,
                "detail", pgErr.Detail,
            )
            http.Error(w, "internal error", http.StatusInternalServerError)
            return
        }

        // 想定外のエラー
        log.Error("unexpected error", "err", err)
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }

    respondJSON(w, user)
}
```

ここでのポイント：

- `context.Canceled` と `sql.ErrNoRows` はセンチネルエラーなので `errors.Is`
- `*pgconn.PgError` は構造体型でエラーコードなどの詳細を取りたいので `errors.As`
- 判定の順序も大事。クライアント切断を先にチェックすることで、不要なDB エラーログを避けている

## この記事の限界

- `errors.Is` / `errors.As` のカスタム実装（`Is(error) bool` メソッド）については深掘りしていない。必要になる場面は限られるが、ライブラリ作者は公式ドキュメントを参照してほしい
- パフォーマンスについては触れていない。エラーチェーンが極端に深い場合（数百段）の性能影響はあるが、通常のアプリケーションでは問題にならない
- サードパーティの `github.com/cockroachdb/errors` などのライブラリは扱っていない

## まとめ

- `==` によるエラー比較は、エラーがラップされた瞬間に壊れる。`errors.Is` / `errors.As` を使おう
- **`errors.Is`**：特定のエラー **値** と一致するか判定する。センチネルエラーとの比較に使う
- **`errors.As`**：特定のエラー **型** に一致するか判定し、値を取り出す。カスタムエラー型の詳細取得に使う
- カスタムエラー型を作るときは `Unwrap()` の実装を忘れない
- 型アサーション（`err.(*T)`）ではなく `errors.As` を使う。後からラップが追加されても壊れない

## 参考

- [Go Blog: Working with Errors in Go 1.13](https://go.dev/blog/go1.13-errors)
- [Go 標準ライブラリ: errors パッケージ](https://pkg.go.dev/errors)
- [Go 標準ライブラリ: fmt.Errorf](https://pkg.go.dev/fmt#Errorf)
- [Go Wiki: Error Handling](https://go.dev/wiki/Errors)
- [Go 1.20 Release Notes - Wrapping multiple errors](https://go.dev/doc/go1.20#errors)
