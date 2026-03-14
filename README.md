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
- シンボリックリンク作成（gitconfig, git/ignore, zshenv, zprofile, zshrc, tmux/tmux.conf, vimrc, ghostty config, gh config, zeno config, claude keybindings）
- `~/.gitconfig.local` の対話的セットアップ（初回のみ）
- jj (jujutsu) の user 設定（git config から取得）
- zsh ファイルの zcompile（起動高速化）
- TPM (Tmux Plugin Manager) のインストール

## Structure

```
dotfiles/
├── Brewfile                # Homebrew 依存管理
├── setup.sh                # セットアップスクリプト
├── .gitignore              # このリポジトリの除外ルール
├── CLAUDE.md               # Claude Code プロジェクト設定
├── AGENTS.md               # AI エージェント向け運用ルール
├── HISTORY.md              # 変更履歴
├── apps/
│   ├── claude/             # Claude Code キーバインド設定
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
    ├── tools/              # ツール統合（fzf, volta, uv, go, zoxide, direnv 等）
    ├── os/                 # OS 固有設定（darwin.zsh, linux.zsh）
    └── integrations/       # 外部ツール統合（tmux, iterm2, AI fallback, kiro）
```

## Zsh 設定

### 読み込み順序

```
zshenv     → LANG, EDITOR, XDG 環境変数
zprofile   → Homebrew, Cargo, GPG
zshrc      → lib/ → tools/ (fzf, zeno, etc.) → os/ → integrations/ → starship → ~/.zshrc.local
```

### Zsh プラグイン

- **zsh-autosuggestions**: Fish ライクなコマンド入力候補（グレー表示、→ で確定）
- **zsh-fast-syntax-highlighting**: コマンドライン構文ハイライト

いずれも Homebrew でインストール、`zsh/tools/zsh-plugins.zsh` で読み込み。

### キーバインド

| キー | 機能 |
|------|------|
| `Ctrl+]` | zoxide インタラクティブジャンプ (zi) |
| `Space` | zeno スニペット展開（gs → git status 等） |
| `Tab` | zeno fuzzy 補完 |
| `Ctrl+r` | zeno 履歴検索 |
| `Ctrl+t` | fzf ファイル検索（bat プレビュー付き） |
| `Alt+c` | fzf ディレクトリ検索（eza プレビュー付き）※macOS は要ターミナル設定 |
| `Ctrl+s` | zeno スニペット一覧から選択 |
| `Ctrl+g` | zeno ghq リポジトリ選択 |

### エイリアス

| エイリアス | 展開先 | 備考 |
|-----------|--------|------|
| `ls` | `eza --icons --git` | eza がなければ素の ls |
| `ll` | `eza --icons --git -l` | |
| `la` | `eza --icons --git -a` | |
| `lt` | `eza --icons --git --tree` | |
| `cat` | `bat --style=plain` | フルパス展開で sudo 対応 |
| `rm/cp/mv` | `-i` 付き | 安全確認 |

### zeno スニペット & 補完

Space キーで展開されるスニペット:

| キーワード | 展開 |
|-----------|------|
| `gs` | `git status` |
| `gc` | `git commit -m ''` |
| `gd` | `git diff` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `dkc` | `docker compose` |
| `q` | `kiro-cli-chat` |

Tab キーで起動する fuzzy 補完: `git add/switch/checkout/branch -d/rebase/restore/stash/diff`、`docker compose`、`brew install/uninstall`、`kill`、`kiro-cli --agent`

### タブタイトル

ディレクトリ移動時にターミナルのタブタイトルをカレントディレクトリ名に自動設定（OSC エスケープシーケンス、iTerm2 / Ghostty 等対応）。

### コマンド実行時間

すべてのコマンド実行後に開始時刻・終了時刻・所要時間を表示:

```
[start: 14:23:45, end: 14:23:48, took: 3s]
```

`zsh/datetime` モジュールを使用し、外部コマンド呼び出しなしで動作。

### AI コマンドフォールバック

コマンドが見つからない場合、入力に日本語が一定比率以上含まれていれば AI CLI に自動転送。

- デフォルト送信先: `codex`（`AI_FALLBACK_TARGET` で `claude` / `kiro-cli` 等に変更可能）
- `AI_FALLBACK_INTERACTIVE`（デフォルト 1）で対話/非対話モードを切替
- `AI_JP_RATIO_THRESHOLD`（デフォルト 0.35）、`AI_MIN_LEN`（デフォルト 6）で判定を調整可能

## Git 設定

- **git-delta**: Dracula テーマの side-by-side diff
- **pull.rebase = true**: pull 時に自動 rebase
- **rebase.autostash = true**: rebase 前に自動 stash
- **push.autoSetupRemote = true**: 初回 push で自動的にリモート追跡
- **merge.conflictStyle = zdiff3**: 3-way マージコンフリクト表示
- **help.autocorrect = prompt**: タイポ時に修正候補を提示
- **ローカル設定**: `~/.gitconfig.local` に個人情報（git 管理外）

