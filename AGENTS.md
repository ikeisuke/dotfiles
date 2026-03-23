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
- `Brewfile` - Homebrew 依存管理
- `setup.sh` - 初回セットアップスクリプト（シンボリックリンク作成、brew bundle 等）
- AI エージェントのセキュリティラッパーは [jailrun](https://github.com/ikeisuke/jailrun) リポジトリに分離

## 設計方針

- ツールの存在チェック（`command -v`）で graceful degradation する
- macOS / Linux 両対応（`os/darwin.zsh`, `os/linux.zsh` で分岐）
- マシン固有の設定は git 管理外（`~/.gitconfig.local`, `~/.zshrc.local`）
- XDG Base Directory 準拠で `$HOME` を汚さない
