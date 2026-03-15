# Terraform state管理で事故らないために知っておくべきこと

## はじめに

### この記事で扱うこと

- remote stateの設定方法と、なぜlocal stateではダメなのか
- state lockの仕組みと、これがないと何が起きるか
- state分割の考え方と、分割しないとどうなるか

### この記事で扱わないこと

- Terraformの基本的な文法やリソース定義
- 特定のクラウドプロバイダーに特化した話（例はAWSを使うが、考え方はどこでも同じ）
- Terraform Cloudやspaceliftなどのマネージドサービスの詳細

### 前提知識

- Terraformで `terraform plan` / `terraform apply` を何度か実行したことがある
- S3やGCSなどのオブジェクトストレージの基本は知っている
- チームで1つのインフラを複数人で管理している、またはこれからする予定

### 動機

Terraformを使い始めて半年くらい経つと、だいたい「stateファイルどうしよう問題」にぶつかる。最初はなんとなく動いていたものが、チームメンバーが増えたり、管理するリソースが増えたりすると、突然怖くなってくる。この記事は、そういう「なんとなく不安」を「具体的に何をすればいいか」に変えるために書いた。

---

## 背景：Terraform stateとは何か

Terraformはインフラの「あるべき姿」を `.tf` ファイルに書く。でも、Terraformが `plan` や `apply` をするとき、現在のインフラの状態をどこかに保存しておく必要がある。それが `terraform.tfstate` ファイルだ。

このファイルには以下のような情報が入っている：

- 管理対象のリソースID（例：`i-0abc123def456`）
- リソースの属性値（IPアドレス、ARNなど）
- リソース間の依存関係

つまり、stateファイルは **Terraformにとっての「現実世界の地図」** だ。この地図が壊れると、Terraformは正しい判断ができなくなる。

---

## よくあるアプローチとその限界

### パターン1：local stateをGitで管理する

Terraform初心者がまずやりがちなのが、`terraform.tfstate` をGitリポジトリにコミットする方法だ。

```
my-infra/
├── main.tf
├── variables.tf
├── terraform.tfstate      # これをGitにコミット
└── terraform.tfstate.backup
```

一見合理的に見える。バージョン管理されるし、チームで共有できる。

**でも、これは壊れる。**

#### 壊れるケース1：同時編集による競合

```
時刻 10:00  Aさん: git pull → terraform apply（EC2追加）
時刻 10:02  Bさん: git pull → terraform apply（RDS追加）
時刻 10:05  Aさん: git commit & push → 成功
時刻 10:06  Bさん: git commit & push → コンフリクト！
```

Bさんのstateファイルには、Aさんが作ったEC2の情報がない。ここでマージを間違えると、次の `terraform plan` で「EC2を削除します」と言われる。本番のEC2が消える。

#### 壊れるケース2：機密情報の漏洩

stateファイルにはデータベースのパスワードやAPIキーが**平文で**記録されることがある。

```json
{
  "type": "aws_db_instance",
  "primary": {
    "attributes": {
      "password": "super-secret-password-123"
    }
  }
}
```

Gitにコミットした時点で、リポジトリにアクセスできる全員がパスワードを見られる。プライベートリポジトリでも、退職者のアクセス権限管理まで考えると怖い。

### パターン2：stateを共有ドライブに置く

「Gitがダメならファイルサーバーに置こう」という発想。Google DriveやDropboxに `terraform.tfstate` を置いて共有する。

これもダメだ。理由はシンプルで、**同時書き込みを防ぐ仕組みがない**。AさんとBさんが同時に `terraform apply` したら、お互いのstateを上書きし合う。

---

## 提案するアプローチ

### Remote state + State lock + State分割

この3つを組み合わせることで、チームでのTerraform運用が安全になる。順番に見ていこう。

---

## 1. Remote State：stateをクラウドストレージに置く

### 設定方法（S3 + DynamoDBの例）

まず、backend用のS3バケットとDynamoDBテーブルを作る。**これだけはTerraform外で作るか、別のstateで管理する**（鶏と卵問題を避けるため）。

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "production/network/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

S3バケット側の設定で重要なポイント：

