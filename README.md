# Dotfiles

macOS / Linux 対応のモジュラーな dotfiles。

## Quick Start

```bash
# 1. Clone (ghq 推奨)
ghq get ikeisuke/dotfiles
cd "$(ghq root)/github.com/ikeisuke/dotfiles"

# ghq がない場合
# git clone https://github.com/ikeisuke/dotfiles.git ~/repos/github.com/ikeisuke/dotfiles
# cd ~/repos/github.com/ikeisuke/dotfiles

# 2. Install dependencies & setup
./setup.sh
```

`setup.sh` は以下を実行します:

- `brew bundle` で Brewfile の依存をインストール（macOS）
- rustup / deno を公式インストーラーで導入（Homebrew 版は循環依存・FFI 不整合のため不使用）
- レガシーパス（`~/.cargo`, `~/.rustup`）の XDG 準拠パスへの自動移行
- 既存ファイルの自動バックアップ（`~/.dotfiles_backup/<timestamp>/` に退避）
- シンボリックリンク作成（各種設定ファイル）
- `~/.gitconfig.local` の対話的セットアップ（初回のみ）
- zsh ファイルの zcompile（起動高速化）
- TPM (Tmux Plugin Manager) のインストール

## Structure

```
dotfiles/
├── Brewfile                # Homebrew 依存管理
├── setup.sh                # セットアップスクリプト
├── docs/                   # 詳細ドキュメント
├── apps/
│   ├── claude/             # Claude Code キーバインド設定
│   ├── fzf/                # fzf デフォルトオプション & テーマ
│   ├── gh/                 # GitHub CLI 設定
│   ├── ghostty/            # Ghostty ターミナル設定
│   ├── git/                # Git 設定 + グローバル gitignore + local config テンプレート
│   ├── starship/           # Starship プロンプト設定
│   ├── tmux/               # Tmux 設定（モジュラー構成）
│   ├── vim/                # Vim 設定 + vim-plug
│   └── zeno/               # zeno.zsh スニペット & 補完設定
└── zsh/
    ├── zshenv              # 環境変数（全 zsh で読み込み）
    ├── zprofile            # ログインシェル設定
    ├── zshrc               # インタラクティブシェル設定（モジュールローダー）
    ├── lib/                # コア機能（aliases, completion, history, keybinds 等）
    ├── tools/              # ツール統合（mise, fzf, uv, go, zoxide, direnv 等）
    ├── os/                 # OS 固有設定（darwin.zsh, linux.zsh）
    └── integrations/       # 外部ツール統合（tmux, iterm2, AI fallback, kiro）
```

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [Zsh 設定](docs/zsh.md) | プラグイン、キーバインド、エイリアス、zeno スニペット、起動高速化 |
| [Git 設定](docs/git.md) | エイリアス、fixup ワークフロー、delta、ローカル設定パターン |
| [ターミナル & エディタ](docs/terminal.md) | Ghostty、iTerm2、Starship プロンプト、Vim |
| [開発ツール](docs/tools.md) | mise（ランタイム管理）、uv、lazygit、fzf、AI CLI ツール |
| [Tmux 設定](docs/tmux.md) | キーバインド、セッション永続化、iTerm2 統合 |
| [Git ローカル設定ガイド](docs/git-local.md) | マシン別・組織別の includeIf パターン |

## 設計方針

- **Graceful degradation**: すべてのツールを `command -v` でチェック。未インストールでもエラーにならない
- **XDG 準拠**: HISTFILE, cargo, rustup 等を XDG パスに配置
- **高速起動**: `.zwc` プリコンパイル、zrecompile の 1 日 1 回チェック、補完キャッシュ
- **クロスプラットフォーム**: macOS (Apple Silicon / Intel) と Linux に対応
- **秘密情報の分離**: `~/.gitconfig.local`, `~/.zshrc.local` は git 管理外

## カスタマイズ

```bash
# ~/.zshrc.local（git 管理外）
export MY_VAR="value"
alias myalias="command"

# ~/.gitconfig.local（git 管理外）
# → 詳細は apps/git/README.md を参照
```

## Platform Notes

### Linux

- Linuxbrew 対応（`zshenv` で自動検出）
- WSL 検出時に Windows 側のブラウザ・PowerShell を PATH に追加
- Brewfile の Linux ブロックで WSL 向けツール（k9s, kubectl 等）を追加インストール
- eza のアイコン表示には Nerd Font が必要（Linux では別途インストール）

## License

MIT
