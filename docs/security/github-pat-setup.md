# GitHub Fine-grained PAT セットアップガイド

AI エージェント（Claude Code, Codex, Kiro CLI, Gemini CLI）に渡す制限付き GitHub トークンの作成・保存手順。
セキュリティラッパー（`bin/_credential-guard.sh`）が Keychain からトークンを取得して注入する。

## なぜ必要か

- `gh auth login` で取得したトークンは全権限を持つ
- エンタープライズ管理者のトークンは特に危険（組織全体に影響）
- Fine-grained PAT でリポジトリ・権限を最小限に絞る

## 1. Fine-grained PAT の作成

### GitHub.com の場合

1. https://github.com/settings/tokens?type=beta にアクセス
2. **Generate new token** をクリック
3. 以下を設定:

| 項目 | 設定 |
|------|------|
| Token name | `ai-agent` (用途がわかる名前) |
| Expiration | 30 days（短めに設定、定期ローテーション） |
| Resource owner | 個人アカウント |
| Repository access | **Only select repositories**（必要なリポジトリだけ選択） |

4. Permissions（必要最小限を選択）:

| Permission | Level | 用途 |
|-----------|-------|------|
| Contents | Read and write | コード読み書き |
| Pull requests | Read and write | PR 作成 |
| Issues | Read-only | Issue 参照 |
| Metadata | Read-only | 自動付与 |
| Workflows | Read and write | `.github/workflows` の変更（※前提条件あり） |

> **Workflows 権限の前提条件**: main ブランチにブランチ保護ルールを設定し、
> 直接 push を禁止・PR 必須にすること。これにより、エージェントが CI 定義を
> 変更する PR を作成できるが、main に直接マージはできない（Layer 3: サービス側制限）。

**付けてはいけない Permission**:
- Administration（リポジトリ設定変更、ブランチ削除）
- Actions（ワークフロー実行・トリガー）
- Organization administration
- Members（メンバー管理）

5. **Generate token** → トークンをコピー

### GitHub Enterprise の場合

エンタープライズ管理者は追加の注意が必要:

- **Resource owner を個人アカウントにする**（Organization を選ばない）
- Organization の PAT を作る場合は管理者権限が付与されないことを確認
- Organization settings → Personal access tokens で Fine-grained PAT の利用を許可する必要がある場合あり
- `admin:org`, `admin:enterprise` スコープは **絶対に付与しない**

## 2. ブランチ保護ルールの設定（前提条件）

Workflows 権限を PAT に付与する場合、対象リポジトリに以下のブランチ保護を設定する:

1. リポジトリの **Settings → Branches → Add branch protection rule**
2. Branch name pattern: `main`（または `master`）
3. 以下を有効化:
   - **Require a pull request before merging**
   - **Require approvals**（1人以上の承認を推奨）
   - **Do not allow bypassing the above settings**

これにより、エージェントが `.github/workflows` を変更する PR を作成できるが、
レビューなしに main へマージすることはできない。

## 3. macOS Keychain にトークンを保存

```bash
# 保存
security add-generic-password \
  -s "ai-agent-gh-token" \
  -a "$USER" \
  -w "ghp_xxxxxxxxxxxxxxxxxxxx"
```

確認:

```bash
# トークンが保存されているか確認
security find-generic-password -s "ai-agent-gh-token" -a "$USER"

# トークンの値を表示（確認用）
security find-generic-password -s "ai-agent-gh-token" -a "$USER" -w
```

## 4. トークンのローテーション

```bash
# 既存を削除して再作成
security delete-generic-password -s "ai-agent-gh-token" -a "$USER"
security add-generic-password \
  -s "ai-agent-gh-token" \
  -a "$USER" \
  -w "ghp_新しいトークン"
```

30 日ごとに GitHub で新しいトークンを生成し、Keychain を更新する。

## 5. 動作確認

```bash
# ラッパー経由で起動して確認（claude, codex, kiro-cli, gemini 共通）
claude

# エージェント内で以下を実行して確認
# gh auth status → Fine-grained PAT が使われていることを確認
```

## トラブルシューティング

### "WARN: GitHub PAT 未設定" と表示される

Keychain にトークンが保存されていない。手順 3 を実行する。

### Permission denied エラー

PAT の権限が足りない。GitHub で PAT を編集し、必要な Permission を追加する。
ただし最小権限の原則を守り、必要なものだけ追加すること。

### Organization のリポジトリにアクセスできない

Fine-grained PAT の Resource owner が正しいか確認する。
Organization が Fine-grained PAT を許可しているか、Organization の管理者に確認する。
