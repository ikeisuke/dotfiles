# Change History

## 2026-03-20 Claude Code ステータスライン対応

### apps/claude/statusline.py (新規)
- Braille dots パターンでAPIレート制限をステータスバーに表示するスクリプトを追加
- コンテキスト使用率(ctx)、5時間枠(5h)、7日枠(7d)をTrueColorグラデーション付きで表示
- 参考: https://nyosegawa.com/posts/claude-code-statusline-rate-limits/

### apps/claude/settings.json
- `statusLine` 設定を追加（`~/.claude/statusline.py` をコマンドとして実行）

### setup.sh
- `statusline.py` のシンボリックリンク作成と実行権限付与を追加

## 2026-03-19 zeno補完の部分入力対応・細かな改善

### zsh/tools/zeno.zsh
- ZLEラッパーウィジェット `_zeno-completion-with-query` を追加
- `git switch ma<tab>` のように部分入力がある状態でfzf補完を使った際、入力済みテキストがfzfの初期クエリに渡され、選択結果が正しく挿入されるよう修正
- 対象: git switch/checkout/rebase/restore/add/diff, git branch -d/-D

### apps/zeno/config.yml
- git補完パターンに `(?!-)` 負先読みを追加し、オプション（`-c` 等）入力時にfzf補完が誤発動しないよう修正

### zsh/tools/zsh-plugins.zsh
- Escape キーで zsh-autosuggestions のサジェストをクリアするキーバインド追加

### apps/git/gitignore
- `.claude/settings.local.json` を gitignore に追加

## 2026-03-15 CLAUDE.md を dotfiles 管理に追加

### apps/claude/CLAUDE.md (新規)
- `~/.claude/CLAUDE.md`（グローバル指示）を dotfiles で管理開始
- 既存の2セクション（シェルエイリアス回避、セッションタイトル自動設定）を移行
- 新規セクション追加: `$(...)` コマンド置換の回避ルール（allow ルールの安全ヒューリスティクス対策）

### apps/claude/settings.json
- PreToolUse フック追加: `$(...)` を含む Bash コマンドをブロック（exit 2）し `-m` フラグ形式へリトライさせる
- ref: https://github.com/anthropics/claude-code/issues/31373

### setup.sh
- Claude Code セクションに `CLAUDE.md` のシンボリックリンクを追加
- `claude plugins install/update` によるプラグイン管理を追加（新規マシン対応）

## 2026-03-15 Claude Code settings.json を dotfiles 管理に追加

### apps/claude/settings.json (新規)
- `~/.claude/settings.json` を dotfiles で管理開始
- env, hooks, plugins, marketplaces 等の設定を含む
- センシティブ情報（API キー等）は含まれていないことを確認済み

### setup.sh
- Claude Code セクションに `settings.json` のシンボリックリンクを追加

## 2026-03-14 モダン化: mise 移行・起動高速化・Git 強化・fzf config・ドキュメント分割

### zsh/tools/mise.zsh (新規)
- mise の shell 有効化を追加（`eval "$(mise activate zsh)"`）
- Brewfile に `mise` があったがシェルで未有効化だったバグを修正

### zsh/tools/volta.zsh (削除)
- mise に完全移行のため Volta を削除

### Brewfile
- `volta` と `node` (Homebrew 版) を削除、`mise` に一本化
- `lazygit` を追加

### apps/git/gitconfig
- `[rebase] autosquash = true` を追加（fixup コミットの自動整列）
- エイリアス追加: `fixup`, `amend`, `unstage`, `last`, `wt`, `sync`

### apps/fzf/fzfrc (新規)
- fzf のデフォルトオプションをネイティブ config ファイルに分離
- Everforest テーマカラー、レイアウト設定

### zsh/tools/fzf.zsh
- `FZF_DEFAULT_OPTS_FILE` によるネイティブ config 読み込みを追加

### zsh/lib/profile.zsh (新規)
- `ZSH_PROFILE=1 zsh -i -c exit` でプロファイリング可能に
- `zsh-profile` コマンドを追加

### zsh/lib/zcompile.zsh
- 毎回の zrecompile チェックを1日1回に最適化（マーカーファイル方式）
- 起動速度の改善（zprof で 38% を占めていた）

### zsh/tools/uv.zsh
- `eval "$(uv generate-shell-completion zsh)"` をファイルキャッシュ化
- uv バイナリ更新時のみ再生成

### setup.sh
- fzf config の symlink を追加