```bash
# エイリアス
git st     # status
git co     # checkout
git br     # branch
git ci     # commit
git lg     # pretty log graph
```

## Tmux 設定

プレフィックスは `C-z`。モジュラー構成（base, keys, theme, plugins, os別）。

### キーバインド

| キー | 機能 |
|------|------|
| `C-z -` | 水平分割 |
| `C-z \` | 垂直分割 |
| `Alt+h/j/k/l` | ペイン移動（プレフィックス不要） |
| `C-z H/J/K/L` | ペインリサイズ |
| `Alt+n/p` | ウィンドウ切り替え |
| `C-z Tab` | 直前のウィンドウ |
| `C-z r` | 設定リロード |

### プラグイン (TPM)

- **tmux-yank**: システムクリップボード連携
- **tmux-resurrect**: セッション保存・復元
- **tmux-continuum**: 15分ごとの自動保存・起動時の自動復元

## ターミナル設定

### iTerm2（メイン）

fzf の `Alt+C` を使うには **Preferences > Profiles > Keys > General > Left Option key → Esc+** に設定が必要。

### Ghostty

- **フォント**: JetBrains Mono 14pt（Ghostty 内蔵、Nerd Font グリフ対応）
- **テーマ**: Everforest Dark Hard / Light Medium（システムの外観に連動）
- **外観**: tabs スタイル、半透明背景（0.95）、ブラー
- **shell integration**: starship との競合を避けるため cursor 機能を無効化
- **`macos-option-as-alt = left`**: fzf の Alt+C が動作するために必須
- **キーバインド**: cmd+1-9 を unbind（tmux のウィンドウ管理と競合するため）

## Starship プロンプト

シングルラインのミニマルなプロンプト:

```
~/dotfiles  main !1+2 %
```

- ディレクトリ（3階層まで）、git ブランチ、git ステータス
- 言語モジュール（aws, nodejs, python 等）は速度のため無効化
- starship 未インストール時は vcs_info ベースのフォールバックプロンプトを使用

## Vim 設定

- **vim-plug**: プラグインマネージャー（自動インストール）
- **fzf.vim**: `<C-p>` でファイル検索、`<leader>r` で ripgrep
- **vim-fugitive / vim-gitgutter**: Git 統合
- **vim-commentary / vim-surround**: 編集補助
- **everforest**: カラースキーム
- **リーダーキー**: `,`

## 開発ツール

| ツール | 用途 |
|--------|------|
| **mise** | ポリグロットランタイムマネージャー（Brewfile に登録済み、シェル初期化は未実装。volta から移行予定） |
| **volta** | Node.js バージョン管理（legacy、mise に移行中） |
| **uv** | Python パッケージ・バージョン管理 |
| **go** | Go 言語 |
| **rustup** | Rust ツールチェーン（公式インストーラーで管理） |
| **deno** | zeno.zsh のランタイム（公式インストーラーで管理） |
| **zeno.zsh** | Deno 製 fuzzy 補完 & スニペット展開 |
| **direnv** | ディレクトリ別の環境変数 |
| **gh** | GitHub CLI |
| **jj** | Git 互換 VCS (jujutsu) |
| **git-delta** | Git diff ビューア |
| **git-secret** | Git シークレット管理 |
| **awscli / aws-cdk** | AWS ツール |
| **pulumi** | Infrastructure as Code |
| **claude-code / codex / kiro-cli / gemini-cli** | AI CLI ツール |

## カスタマイズ

### ローカルオーバーライド

```bash
# ~/.zshrc.local（git 管理外）
export MY_VAR="value"
alias myalias="command"
```

### Git ローカル設定

```bash
# ~/.gitconfig.local（git 管理外）
[user]
  name = Your Name
  email = your@email.com
```

SSH 署名や `includeIf` によるディレクトリ別設定は `apps/git/gitconfig.local.example` を参照。

## 設計方針

- **Graceful degradation**: すべてのツールを `command -v` でチェック。未インストールでもエラーにならない
- **XDG 準拠（可能な範囲）**: HISTFILE, npm, cargo, rustup 等を XDG パスに配置。例外: `~/.volta`（公式未対応）、`~/.deno`（公式インストーラー）
- **高速起動**: zsh ファイルを `.zwc` にプリコンパイル、変更時に自動再コンパイル
- **クロスプラットフォーム**: macOS (Apple Silicon / Intel) と Linux に対応
- **秘密情報の分離**: `~/.gitconfig.local`, `~/.zshrc.local` は git 管理外

## Platform Notes

### Linux

- Linuxbrew 対応（`zshenv` で自動検出）
- WSL 検出時に Windows 側のブラウザ・PowerShell を PATH に追加
- Brewfile の Linux ブロックで WSL 向けツールを追加インストール（k9s, kubectl, aws-iam-authenticator, cloudformation-guard, yq, remarshal）
- eza のアイコン表示には Nerd Font が必要（macOS では Brewfile の `font-jetbrains-mono-nerd-font` で導入済み、Linux では別途インストール）

## License

MIT
