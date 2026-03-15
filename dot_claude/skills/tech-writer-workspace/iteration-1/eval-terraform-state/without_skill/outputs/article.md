# Terraform State管理のベストプラクティス — チーム開発で失敗しないための実践ガイド

## はじめに

Terraformを使い始めて数ヶ月、`terraform apply` でインフラを構築できるようになった頃、次にぶつかる壁が **state管理** です。個人で使っているうちは問題になりにくいのですが、チームで運用し始めると「誰かがapplyしている最中に別の人もapplyしてしまった」「stateファイルが壊れた」「stateが肥大化してplanが遅い」といったトラブルが頻発します。

この記事では、Terraform歴半年ほどのインフラエンジニアを対象に、チーム開発で必須となるstate管理のベストプラクティスを3つの観点から解説します。

1. **Remote State** — stateファイルをチームで安全に共有する
2. **State Lock** — 同時実行による破壊を防ぐ
3. **State分割** — 運用しやすい粒度に分ける

## 1. Remote Stateの設定

### なぜRemote Stateが必要なのか

Terraformはデフォルトで `terraform.tfstate` というファイルをローカルに生成します。このファイルには、Terraformが管理するすべてのリソースの現在の状態が記録されています。

ローカルstateのままチーム開発を行うと、以下の問題が発生します。

- **stateの不一致**: AさんのローカルstateとBさんのローカルstateが異なり、意図しないリソースの削除や再作成が発生する
- **stateの紛失**: PCの故障やディスク破損でstateファイルを失うと、Terraformが管理しているリソースとの対応関係が分からなくなる
- **機密情報の散在**: stateファイルにはデータベースのパスワードなどの機密情報が平文で含まれる場合があり、各開発者のローカルに散在するのはセキュリティリスクになる

### S3 + DynamoDB構成（AWS環境の場合）

AWSを使っている場合、最も一般的な構成は **S3バケット + DynamoDBテーブル** です。S3がstateファイルの保存先、DynamoDBがロック機構を担います。

#### Step 1: バックエンド用リソースの作成

まず、stateを保存するためのS3バケットとDynamoDBテーブルを作成します。これらのリソース自体はTerraformで管理しても構いませんが、「鶏と卵」問題を避けるため、別のTerraformワークスペースまたはCloudFormation/手動で作成することを推奨します。

```hcl
# backend-setup/main.tf（バックエンド用リソースを管理する別プロジェクト）

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-team-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

ポイントをいくつか補足します。

- **バージョニングの有効化**: stateファイルが破損した場合に以前のバージョンに戻せるようにします。これは必須設定です
- **サーバーサイド暗号化**: stateには機密情報が含まれる可能性があるため、保存時の暗号化を有効にします
- **パブリックアクセスのブロック**: stateファイルが外部に公開されるのを防ぎます
- **prevent_destroy**: 誤ってバケットを削除してしまうのを防ぎます

#### Step 2: backendの設定

メインのTerraformプロジェクトでbackendを設定します。

```hcl
# main.tf