### README.md
- 278 行 → 約 100 行に圧縮。詳細は docs/ に分離
- Structure にドキュメントリンク表を追加
- 開発ツール表、設定詳細は各 docs ファイルに移動

### docs/ (新規)
- `docs/zsh.md`: Zsh 設定詳細（プラグイン、キーバインド、エイリアス、起動高速化）
- `docs/git.md`: Git 設定詳細（エイリアス、fixup ワークフロー、worktree の使い方）
- `docs/git-local.md`: `apps/git/README.md` から移動（includeIf パターン）
- `docs/tmux.md`: `apps/tmux/README.md` から移動（セッション永続化、iTerm2 統合）
- `docs/terminal.md`: ターミナル & エディタ（Ghostty、iTerm2、Starship、Vim）
- `docs/tools.md`: 開発ツール（mise、lazygit、fzf、AI CLI ツール、ユーティリティ）

### zsh/tools/zsh-plugins.zsh
- Homebrew 依存から git-clone パターンに移行（zeno と同じ方式）
- `$XDG_DATA_HOME/zsh/plugins/` にクローン、`update-zsh-plugins` で一括更新
- Linux (Homebrew なし) でもプラグインが動作するように

### Brewfile
- `zsh-autosuggestions`, `zsh-fast-syntax-highlighting` を削除（git-clone に移行）

### .github/workflows/lint.yml (新規)
- shellcheck による setup.sh の lint
- `zsh -n` による全 zsh ファイルのシンタックスチェック

### ドリフト修正
- `docs/zsh.md`: `lla`, `mkdir`, `sudo` エイリアスを追記
- `zsh/lib/aliases.zsh`: `q` エイリアスの重複に意図を示すコメントを追加
- `README.md`: Structure ツリーから volta の残留参照を修正

## 2026-03-12 公開準備: gcd 統合・README 更新・setup.sh 出力改善

### zsh/functions/gcd.zsh (削除)
- zeno の `Ctrl+x Ctrl+f` (ghq-cd) と機能重複のため削除

### zsh/lib/keybinds.zsh
- `^g` (gcd) バインドを削除

### README.md
- Quick Start を `ghq get` 推奨に変更
- 開発ツール表を Brewfile に合わせて更新（mise, deno, git-delta, git-secret, AI CLI 追加）
- Ghostty「メインターミナル」→ iTerm2 メイン + Ghostty サブの構成に修正
- `Alt+C` の macOS 注記（要ターミナル設定）を追加
- zeno スニペット & fuzzy 補完の一覧を追加
- タブタイトル自動設定の説明を追加
- AI コマンドフォールバックの説明を追加
- setup.sh の rustup/deno 公式インストーラー使用の理由を追記
- Linux Platform Notes に WSL 向けツール群を追記

### setup.sh
- legacy paths チェック後に `✓ No legacy paths to migrate` を表示
- jj 設定出力からメールアドレスを非表示に
- Tmux の大きな囲みブロックを簡素化（TPM 初回時のみガイド表示）
- symlink パスを `~` / `<dotfiles>` で短縮表示

## 2026-03-12 Brewfile 整理

### Brewfile
- `git` を Core tools に追加（システム版が古いため brew 版を明示管理）
- `git-secret` を Utilities に追加
- `codex` を macOS ブロックからクロスプラットフォームに移動
- Linux (WSL) ブロックを新設: `k9s`, `kubernetes-cli`, `aws-iam-authenticator`, `cloudformation-guard`, `yq`, `remarshal`
- 不要パッケージをアンインストール: `goenv`, `pyenv`, `rbenv`, `tfenv`（mise に移行）、`poetry`, `jsonnet`, `marp-cli`, `tidy-html5`, `peco`, `tree`, `node@24`

## 2026-03-12 rustup セットアップ修正

### setup.sh
- legacy `~/.cargo` 残骸（`env/` ディレクトリのみ残存）のクリーンアップ処理を追加
- rustup インストール後に `$CARGO_HOME/env` を source して現セッションの PATH を通すように修正
- active toolchain 未設定時に `rustup default stable` を自動実行するように修正

## 2026-03-12 コードレビュー指摘修正

### zsh/integrations/ai_command_fallback.zsh
- `_ai_send` 失敗時に `return 0` → `return $?` に修正（失敗を隠さないように）

### setup.sh
- バックアップファイル名を `basename` からフルパスベースに変更（同名ファイルの上書き防止）
- `set -e` 下で zcompile 失敗時にセットアップが中断しないよう `if` で囲む

