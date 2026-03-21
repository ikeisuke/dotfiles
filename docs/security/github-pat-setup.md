# GitHub Fine-grained PAT セットアップガイド

AI エージェント（Claude Code, Codex, Kiro CLI）に渡す制限付き GitHub トークンの作成・保存手順。
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
| Token name | `claude-agent` (用途がわかる名前) |
| Expiration | 30 days（短めに設定、定期ローテーション） |
| Resource owner | 個人アカウント |
| Repository access | **Only select repositories**（必要なリポジトリだけ選択） |

4. Permissions（必要最小限を選択）:

| Permission | Level | 用途 |
|-----------|-------|------|
| Contents | Read-only | コード読み取り |
| Pull requests | Read and write | PR 作成（不要なら Read-only） |
| Issues | Read-only | Issue 参照 |
| Metadata | Read-only | 自動付与 |

**付けてはいけない Permission**:
- Administration（リポジトリ設定変更、ブランチ削除）
- Actions（ワークフロー実行）
- Workflows（.github/workflows の変更）
- Organization administration
- Members（メンバー管理）

5. **Generate token** → トークンをコピー

### GitHub Enterprise の場合

エンタープライズ管理者は追加の注意が必要:

- **Resource owner を個人アカウントにする**（Organization を選ばない）
- Organization の PAT を作る場合は管理者権限が付与されないことを確認
- Organization settings → Personal access tokens で Fine-grained PAT の利用を許可する必要がある場合あり
- `admin:org`, `admin:enterprise` スコープは **絶対に付与しない**

## 2. macOS Keychain に保存

```bash
# 保存
security add-generic-password \
  -s "claude-gh-token" \
  -a "$USER" \
  -w "ghp_xxxxxxxxxxxxxxxxxxxx"
```

確認:

```bash
# トークンが保存されているか確認
security find-generic-password -s "claude-gh-token" -a "$USER"

# トークンの値を表示（確認用）
security find-generic-password -s "claude-gh-token" -a "$USER" -w
```

## 3. トークンのローテーション

```bash
# 既存を削除して再作成
security delete-generic-password -s "claude-gh-token" -a "$USER"
security add-generic-password \
  -s "claude-gh-token" \
  -a "$USER" \
  -w "ghp_新しいトークン"
```

30 日ごとに GitHub で新しいトークンを生成し、Keychain を更新する。

## 4. 動作確認

```bash
# ラッパー経由で起動して確認（claude, codex, kiro-cli-chat 共通）
claude

# エージェント内で以下を実行して確認
# gh auth status → Fine-grained PAT が使われていることを確認
```

## トラブルシューティング

### "WARN: GitHub PAT 未設定" と表示される

Keychain にトークンが保存されていない。手順 2 を実行する。

### Permission denied エラー

PAT の権限が足りない。GitHub で PAT を編集し、必要な Permission を追加する。
ただし最小権限の原則を守り、必要なものだけ追加すること。

### Organization のリポジトリにアクセスできない

Fine-grained PAT の Resource owner が正しいか確認する。
Organization が Fine-grained PAT を許可しているか、Organization の管理者に確認する。
