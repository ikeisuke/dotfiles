# Zsh 設定

## 読み込み順序

```
zshenv     → LANG, EDITOR, XDG 環境変数
zprofile   → Homebrew, Cargo, GPG
zshrc      → lib/ → tools/ → os/ → integrations/ → starship → ~/.zshrc.local
```

## プラグイン

- **zsh-autosuggestions**: Fish ライクなコマンド入力候補（グレー表示、→ で確定）
- **zsh-fast-syntax-highlighting**: コマンドライン構文ハイライト

初回起動時に自動で git clone される（Homebrew 不要）。`update-zsh-plugins` コマンドで一括更新。

## キーバインド

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

## エイリアス

| エイリアス | 展開先 | 備考 |
|-----------|--------|------|
| `ls` | `eza --icons --git` | eza がなければ素の ls |
| `ll` | `eza --icons --git -l` | |
| `la` | `eza --icons --git -a` | |
| `lla` | `eza --icons --git -la` | |
| `lt` | `eza --icons --git --tree` | |
| `cat` | `bat --style=plain` | bat がなければ素の cat |
| `rm/cp/mv` | `-i` 付き | 誤操作防止 |
| `mkdir` | `mkdir -p` | 中間ディレクトリも自動作成 |
| `sudo` | `sudo ` | 末尾スペースでエイリアス展開を継続 |

## zeno スニペット & 補完

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

## シェル機能

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
- `AI_FALLBACK_INTERACTIVE`（デフォルト 0）で対話/非対話モードを切替
- `AI_JP_RATIO_THRESHOLD`（デフォルト 0.35）、`AI_MIN_LEN`（デフォルト 6）で判定を調整可能

## 起動高速化

シェルの起動速度を最適化するために以下の仕組みを導入している:

### zcompile（プリコンパイル）

zsh ファイルを `.zwc` バイトコードにコンパイルして読み込みを高速化。`setup.sh` 実行時にコンパイルされる。日常のシェル起動時は 1 日 1 回だけ差分チェックを行い、変更があったファイルのみ再コンパイルする。

### 補完キャッシュ

`uv generate-shell-completion zsh` のようなコマンド補完生成を毎回実行する代わりに、ファイルにキャッシュして source する。バイナリが更新されたときだけ自動再生成。

### プロファイリング

起動が遅いと感じたら、以下のコマンドでボトルネックを特定できる:

```bash
zsh-profile
# または
ZSH_PROFILE=1 zsh -i -c exit
```

各関数の実行時間・呼び出し回数・全体に占める割合が表形式で表示される。