### zsh/tools/zeno.zsh
- トップレベルの `local` を通常変数 + `unset` に変更

### zsh/lib/aliases.zsh
- `cat` alias のパス固定（`$(command -v bat)`）を `bat` に変更

### apps/git/README.md
- `pull.rebase` の記述を `false` → `true` に修正
- `conflictStyle` を `diff3` → `zdiff3` に修正

### README.md
- シンボリックリンク一覧を実際の setup.sh に合わせて更新

---

## 2026-03-12 リポジトリ公開準備

### README.md
- クローン URL を `yourusername` から `ikeisuke` に更新
- zeno.zsh のキーバインド・構成情報を追加
- `apps/claude/`, `apps/zeno/` を Structure に追加

### .gitignore
- `.env*`, `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*`, `.aws/`, `.ssh/`, `credentials*` を追加（安全策）

---

## 2026-03-12 deno を公式インストーラー版に移行

### 原因
- Linuxbrew 版 deno の `libffi.so.8` / `libsqlite3.so.0` と zeno の FFI プラグインの間でライブラリ不整合が発生し SIGSEGV
- zeno のソケットサーバーが起動できない問題の根本原因

### Brewfile
- `deno` を削除（Linuxbrew 版は FFI 不整合で SEGV するため）

### zsh/zshenv
- `DENO_INSTALL` と `~/.deno/bin` の PATH 追加（公式インストーラー版を使用）

### apps/zeno/config.yml
- kiro agent 補完を統合・簡素化（ファイルシステムから直接 agent 名を取得）

---

## 2026-03-12 AI コマンドフォールバック追加

### zsh/integrations/ai_command_fallback.zsh (新規)
- コマンド未定義時に `command_not_found_handler` で捕捉し、日本語比率が一定以上の入力を AI CLI に転送
- デフォルト送信先を `kiro-cli` にし、`AI_FALLBACK_TARGET` で `codex` / `claude` / `kiro-cli-chat` へ上書き可能
- `AI_JP_RATIO_THRESHOLD` と `AI_MIN_LEN` を環境変数で調整可能

### zsh/zshrc
- `integrations/ai_command_fallback.zsh` の読み込みを追加

---

## 2026-03-11 zeno.zsh 導入（fuzzy 補完 & スニペット展開）

### Brewfile
- `deno` を追加（zeno.zsh のランタイム）→ 後に公式版に移行

### zsh/tools/zeno.zsh (新規)
- zeno.zsh の自動インストール（`$XDG_DATA_HOME/zeno` に git clone）
- Deno キャッシュを XDG 準拠に設定（`$XDG_CACHE_HOME/deno`）
- bat/eza をプレビューに活用
- キーバインド設定：Space（スニペット展開）、Tab（fuzzy 補完）、Ctrl+r（履歴検索）、Ctrl+x Ctrl+s（スニペット挿入）、Ctrl+x Ctrl+f（ghq cd）

### apps/zeno/config.yml (新規)
- 頻出コマンドのスニペット（gs, gc, gd, gp, gpl, dkc, q）
- Git 操作の fuzzy 補完（add, switch, checkout, branch -d, rebase, restore, stash, diff）
- Docker / Brew / kill / Kiro CLI のカスタム補完

### zsh/zshrc
- `zeno.zsh` の読み込みを追加（fzf の後、zsh-plugins の前）

### zsh/zshenv
- `DENO_DIR` を XDG 準拠で追加

### setup.sh
- zeno config のシンボリックリンク作成を追加

---

## 2026-03-10 ターミナルタブタイトルの自動設定

### zsh/lib/tab_title.zsh (新規)
- `chpwd` フックでディレクトリ変更時にターミナルのタブタイトルをカレントディレクトリ名に設定
- OSC 1 エスケープシーケンスを使用（iTerm2, WezTerm, Ghostty 対応）

### zsh/zshrc
- `tab_title.zsh` の読み込みを追加

---

## 2026-02-21 (10) 全体改善・バグ修正

### apps/tmux/tmux.conf
- `readlink -f` を `readlink` に変更（macOS 互換。`-f` は GNU 拡張で macOS に存在しない）

### apps/tmux/base.conf
- ハードコードされた `default-shell /bin/zsh` と `default-command /bin/zsh` を削除（tmux.conf の `${SHELL} -l` と競合していた）

### setup.sh
- `link_and_backup` にエラーハンドリングを追加（バックアップ・シンボリックリンク失敗時に報告）
- zsh コンパイルの `2>/dev/null` を削除し、失敗時に警告を表示するように変更

