# Go のエラーハンドリング完全理解 ── errors.Is と errors.As を正しく使い分ける

## はじめに

Go を半年ほど書いていると、エラーハンドリングで `errors.Is` と `errors.As` という2つの関数に出会うはずです。どちらも Go 1.13 で導入された関数で、エラーチェインを辿ってエラーを検査するという共通の目的を持っています。しかし「どちらをいつ使うのか」が曖昧なまま、なんとなく使っていませんか？

この記事では、両者の違いを根本から整理し、実務で迷わず使い分けられるようになることを目指します。

## 前提知識：エラーチェイン（Error Wrapping）

Go 1.13 以降、`fmt.Errorf` に `%w` を使うことでエラーをラップできます。

```go
originalErr := errors.New("connection refused")
wrappedErr := fmt.Errorf("failed to connect to database: %w", originalErr)
```

このとき `wrappedErr` は `originalErr` を内部に持つ「エラーチェイン」を形成します。`errors.Is` と `errors.As` は、このチェインを辿って目的のエラーを探す関数です。

## errors.Is ── 「このエラーか？」を判定する

### 基本的な役割

`errors.Is` は、エラーチェインの中に **特定の値と一致するエラー** が含まれているかを調べます。

```go
func Is(err, target error) bool
```

「値の一致」とは、原則として `==` による比較です。

### 典型的な使い方

```go
if errors.Is(err, os.ErrNotExist) {
    // ファイルが存在しない場合の処理
    log.Println("ファイルが見つかりません")
}
```

```go
if errors.Is(err, sql.ErrNoRows) {
    // レコードが見つからなかった場合の処理
    return nil, ErrUserNotFound
}
```

### いつ使うか

- **センチネルエラー**（パッケージレベルで定義された固定のエラー値）と比較したいとき
- エラーの **種類ではなく、特定のインスタンス** かどうかを知りたいとき

### よくある間違い

```go
// NG: == で直接比較してはいけない
if err == os.ErrNotExist {
    // ラップされていたら一致しない！
}

// OK: errors.Is を使う
if errors.Is(err, os.ErrNotExist) {
    // チェインを辿って見つけてくれる
}
```

## errors.As ── 「この型のエラーか？」を判定する

### 基本的な役割

`errors.As` は、エラーチェインの中に **特定の型に一致するエラー** が含まれているかを調べ、見つかった場合はその値を取り出します。

```go
func As(err error, target interface{}) bool
```

### 典型的な使い方

```go
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    // pathErr にキャストされた値が入っている
    fmt.Printf("操作: %s, パス: %s\n", pathErr.Op, pathErr.Path)
}
```

```go
var netErr net.Error
if errors.As(err, &netErr) {
    if netErr.Timeout() {
        log.Println("タイムアウトが発生しました。リトライします。")
    }
}
```

### いつ使うか

- エラーの **型に基づいて** 処理を分岐したいとき
- エラーに含まれる **追加情報（フィールドやメソッド）にアクセス** したいとき

### よくある間違い

```go
// NG: 型アサーションで直接チェックしてはいけない
if pathErr, ok := err.(*os.PathError); ok {
    // ラップされていたらマッチしない！
}

// OK: errors.As を使う
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    // チェインを辿って見つけてくれる
}
```

## 使い分けの判断基準

ここが本記事の核心です。以下の表で整理します。

| 観点 | errors.Is | errors.As |
|---|---|---|
| 比較対象 | エラーの **値**（インスタンス） | エラーの **型** |
| 質問 | 「このエラーは X と同じか？」 | 「このエラーは型 T か？」 |
| 戻り値 | `bool` のみ | `bool` + 型変換された値 |
| 主な用途 | センチネルエラーとの比較 | 構造体エラーの詳細情報取得 |
| イメージ | `==` の上位互換 | 型アサーションの上位互換 |

### 判断フローチャート

1. **比較したい相手はパッケージ変数（センチネルエラー）か？** → `errors.Is`
   - 例：`io.EOF`, `sql.ErrNoRows`, `os.ErrNotExist`
2. **エラーの型を調べたい、またはエラーからフィールドを取り出したいか？** → `errors.As`
   - 例：`*os.PathError`, `*url.Error`, 自作のエラー構造体
3. **単に「エラーが起きたかどうか」だけ知りたいか？** → `err != nil` で十分

## 実践例：自作エラー型での使い分け

実務では自分でエラー型を定義する場面も多いでしょう。両方を適切に使い分ける例を示します。

### エラー型の定義