```hcl
# これはbackend用バケットを作るための別プロジェクト
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-company-terraform-state"

  # 誤削除を防止
  lifecycle {
    prevent_destroy = true
  }
}

# バージョニング有効化（誤操作からの復旧に必須）
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 暗号化（stateに含まれる機密情報を保護）
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# パブリックアクセス完全ブロック
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### local stateとの比較

| 観点 | local state（Git管理） | remote state（S3） |
|------|----------------------|-------------------|
| 同時アクセス制御 | なし（Gitマージに依存） | state lockで排他制御 |
| 機密情報 | Gitに平文で残る | S3側で暗号化 |
| バージョン管理 | Gitの履歴 | S3バージョニング |
| アクセス制御 | Gitリポジトリ単位 | IAMポリシーで細かく制御 |
| 復旧 | `git revert`（マージ事故リスク） | S3バージョンから復元 |

---

## 2. State Lock：同時実行を防ぐ

### なぜlockが必要か

remote stateだけでは、同時実行の問題は解決しない。S3に置いただけでは、2人が同時に `terraform apply` できてしまう。

```
時刻 10:00  Aさん: terraform plan（stateを読む）
時刻 10:01  Bさん: terraform plan（同じstateを読む）
時刻 10:02  Aさん: terraform apply（stateを書く）
時刻 10:03  Bさん: terraform apply（Aさんの変更を知らないまま書く）→ 💥
```

### DynamoDBによるlock設定

```hcl
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

backend設定で `dynamodb_table` を指定するだけで、Terraformは自動的にlockを取得・解放する。

### lockがある場合の動作

```
時刻 10:00  Aさん: terraform apply → lockを取得 → 実行開始
時刻 10:01  Bさん: terraform apply → lock取得を試みる → 失敗

  Error: Error acquiring the state lock

  Error message: ConditionalCheckFailedException: The conditional request failed
  Lock Info:
    ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
    Path:      my-company-terraform-state/production/network/terraform.tfstate
    Operation: OperationTypeApply
    Who:       aさん@ip-10-0-1-100
    Version:   1.5.7
    Created:   2024-01-15 10:00:00.000000000 +0000 UTC

時刻 10:05  Aさん: terraform apply完了 → lockを解放
時刻 10:06  Bさん: terraform apply → lock取得成功 → 実行開始
```

Bさんは明確なエラーメッセージを受け取り、誰が何をしているかわかる。安全だ。

### lockが残ってしまった場合

`terraform apply` の途中でプロセスが死ぬと、lockが残ることがある。この場合は `terraform force-unlock` を使う。

```bash
# lockのIDを指定して強制解除
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**注意：`force-unlock` は本当に誰も実行していないことを確認してから使うこと。** 誰かが実行中にlockを外すと、同時書き込みが起きてstateが壊れる。Slackで「今Terraform使ってる人いますか？」と聞くのは泥臭いけど大事だ。

---

## 3. State分割：爆発半径を小さくする

### 全部入りstateの問題

1つのstateファイルで全リソースを管理すると、以下の問題が出てくる。

```
my-infra/
├── main.tf          # VPC, EC2, RDS, S3, IAM, CloudFront, Route53...
├── variables.tf     # 全環境の変数
└── terraform.tfstate # 数千リソースの情報が1ファイルに
```

**問題1：`plan` が遅い**

stateに1000リソースあると、`terraform plan` が5〜10分かかることがある。全リソースの現在の状態をAPIで確認するからだ。「ちょっとセキュリティグループ1つ変えたいだけなのに10分待つ」というのは、開発体験として最悪だ。

**問題2：影響範囲が大きすぎる**

1つのstateに全リソースがあると、あるリソースの変更が意図せず他のリソースに影響する可能性がある。`terraform apply` の爆発半径（blast radius）がインフラ全体になってしまう。

**問題3：lockの競合が頻発する**

stateが1つだと、誰かが `plan` を実行するだけでlockがかかる。チームが5人以上いると、「lockが取れなくてapplyできない」が日常になる。

### 分割の考え方

state分割には「正解」はないが、よく使われるパターンがある。

#### パターン1：レイヤーで分割する

```
infrastructure/
├── network/          # VPC, Subnet, NAT Gateway, Route Table
│   ├── main.tf
│   └── backend.tf    # state: production/network/terraform.tfstate
├── database/         # RDS, ElastiCache
│   ├── main.tf
│   └── backend.tf    # state: production/database/terraform.tfstate
├── application/      # ECS, ALB, Security Group
│   ├── main.tf
│   └── backend.tf    # state: production/application/terraform.tfstate
└── monitoring/       # CloudWatch, SNS
    ├── main.tf
    └── backend.tf    # state: production/monitoring/terraform.tfstate
```

レイヤーの目安：

| レイヤー | 変更頻度 | リスク | 例 |
|---------|---------|--------|-----|
| ネットワーク | 低（月1回以下） | 高 | VPC, Subnet, NAT GW |
| データストア | 低（月1〜2回） | 高 | RDS, ElastiCache |
| アプリケーション | 高（週数回） | 中 | ECS, ALB, SG |
| モニタリング | 中（週1回） | 低 | CloudWatch, SNS |

変更頻度が高いものと低いものを分けるのがポイントだ。ネットワークは滅多に変わらないのに、アプリのデプロイのたびにlockを取られたら困る。

#### パターン2：環境で分割する

```
infrastructure/
├── environments/
│   ├── production/
│   │   ├── main.tf
│   │   └── backend.tf   # state: production/terraform.tfstate
│   ├── staging/
│   │   ├── main.tf
│   │   └── backend.tf   # state: staging/terraform.tfstate
│   └── development/
│       ├── main.tf
│       └── backend.tf   # state: development/terraform.tfstate
└── modules/
    ├── network/
    └── application/
