# Dotfiles リポジトリ運用ルール

## プロジェクト概要

個人開発環境 (zsh / 各種ツール設定) を macOS / Linux (WSL2 含む) で再現可能に管理するための dotfiles。

優先する価値判断（順位順）:
1. 安定性 (毎日の作業基盤、壊れると影響大)
2. クロスプラットフォーム両立 (macOS / Linux)
3. 可読性 (将来の自分が読む)
4. 秘密情報の非漏洩

## 技術スタック

- Shell: zsh (main), bash (互換)
- Package manager: Homebrew (macOS / Linuxbrew)
- Runtime: macOS / Linux (WSL2 含む)
- CI: GitHub Actions (`.github/workflows/lint.yml`)
- 静的解析: shellcheck, `zsh -n`

## リポジトリ構成

- `zsh/` - モジュラーな zsh 設定（zshenv, zprofile, zshrc から各モジュールを読み込み）
- `apps/` - アプリ個別設定（gh, ghostty, git, starship, tmux, vim, claude）
- `bin/` - **PATH に通す汎用コマンド** (`setup.sh` が `~/.local/bin/` にリンク)。任意のリポジトリ/ディレクトリから呼べる前提のもののみ置く
- `scripts/` - **dotfiles リポジトリ内専用のメンテナンス用スクリプト** (`./scripts/<name>` として叩く)。PATH には乗せない
- `Brewfile` - Homebrew 依存管理
- `setup.sh` - 初回セットアップスクリプト（シンボリックリンク作成、brew bundle 等）
- AI エージェントのセキュリティラッパーは [jailrun](https://github.com/ikeisuke/jailrun) リポジトリに分離

## セットアップコマンド

- Install / 再適用: `./setup.sh` (冪等)
- Homebrew 依存解決: `brew bundle`
- 健全性チェック: `./scripts/doctor`

## 品質チェック

- Shell script lint: `shellcheck --severity=warning <file>`
- zsh syntax check: `zsh -n <file>`
- 自動実行: `.claude/settings.json` の PostToolUse hook が Edit/Write/MultiEdit 時に対象拡張子を自動 lint
- CI: `.github/workflows/lint.yml` が main への push / PR で `setup.sh` + 全 zsh ファイルを検査

## コーディングルール

- 既存のディレクトリ構成・命名・モジュール分割パターンに従う
- ツールの存在チェック (`command -v`) で graceful degradation する
- macOS / Linux 両対応: `os/darwin.zsh`, `os/linux.zsh` で OS 分岐
- マシン固有設定は git 管理外: `~/.gitconfig.local`, `~/.zshrc.local`
- XDG Base Directory 準拠で `$HOME` を汚さない
- `bin/` は PATH 上の汎用コマンド、`scripts/` はリポジトリ内専用 (配置で意図を表現)

## セキュリティルール

- 秘密情報 (API トークン, credential, 秘密鍵, `.env`) を commit しない
- マシン固有・環境固有の値は machine-local ファイル (`~/.gitconfig.local`, `~/.zshrc.local`, `.env*`) に分離し gitignore する
- 外部公開コンテンツ (GitHub Issue / PR / コミットメッセージ等) には個人パス (`/Users/<name>/...` 等) を直書きしない

## 変更履歴の記録

このリポジトリに変更を加えた場合、必ず `HISTORY.md` に追記する。

- 日付（`## YYYY-MM-DD`）ごとにセクションを分ける
- 変更したファイル/カテゴリごとに `###` で見出しをつける
- 各変更は「何を」「なぜ」がわかるように簡潔に記述する
- 新しい変更は既存の履歴の上に追記する（新しい順）

## WSL2 AppArmor 有効化

jailrun のサンドボックスが AppArmor を一次プロファイルとして利用するため、
WSL2 環境では dotfiles 側で `.wslconfig` の `kernelCommandLine` に
`apparmor=1 security=apparmor` を追加する責務を持つ。

- `setup.sh` が WSL2 を検出すると `/mnt/c/Users/<USERNAME>/.wslconfig` をマージ（冪等）
- 既存の `kernelCommandLine` は保持し、不足パラメータのみ追記
- 変更時は `.bak.<timestamp>` バックアップを残す
- 適用には Windows 側で `wsl --shutdown` が必要
- userspace ツール未導入時は `sudo apt install apparmor apparmor-utils` を案内
- securityfs (`/sys/kernel/security`) はカーネルが LSM インターフェースを公開する仮想 FS。WSL2 は自動マウントしないため、未マウントなら一時マウントコマンドと `/etc/fstab` 永続化手順を案内（sudo 実行は user 側に委ねる）

## 既知の落とし穴

- Linuxbrew は cask 行を無視する (`Brewfile` の cask は macOS でのみ適用される)
- Linux で brew 配布が無いツール (Obsidian 等) は AppImage 等で個別対応 (`setup.sh` 内)
- WSL2 で Obsidian など Windows 版とコマンド名が衝突する場合は別名 symlink で回避 (例: `obsidian-appimage`)

## 慎重に扱う領域

- `setup.sh` のシンボリックリンクロジック (誤ると dotfiles 全体が壊れる)
- `.wslconfig` / `/etc/fstab` 編集 (sudo / root 影響範囲が広い)
- `apps/claude/settings.json` (Claude Code の起動時挙動に直結)

## AI エージェント向けファイルの運用

- `AGENTS.md` (このファイル) — 全 AI エージェント共通の正本
- `CLAUDE.md` (root) — Claude Code 用の薄いラッパー。`@AGENTS.md` で本ファイルを import
- 共通ルールは `AGENTS.md` に書く。Claude Code 固有の指示のみ `CLAUDE.md` に追加する
- 強制したい処理は markdown ではなく CI / hook / script 側に寄せる（例: `.claude/settings.json` の PostToolUse で shellcheck/zsh -n を自動実行）
- ルールが領域別に長くなった場合は `.claude/rules/<area>.md` に分割する (現状は不要)
- 個人のグローバル AI 設定は本リポジトリで管理し symlink 配置する（このリポジトリの `AGENTS.md` / `CLAUDE.md` には書かない）:
  - `apps/agents/AGENTS.md` → `~/.agents/AGENTS.md` （共通原本）
  - `apps/claude/CLAUDE.md` → `~/.claude/CLAUDE.md` （Claude Code 用、冒頭で `@~/.agents/AGENTS.md` を import）
  - `apps/codex/AGENTS.md` → `~/.codex/AGENTS.md` （Codex CLI 用、`apps/codex/AGENTS.md` 自体が `../agents/AGENTS.md` への symlink）
- 個人グローバル設定の編集ポリシー:
  - 共通ルール（基本姿勢 / 対話ルール / コマンド実行ルール / git 運用）は `apps/agents/AGENTS.md` に書く
  - 各ツール固有のルールは `apps/claude/CLAUDE.md` / `apps/codex/AGENTS.md` に書く（Codex 固有は現状なしのため symlink で済んでいる）
  - 詳細な WHY は HISTORY.md に残し、本体には**高リスク規則の WHY 1 行のみ**（起動毎の system prompt 読込コスト削減）
  - 圧縮ポリシー: [agents.md](https://agents.md/) 精神 (action-oriented、AI 向け、README clutter を避ける) に従い、レベル B 粒度を基準とする