```go
// センチネルエラー（値）
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// 構造体エラー（型）
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: %s - %s", e.Field, e.Message)
}
```

### サービス層でラップして返す

```go
func (s *UserService) GetUser(id string) (*User, error) {
    user, err := s.repo.FindByID(id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
        }
        return nil, fmt.Errorf("failed to get user %s: %w", id, err)
    }
    return user, nil
}

func (s *UserService) UpdateUser(id string, input UpdateInput) error {
    if input.Email == "" {
        return fmt.Errorf("update user %s: %w",
            id,
            &ValidationError{Field: "email", Message: "must not be empty"},
        )
    }
    // ...
}
```

### ハンドラ層で検査する

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.service.GetUser(r.PathValue("id"))
    if err != nil {
        // errors.Is: センチネルエラーの値を比較
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        if errors.Is(err, ErrUnauthorized) {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        http.Error(w, "Internal server error", http.StatusInternalServerError)
        return
    }
    // ...
}

func (h *Handler) UpdateUser(w http.ResponseWriter, r *http.Request) {
    err := h.service.UpdateUser(r.PathValue("id"), input)
    if err != nil {
        // errors.As: 型を比較し、フィールドを取り出す
        var valErr *ValidationError
        if errors.As(err, &valErr) {
            msg := fmt.Sprintf("Validation failed on field '%s': %s",
                valErr.Field, valErr.Message)
            http.Error(w, msg, http.StatusBadRequest)
            return
        }
        http.Error(w, "Internal server error", http.StatusInternalServerError)
        return
    }
    // ...
}
```

## 応用：Is メソッドと As メソッドのカスタマイズ

`errors.Is` と `errors.As` は、エラー型に `Is` や `As` メソッドを実装することでマッチングのロジックをカスタマイズできます。

### Is メソッドのカスタマイズ

```go
type AppError struct {
    Code    int
    Message string
}

func (e *AppError) Error() string {
    return fmt.Sprintf("[%d] %s", e.Code, e.Message)
}

// Code が一致すれば同じエラーとみなす
func (e *AppError) Is(target error) bool {
    t, ok := target.(*AppError)
    if !ok {
        return false
    }
    return e.Code == t.Code
}
```

```go
err := &AppError{Code: 404, Message: "user not found"}
wrapped := fmt.Errorf("service error: %w", err)

// Message が異なっていても Code が同じなら true
target := &AppError{Code: 404, Message: ""}
fmt.Println(errors.Is(wrapped, target)) // true
```

この仕組みは、エラーコードベースの比較や、部分一致を実現したいときに有用です。ただし、挙動が暗黙的になるため、チームで合意を取ってから導入することをおすすめします。

## よくある疑問

### Q1: errors.Is で構造体エラーを比較できないの？

技術的にはできます。ただし、`errors.Is` は `==` で比較するため、ポインタ型のエラーでは「同じインスタンスかどうか」の判定になります。

```go
err1 := &ValidationError{Field: "email", Message: "invalid"}
err2 := &ValidationError{Field: "email", Message: "invalid"}

fmt.Println(errors.Is(err1, err2)) // false（別のポインタ）
```

構造体エラーの場合は `errors.As` で型マッチさせるのが正しいアプローチです。

### Q2: %w を複数使えるの？

Go 1.20 以降、`fmt.Errorf` で `%w` を複数使用でき、エラーツリー（複数の親を持つチェイン）を形成できます。

```go
err := fmt.Errorf("operation failed: %w, %w", err1, err2)
```

`errors.Is` と `errors.As` はこのツリーも正しく探索します。

### Q3: errors.Unwrap はいつ使うの？

ほとんどの場合、直接使う必要はありません。`errors.Is` と `errors.As` が内部で `Unwrap` を呼んでチェインを辿ってくれます。エラーチェインを手動で1階層ずつ剥がしたい特殊なケースでのみ使います。

## まとめ

- **`errors.Is`**：エラーの **値** を比較する。センチネルエラーとの照合に使う。`==` の上位互換。
- **`errors.As`**：エラーの **型** を検査し、値を取り出す。構造体エラーの詳細取得に使う。型アサーションの上位互換。
- どちらもエラーチェインを自動で辿るため、`fmt.Errorf("%w", ...)` でラップされたエラーに対しても正しく動作する。
- 直接 `==` や型アサーションでエラーを検査するのは避け、常に `errors.Is` / `errors.As` を使う。

迷ったら「値で比較したいなら Is、型で比較したいなら As」と覚えておけば、実務で困ることはまずないでしょう。
