# ターミナル & エディタ

## Ghostty

GPU アクセラレーション対応のモダンターミナルエミュレータ。

- **フォント**: JetBrains Mono 14pt（Ghostty 内蔵、Nerd Font グリフ対応）
- **テーマ**: Everforest Dark Hard / Light Medium（システムの外観に連動）
- **外観**: tabs スタイル、半透明背景（0.95）、ブラー
- **shell integration**: starship との競合を避けるため cursor 機能を無効化
- **`macos-option-as-alt = left`**: fzf の `Alt+C` が動作するために必須
- **キーバインド**: `cmd+1-9` を unbind（tmux のウィンドウ管理と競合するため）

設定ファイル: `apps/ghostty/config`

## iTerm2

- fzf の `Alt+C` を使うには **Preferences > Profiles > Keys > General > Left Option key → Esc+** に設定が必要
- tmux の iTerm2 統合（`tmux -CC`）については [Tmux 設定](../apps/tmux/README.md) を参照

## Starship プロンプト

シングルラインのミニマルなプロンプト:

```
~/dotfiles  main !1+2 %
```

- ディレクトリ（3 階層まで）、git ブランチ、git ステータス
- 言語モジュール（aws, nodejs, python 等）は速度のため無効化
- starship 未インストール時は vcs_info ベースのフォールバックプロンプトを使用

設定ファイル: `apps/starship/starship.toml`

## Vim

軽量な設定（92 行）。VS Code や AI CLI ツールをメインエディタとする前提で、ターミナルでの簡易編集用。

- **vim-plug**: プラグインマネージャー（自動インストール）
- **fzf.vim**: `<C-p>` でファイル検索、`<leader>r` で ripgrep
- **vim-fugitive / vim-gitgutter**: Git 統合
- **vim-commentary / vim-surround**: 編集補助
- **everforest**: カラースキーム（Ghostty と統一）
- **リーダーキー**: `,`

設定ファイル: `apps/vim/vimrc`
