# Dotfiles リポジトリ運用ルール

## 変更履歴の記録

このリポジトリに変更を加えた場合、必ず `HISTORY.md` に追記すること。

- 日付（`## YYYY-MM-DD`）ごとにセクションを分ける
- 変更したファイル/カテゴリごとに `###` で見出しをつける
- 各変更は「何を」「なぜ」がわかるように簡潔に記述する
- 新しい変更は既存の履歴の上に追記する（新しい順）

## リポジトリ構成

- `zsh/` - モジュラーな zsh 設定（zshenv, zprofile, zshrc から各モジュールを読み込み）
- `apps/` - アプリ個別設定（gh, ghostty, git, starship, tmux, vim, claude）
- `bin/` - **PATH に通す汎用コマンド** (`setup.sh` が `~/.local/bin/` にリンク)。任意のリポジトリ/ディレクトリから呼べる前提のもののみ置く
- `scripts/` - **dotfiles リポジトリ内専用のメンテナンス用スクリプト** (`./scripts/<name>` として叩く)。PATH には乗せない
- `Brewfile` - Homebrew 依存管理
- `setup.sh` - 初回セットアップスクリプト（シンボリックリンク作成、brew bundle 等）
- AI エージェントのセキュリティラッパーは [jailrun](https://github.com/ikeisuke/jailrun) リポジトリに分離

## 設計方針

- ツールの存在チェック（`command -v`）で graceful degradation する
- macOS / Linux 両対応（`os/darwin.zsh`, `os/linux.zsh` で分岐）
- マシン固有の設定は git 管理外（`~/.gitconfig.local`, `~/.zshrc.local`）
- XDG Base Directory 準拠で `$HOME` を汚さない

## WSL2 AppArmor 有効化

jailrun のサンドボックスが AppArmor を一次プロファイルとして利用するため、
WSL2 環境では dotfiles 側で `.wslconfig` の `kernelCommandLine` に
`apparmor=1 security=apparmor` を追加する責務を持つ。

- `setup.sh` が WSL2 を検出すると `/mnt/c/Users/<USERNAME>/.wslconfig` をマージ（冪等）
- 既存の `kernelCommandLine` は保持し、不足パラメータのみ追記
- 変更時は `.bak.<timestamp>` バックアップを残す
- 適用には Windows 側で `wsl --shutdown` が必要
- userspace ツール未導入時は `sudo apt install apparmor apparmor-utils` を案内