```

環境分割は必須と言っていい。productionのstateとstagingのstateが同じだと、stagingの変更がproductionに影響するリスクがある。

#### 実践的なおすすめ：レイヤー × 環境

```
infrastructure/
├── production/
│   ├── network/
│   ├── database/
│   └── application/
├── staging/
│   ├── network/
│   ├── database/
│   └── application/
└── modules/
    ├── network/
    ├── database/
    └── application/
```

### 分割したstate間でデータを参照する

stateを分割すると、「networkのVPC IDをapplicationで使いたい」という場面が出てくる。ここで `terraform_remote_state` データソースを使う。

```hcl
# application/main.tf

# networkのstateからVPC IDを取得
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-company-terraform-state"
    key    = "production/network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}
```

参照元（network側）では、`output` を定義しておく必要がある。

```hcl
# network/outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID for application layer"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs for application layer"
}
```

### 分割しすぎの罠

ここまで読むと「じゃあ細かく分ければ分けるほどいいのか」と思うかもしれないが、分割しすぎにも問題がある。

- **`terraform_remote_state` の依存関係が複雑になる** - A→B→C→Dの参照チェーンができると、変更の影響範囲の把握が難しい
- **applyの順序管理が面倒になる** - networkを先にapplyしないとapplicationがapplyできない、といった依存順序を人間が管理する必要がある
- **一覧性が下がる** - 「このリソースどこにあるんだっけ」と探す時間が増える

目安として、**チーム規模が5人以下なら3〜5分割くらい**がちょうどいい。それ以上に分けるのは、本当に必要になってからでいい。

---

## 運用上の注意

### stateファイルのバックアップ

S3のバージョニングを有効にしていれば、過去のstateに戻れる。ただし、**stateだけ戻しても実際のインフラは元に戻らない**ことに注意。stateは「地図」であって「領土」ではない。

stateを過去バージョンに戻す場合の手順：

```bash
# 1. 現在のstateをバックアップ
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. S3から過去バージョンを取得
aws s3api get-object \
  --bucket my-company-terraform-state \
  --key production/network/terraform.tfstate \
  --version-id "xxxx" \
  restored.tfstate

# 3. 復元したstateをpush
terraform state push restored.tfstate

# 4. planで差分を確認（ここが重要）
terraform plan
```

### CI/CDでのTerraform実行

チームの運用が成熟してきたら、ローカルからの `terraform apply` を禁止して、CI/CD経由のみにするのがベストだ。

```
PR作成 → terraform plan（自動実行、結果をPRにコメント）
     → レビュー・承認
     → マージ → terraform apply（自動実行）
```

これにより以下のメリットがある：

- 誰がいつ何を変更したかがPRに残る
- planの結果をレビューしてからapplyできる
- ローカル環境の差異（Terraformバージョン違いなど）に悩まされない

### 事故が起きたときの対応

stateが壊れた場合、慌てずに以下の手順で対応する：

1. **全員にTerraform操作を止めるよう連絡する**
2. **S3バージョニングから直前のstateを復元する**
3. **`terraform plan` で差分を確認する**
4. **差分が意図通りなら `terraform apply`、意図しない差分があれば `terraform import` や `terraform state rm` で手動修正する**

ぶっちゃけ、stateが壊れるのはチームでTerraform運用していれば一度は経験する。大事なのは、壊れたときにリカバリーできる仕組み（バージョニング、バックアップ）を事前に用意しておくことだ。

---

## まとめ

- **local stateのGit管理は避ける** - 同時編集のコンフリクトと機密情報漏洩のリスクがある
- **remote state（S3等）を使う** - 暗号化、アクセス制御、バージョニングが利用できる
- **state lockは必須** - DynamoDB等を使って同時実行を防ぐ。lockがないと同時applyでstateが壊れる
- **stateはレイヤーと環境で分割する** - blast radiusを小さくし、lock競合を減らす。ただし分割しすぎに注意
- **バージョニングとバックアップを必ず設定する** - 事故は起きる前提で備える
- **成熟したらCI/CD経由でのapplyに移行する** - 人間が直接applyするリスクを減らす

---

## 参考

- [Terraform公式ドキュメント - Backend Configuration](https://developer.hashicorp.com/terraform/language/backend)
- [Terraform公式ドキュメント - State](https://developer.hashicorp.com/terraform/language/state)
- [Terraform公式ドキュメント - Remote State Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [Terraform: Up and Running, 3rd Edition](https://www.terraformupandrunning.com/) - Yevgeniy Brikman著。state管理の章が特に参考になる
- [AWS Provider - S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