### zsh/zprofile
- `GPG_TTY=$(tty)` を条件付きに変更（非対話シェルでの失敗を防止）

### zsh/tools/fzf.zsh, zsh/os/darwin.zsh, zsh/tools/zsh-plugins.zsh
- `$(brew --prefix)` を `$HOMEBREW_PREFIX` に置き換え（起動時のサブシェル呼び出しを削減）

### zsh/zshrc
- `WORDCHARS` の重複文字（`*?#%^` が二重定義）を修正

### zsh/integrations/kiro.zsh
- `command -v kiro` ガードを追加（kiro 未インストール時のエラー防止）

### zsh/tools/volta.zsh
- `VOLTA_HOME` をデフォルト値付きに変更、非 XDG の理由をコメント追記

### zsh/tools/ghq.zsh
- `GHQ_ROOT` をデフォルト値付きに変更（環境変数での上書きを許可）

---

## 2026-02-21 (9) $HOME 精査 & gh 設定管理

### apps/gh/config.yml (新規)
- GitHub CLI の設定ファイルを dotfiles 管理下に追加
- `~/.config/gh/config.yml` へのシンボリックリンクで管理（hosts.yml は秘密情報のため対象外）

### setup.sh
- gh config のシンボリックリンク作成を追加

### $HOME クリーンアップ
- `~/.zprofile.zwc.old`, `~/.zshenv.zwc.old` を削除（古い zsh コンパイルキャッシュ）

### AGENTS.md, README.md
- apps/ の一覧に gh, ghostty を追加

---

## 2026-02-21 (8) 不要ファイルの掃除

### old_dotfiles/ (削除)
- リファクタリング前の旧設定アーカイブを削除（アクティブコードから未参照）

### Brewfile.current (削除)
- `brew bundle dump` のスナップショットファイルを削除（必要時に再生成可能）

### apps-list.txt (削除)
- インストール済みアプリ一覧を削除（どこからも未参照の陳腐化したファイル）

### AGENTS.md, README.md
- 削除したファイルへの参照を除去

---

## 2026-02-21 (7) ハードコードパスの除去

### zsh/tools/starship.zsh
- `$HOME/.dotfiles/...` を `${DOTFILES_DIR:h}/...` に変更（ghq 等でリポジトリ配置先を変更可能に）

### apps/tmux/tmux.conf
- `$HOME/.dotfiles/apps/tmux` を `readlink -f ~/.tmux.conf` によるシンボリックリンク解決に変更

---

## 2026-02-21 (6) Claude Code キーバインド管理

### apps/claude/keybindings.json (新規)
- Claude Code のキーバインド設定を dotfiles 管理下に追加
- `Ctrl+J` で入力欄に改行を挿入する設定

### setup.sh
- Claude Code keybindings.json のシンボリックリンク作成を追加

---

## 2026-02-21 (5) $HOME クリーンアップ

### zsh/zshenv
- `NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"` を追加（`~/.npm` の XDG 化）
- `PULUMI_HOME="$XDG_DATA_HOME/pulumi"` を追加（`~/.pulumi` の XDG 化）

### zsh/zprofile
- Cargo env のパスを `$CARGO_HOME` 変数ベースに変更（XDG 対応）

### apps/vim/vimrc
- `viminfofile=~/.local/state/vim/viminfo` を設定（`~/.viminfo` の XDG 化）

### $HOME 直下の削除・移動
- `~/golang/` を削除（旧 GOPATH、`go clean -modcache` 後に削除）
- `~/.cargo/` を削除（`$XDG_DATA_HOME/cargo` に移行済み）
- `~/.npm/` を削除（`NPM_CONFIG_CACHE` で XDG 化）
- `~/.pulumi/` を `$XDG_DATA_HOME/pulumi` に移動
- `~/.viminfo` を `~/.local/state/vim/viminfo` に移動
- `~/.zsh_history` を削除（XDG の history に移行済み）
- `~/.zprofile.zwc.old`, `~/.zshenv.zwc.old`, `~/.zshrc.zwc.old` を削除
- `~/package-lock.json` を削除
- `~/.amazon-q.dotfiles.bak/` を削除

---

## 2026-02-21 (4) README.md 刷新

### README.md
- 現在の設定内容に合わせて全面書き直し
- 日本語化、各セクションを実際の設定値に基づいて記述
- 古い情報を削除（`pull.ff=only`、auto-attach、旧プロンプト形式等）
- Ghostty セクションを追加
- zsh 読み込み順序、キーバインド一覧、エイリアス一覧を追加
- 設計方針セクションを追加

