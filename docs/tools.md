# 開発ツール

## ランタイム管理

### mise（メイン）

ポリグロットランタイムマネージャー。Node.js, Python, Go, Rust 等を統一管理する。

```bash
# Node.js のインストール
mise install node@lts
mise use --global node@lts

# プロジェクト単位でバージョン固定
cd my-project
mise use node@20
# → .tool-versions が作成される
```

プロジェクトの `.tool-versions` や `mise.toml` を検知して自動的にバージョンを切り替える。チーム開発での再現性が高い。

設定: `zsh/tools/mise.zsh` で `eval "$(mise activate zsh)"` により有効化。

### uv（Python）

高速な Python パッケージ・バージョンマネージャー。pip の代替。

```bash
uv pip install requests     # pip install の高速版
uv venv                     # 仮想環境の作成
uv run script.py            # 依存を自動解決して実行
```

シェル補完はファイルキャッシュ化されており、起動時のオーバーヘッドはない。

### rustup / deno

- **rustup**: Rust ツールチェーン。公式インストーラーで管理（Homebrew 版は循環依存のため不使用）
- **deno**: zeno.zsh のランタイム。公式インストーラーで管理（Homebrew 版は FFI 不整合のため不使用）

## Git ツール

### lazygit

ターミナル上の Git TUI。以下の操作がキー 1 つでできる:

- ファイルツリーを見ながら hunk 単位でステージング
- コミットグラフ上でインタラクティブ rebase（fixup, squash, reword, reorder）
- コンフリクトを左右分割ビューで解決
- stash の管理（apply, drop, branch 作成）

```bash
lazygit    # カレントリポジトリで起動
```

### git-delta

git diff の出力を side-by-side 表示、構文ハイライト付きに変換する pager。`apps/git/gitconfig` で `core.pager = delta` として設定済み。

### jj (jujutsu)

Git 互換の新しいバージョン管理システム。Git リポジトリをそのまま操作できる。

## ナビゲーション

### fzf

汎用 fuzzy finder。以下のシェルインテグレーションが有効:

| キー | 機能 |
|------|------|
| `Ctrl+t` | ファイル検索（bat/eza によるプレビュー付き） |
| `Alt+c` | ディレクトリ検索（eza によるプレビュー付き） |
| `Ctrl+r` | コマンド履歴検索 |

デフォルトオプション（テーマ・レイアウト）は `apps/fzf/fzfrc` で設定。Everforest テーマに合わせた配色を適用している。ファイル検索には `fd` を使用（`.git` 除外、隠しファイル対応）。

### zoxide

`cd` の賢い代替。訪問頻度を学習して部分一致でジャンプ:

```bash
z dotfiles       # 最もよく使う "dotfiles" を含むディレクトリにジャンプ
zi               # インタラクティブ選択（Ctrl+] にもバインド）
```

### ghq

リポジトリを `~/repos/github.com/<org>/<repo>/` のような統一パスで管理:

```bash
ghq get ikeisuke/dotfiles   # clone
ghq list                     # 管理下のリポジトリ一覧
# Ctrl+g で zeno による fuzzy リポジトリ選択
```

## AI CLI ツール

| ツール | 用途 |
|--------|------|
| **claude-code** | Anthropic Claude — コーディングエージェント |
| **codex** | OpenAI Codex — コーディングエージェント |
| **opencode** | OpenCode — マルチプロバイダー対応コーディングエージェント |
| **kiro-cli** | Amazon Kiro — コーディングエージェント |
| **gemini-cli** | Google Gemini — コーディングエージェント |

ターミナルで日本語テキストを入力してコマンドが見つからない場合、自動的に AI CLI に転送される（[AI コマンドフォールバック](zsh.md#ai-コマンドフォールバック)）。

## インフラ・クラウド

| ツール | 用途 |
|--------|------|
| **awscli / aws-cdk** | AWS CLI & CDK |
| **pulumi** | Infrastructure as Code |
| **direnv** | ディレクトリ別の環境変数（`.envrc`） |
| **git-secret** | Git リポジトリでの秘密情報管理 |

## ユーティリティ

| ツール | 用途 |
|--------|------|
| **ripgrep** (`rg`) | 高速 grep（fzf プレビュー、vim プラグインで使用） |
| **bat** | 構文ハイライト付き cat（fzf プレビューで使用） |
| **eza** | モダンな ls（アイコン、git ステータス表示） |
| **fd** | 高速 find（fzf のファイル検索で使用） |
| **jq / dasel** | JSON / YAML / TOML プロセッサ |
| **gh** | GitHub CLI |