terraform {
  backend "s3" {
    bucket         = "my-team-terraform-state"
    key            = "production/network/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

`key` はS3バケット内のパスです。後述するstate分割と関連しますが、環境名やコンポーネント名を含めた階層構造にしておくと管理しやすくなります。

#### Step 3: 初期化

backend設定を追加したら `terraform init` を実行します。既にローカルにstateがある場合は、リモートへの移行を確認するプロンプトが表示されます。

```bash
$ terraform init

Initializing the backend...
Do you want to copy existing state to the new backend?
  ...
  Enter a value: yes
```

### GCS構成（Google Cloud環境の場合）

Google Cloudの場合は、GCSバケットを使います。GCSはバケット自体にロック機構が組み込まれているため、DynamoDBのような別サービスは不要です。

```hcl
terraform {
  backend "gcs" {
    bucket = "my-team-terraform-state"
    prefix = "production/network"
  }
}
```

### Remote State設定時の注意点

- **backendブロックに変数は使えない**: `backend` ブロック内では `var.xxx` のような変数参照ができません。環境ごとに異なる設定が必要な場合は、`-backend-config` オプションまたは `.tfbackend` ファイルを使います
- **state用バケットのリージョン**: チームメンバーが主にアクセスするリージョンに配置すると、plan/applyの速度が向上します
- **.gitignore の設定**: `*.tfstate` と `*.tfstate.*` を `.gitignore` に追加し、stateファイルがリポジトリにコミットされないようにします

```bash
# .gitignore に追加
*.tfstate
*.tfstate.*
.terraform/
```

## 2. State Lockの重要性

### State Lockとは

State Lockは、Terraformの操作（plan、apply、destroyなど）を実行する際にstateファイルをロックし、他の操作が同時に実行されるのを防ぐ仕組みです。

### ロックがないと何が起きるのか

具体的なシナリオで考えてみましょう。

```
時刻  Aさん                        Bさん
─────────────────────────────────────────────────
10:00 terraform apply 開始
      stateを読み込み(v1)
10:01                               terraform apply 開始
                                    stateを読み込み(v1)
10:02 リソース作成完了
      stateを書き込み(v2)
10:03                               リソース作成完了
                                    stateを書き込み(v3)
                                    ← Aさんの変更(v2)が上書きされて消失！
```

この結果、Aさんが作成したリソースはAWSには存在するがTerraformのstateには記録されていない「孤立リソース」となります。次回のplanで予期しない差分が表示されたり、最悪の場合はリソースが二重に作成されたりします。

### State Lockの動作

S3 + DynamoDBバックエンドの場合、Terraformは以下の流れでロックを取得します。

1. `terraform plan` または `terraform apply` を実行
2. DynamoDBテーブルにロックレコードを作成（LockIDはstateファイルのパスに対応）
3. ロックが取得できたら処理を続行、既にロックされていればエラーを返す
4. 処理完了後にロックレコードを削除

ロックが取得できない場合、以下のようなエラーメッセージが表示されます。

```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      my-team-terraform-state/production/network/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.7.0
  Created:   2024-01-15 10:00:00.000000 +0000 UTC
```

### ロックが残ってしまった場合の対処

プロセスが異常終了した場合など、ロックが解放されずに残ることがあります。この場合は `terraform force-unlock` コマンドを使います。

```bash
$ terraform force-unlock <LOCK_ID>
```

ただし、**force-unlockは最後の手段です**。実行前に以下を必ず確認してください。

1. 本当に他の誰もTerraform操作を実行していないか（Slackなどで確認）
2. ロック情報に表示された `Who` と `Created` を確認し、該当の操作が本当に終了しているか
3. 可能であれば、ロックを作成した本人に状況を確認する

### CI/CDパイプラインでの考慮

CI/CDでTerraformを実行する場合も、State Lockは重要です。

- **パイプラインの同時実行を制限する**: GitHub ActionsのconcurrencyやGitLab CIのresource_groupを使い、同じstateに対する操作が同時に実行されないようにします
- **タイムアウトの設定**: CI/CDジョブにタイムアウトを設定し、異常時にロックが長時間保持されるのを防ぎます

```yaml
# GitHub Actions の例
jobs:
  terraform:
    concurrency:
      group: terraform-production-network
      cancel-in-progress: false  # 実行中のジョブはキャンセルしない
    steps:
      - uses: actions/checkout@v4
      - run: terraform apply -auto-approve
        timeout-minutes: 30
```

`cancel-in-progress: false` にしている理由は、実行中のapplyをキャンセルするとリソースが中途半端な状態になる可能性があるためです。後からトリガーされたジョブがキューで待機し、先行ジョブの完了後に実行されます。

## 3. State分割の考え方

### なぜStateを分割するのか

プロジェクトが成長すると、単一のstateファイルに数百のリソースが含まれるようになります。これにより以下の問題が生じます。

- **planが遅い**: すべてのリソースの現在の状態をAPIで確認するため、リソース数に比例して時間がかかる（数百リソースで数分以上になることも）
- **影響範囲が大きい**: 1つのstateにすべてが入っていると、VPCの設定変更のつもりがアプリケーションのリソースにも影響を与えるリスクがある
- **権限管理が困難**: ネットワーク担当とアプリケーション担当が同じstateにアクセスする必要があり、最小権限の原則に反する
- **ロック競合**: 複数のチームが同じstateを使うとロック待ちが頻発し、作業効率が低下する

### 分割の軸

stateを分割する際の代表的な軸は3つあります。

#### 軸1: 環境（Environment）

最も基本的な分割です。production、staging、developmentなど環境ごとにstateを分けます。

```
terraform-state/
├── production/terraform.tfstate
├── staging/terraform.tfstate
└── development/terraform.tfstate
```

これにより、staging環境への変更がproduction環境のstateに影響を与えることがなくなります。

#### 軸2: レイヤー（Layer）/ コンポーネント

同じ環境内でも、変更頻度やライフサイクルが異なるリソースは分割すべきです。

```
terraform-state/
└── production/
    ├── network/terraform.tfstate      # VPC, Subnet, Route Table（ほぼ変更しない）
    ├── database/terraform.tfstate     # RDS, ElastiCache（慎重に変更）
    ├── application/terraform.tfstate  # ECS, ALB（頻繁に変更）
    └── monitoring/terraform.tfstate   # CloudWatch, SNS（独立して変更）
```

分割の判断基準は以下の通りです。

| 基準 | 説明 |
|------|------|
| 変更頻度 | 頻繁に変更するリソースとほぼ変更しないリソースは分ける |
| ライフサイクル | 作成・削除のタイミングが異なるリソースは分ける |
| チーム境界 | 担当チームが異なるリソースは分ける |
| リスクレベル | 変更のリスクが高いもの（DB、ネットワーク）と低いもの（監視設定）は分ける |

#### 軸3: サービス / マイクロサービス

マイクロサービスアーキテクチャを採用している場合は、サービスごとにstateを分けることも有効です。

```
terraform-state/
└── production/
    ├── shared/
    │   ├── network/terraform.tfstate
    │   └── database/terraform.tfstate
    └── services/
        ├── user-api/terraform.tfstate
        ├── order-api/terraform.tfstate
        └── payment-api/terraform.tfstate
```

### State間のデータ参照: terraform_remote_state と data source

stateを分割すると、あるstateで作成したリソースの情報（VPCのIDなど）を別のstateから参照する必要が出てきます。これには主に2つの方法があります。

#### 方法1: terraform_remote_state

参照元のstateでoutputを定義し、参照先で `terraform_remote_state` データソースを使います。

```hcl
# network/outputs.tf（参照元）
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

```hcl
# application/main.tf（参照先）
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-team-terraform-state"
    key    = "production/network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_ecs_service" "app" {
  # ...
  network_configuration {
    subnets = data.terraform_remote_state.network.outputs.private_subnet_ids
  }
}
```

#### 方法2: データソースによる直接参照

AWSのリソースを `aws_vpc` や `aws_subnet` などのデータソースで直接検索する方法です。

```hcl
# application/main.tf
data "aws_vpc" "main" {
  tags = {
    Name = "production-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = "private"
  }
}
```

#### どちらを使うべきか

| 観点 | terraform_remote_state | データソース |
|------|----------------------|------------|
| 結合度 | stateのバックエンド設定に依存する | リソースのタグや名前に依存する |
| 型安全性 | outputの型がそのまま使える | フィルタ結果に依存するためやや不安定 |
| 他ツールとの互換 | Terraform同士のみ | CloudFormationなど他ツールで作成したリソースも参照可能 |
| 推奨ケース | 同一チーム内のstate間参照 | チーム横断、または非Terraform管理リソースの参照 |

実務では、同じリポジトリ・同じチーム内では `terraform_remote_state` を、チーム横断やTerraform以外で管理されたリソースの参照にはデータソースを使うのがバランスの良い選択です。

### 分割しすぎの罠

state分割にはメリットがありますが、やりすぎると逆効果です。

- **依存関係の管理が煩雑になる**: state間の依存が増えると、apply順序を管理する必要が出てくる
- **全体像が見えにくくなる**: リソースがどのstateに属しているかを把握するコストが増える
- **初期セットアップが面倒になる**: 新しい環境を構築する際に多数のstateを順番にapplyする必要がある

目安として、1つのstateに含まれるリソースが **50〜200個程度** になるように分割すると、plan速度と管理コストのバランスが取りやすくなります。stateの分割数は、チームの規模とリソース数に応じて調整してください。

## 実践的なディレクトリ構成例

ここまでの内容を踏まえた、チーム開発向けのディレクトリ構成例を示します。

```
infrastructure/
├── environments/
│   ├── production/
│   │   ├── network/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── backend.tf      # backend "s3" { key = "production/network/..." }
│   │   ├── database/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── backend.tf
│   │   └── application/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── backend.tf
│   └── staging/
│       └── ...（productionと同じ構造）
├── modules/                      # 再利用可能なモジュール
│   ├── vpc/
│   ├── rds/
│   └── ecs-service/
└── backend-setup/                # state管理用リソースの定義
    └── main.tf
```

各ディレクトリが独立したstateを持ち、それぞれ個別に `terraform init` / `plan` / `apply` を実行します。

## まとめ

| 項目 | やるべきこと |
|------|------------|
| Remote State | S3+DynamoDB（AWS）やGCSなど、チーム全員がアクセスできるリモートバックエンドを使う。バージョニングと暗号化を必ず有効にする |
| State Lock | リモートバックエンドのロック機構を必ず有効にする。CI/CDでは同時実行制限も設定する。`force-unlock` は最後の手段として慎重に使う |
| State分割 | 環境・レイヤー・サービスの軸で分割する。1 stateあたり50〜200リソース程度を目安にし、分割しすぎに注意する |

state管理は地味な作業ですが、ここを疎かにするとチームの生産性に直結します。最初にしっかり設計しておくことで、後から「stateが壊れた」「誰かの変更が消えた」といったトラブルを未然に防げます。

まずは現在のプロジェクトで以下をチェックしてみてください。

1. stateファイルはリモートに保存されているか
2. State Lockは有効になっているか
3. stateのリソース数は適切か（`terraform state list | wc -l` で確認）

1つでも「いいえ」があれば、この記事の該当セクションを参考に改善を始めましょう。