---

## 2026-02-21 (3) ツール管理のモダン化

### apps/ghostty/config (新規)
- Ghostty の設定ファイルを dotfiles 管理下に追加
- JetBrains Mono フォント（Ghostty 内蔵）、Everforest テーマ設定
- macOS tabs スタイル、半透明背景、shell integration 設定
- `macos-option-as-alt = left` で fzf の Alt+C を有効化
- tmux と競合する cmd+1-9 キーバインドを unbind
- cmd+up/down でプロンプト間ジャンプを追加

### setup.sh
- Ghostty config のシンボリックリンク作成を追加

### Brewfile
- `ozankasikci/tap` の tap 宣言を追加（`agent-sessions` 用）

### Brewfile.current
- 現在のシステム状態で再生成（旧エントリ peco, openssl@1.1 等を削除）

---

## 2026-02-21 (2) モダン化

設定全体のモダン化を実施。

### zsh/tools/go.zsh
- レガシーな `GOPATH=~/golang` を削除（Go 1.11+ はデフォルト `~/go` を使用）
- `go env GOPATH` で動的に解決するように変更
- `command -v` ガードを追加

### zsh/tools/volta.zsh
- `command -v volta` チェックを `$VOLTA_HOME` ディレクトリ存在チェックに変更（初回インストール時に PATH が通っていなくても動作する）
- `path_prepend` ヘルパーを使用するように変更

### zsh/functions/gcd.zsh
- fzf プレビューを `ls -la` から `eza -la --icons --git` に変更（eza がある場合）
- eza がない場合は `ls -la` にフォールバック

### zsh/tools/zsh-plugins.zsh
- `brew --prefix` の呼び出しを2回→1回に削減（変数にキャッシュ）

### setup.sh
- バッククォート `` `date ...` `` を `$(date ...)` に置き換え
- `[ $? == 0 ]` パターンを `if check_dependency ...; then` に置き換え
- 変数のクォート不足を修正（`$(dirname $0)` → `"$(dirname "$0")"` 等）
- `check_dependency` 関数を `command -v` ベースにリファクタリング
- `read` に `-r` フラグを追加（バックスラッシュのエスケープ防止）

### zsh/os/darwin.zsh
- `alias ls='ls -G -F'` に eza 存在チェックのガードを追加（`aliases.zsh` の eza エイリアスとの競合を解消）

### apps/git/gitconfig
- `pull.ff = only` を削除（`pull.rebase = true` と矛盾していたため。rebase が優先され ff は無視されていた）

### zsh/integrations/amazon-q.zsh
- 未使用の死にコード（定義のみで呼び出し元なし）を削除

---

## 2026-02-21

リポジトリ全体を解析し、以下のアップデートを実施。

### Brewfile
- `kiro-cli` のコメントを修正（「OpenAI Codex CLI」→「Kiro CLI (Amazon)」）
- `agent-sessions` cask を追加（インストール済みだが未登録だった）

### zsh/zshrc
- Kiro CLI の重複コメントブロック（pre x2, post x2）を削除
- iterm2 shell integration の二重読み込みを解消（`integrations/iterm2.zsh` に統一）
- `export PATH="$HOME/.local/bin:$PATH"` を `path_prepend` ヘルパーに置き換え（PATH 重複防止）

### zsh/zprofile
- Kiro CLI の重複コメントブロック（pre x2, post x2）を削除

### zsh/os/darwin.zsh
- `export TERM=xterm-256color` を削除（tmux の `default-terminal` 設定と衝突するため）
- AWS CLI 補完パスを Intel 固定（`/usr/local/...`）から `$(brew --prefix)` に変更（Apple Silicon 対応）

### zsh/lib/command_time.zsh
- `date` 外部コマンド呼び出しを `zmodload zsh/datetime` + `$EPOCHSECONDS` に置き換え（パフォーマンス改善）

### zsh/lib/aliases.zsh
- `cat` エイリアスの `bat` をフルパス展開に変更（`sudo cat` で bat が見つからない問題を修正）
- `bat` に `--style=plain` を追加（行番号等の装飾を非表示に）

### apps/git/gitconfig
- `help.autocorrect` を `1`（旧形式）から `prompt`（Git 2.43+ 推奨形式）に変更
- credential helper の `gh` パスを Linuxbrew 固定パスから `!gh auth git-credential`（PATH 解決）に変更（macOS/Linux 両対応）
