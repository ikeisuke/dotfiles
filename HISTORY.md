# Change History

## 2026-05-06 Brewfile: copilot-cli (GitHub Copilot CLI) をインストール対象に追加

### Brewfile
- AI tools (cross-platform) セクションに `cask "copilot-cli"` を追加
- 既存の codex (OpenAI) と同列に GitHub Copilot CLI も標準セットアップで揃うようにする
- 注: cask は実体としては macOS のみで適用される (Linuxbrew では cask 行は無視されるため、cross-platform セクション内に置いても挙動は変わらない)

## 2026-04-27 statusline.py: ctx 表示を 5h/7d と統一フォーマットに整理

### apps/claude/statusline.py
- ctx のバーを 2 本（しきい値基準 + 絶対値基準）から 1 本（しきい値基準のみ）に削減
- 表示フォーマットを 5h/7d と揃えて `ctx <bar> 5%/40% →12.5%` に変更
  - `5%`: 現在の使用率
  - `/40%`: autocompact しきい値
  - `→12.5%`: しきい値を 100% としたときの進捗率 (5/40 = 12.5%)
- なぜ: 旧表示はバー 2 本がラベルなしで並んでいて何を比較しているか初見で読めなかった。`→` で「autocompact までの距離感」を数値化することで、5h/7d の予測表示と視覚的に揃う

## 2026-04-27 statusline.py に 5h/7d レートリミットのペース可視化を追加

### apps/claude/statusline.py
- `fmt()` に `window_seconds` 引数を追加し、5h (18000秒) / 7d (604800秒) のウィンドウ全体に対する経過率と「現ペースのまま行った場合の最終予測使用率」を併記
- 表示フォーマット: `5h <bar> 50%/20% →250% 3h59m` (使用率 / 経過率 → 予測 リセット残)
- `gradient_pace()` を追加し、予測値で色分け: >100%=赤 (越えそう), >85%=黄, <60%=青 (節約しすぎ), それ以外=緑
- なぜ: `used_percentage` 単独だと「今のペースが妥当か」が判断できなかった。経過時間との比で予測値を出すことで、節約／オーバーペースが一目でわかる

## 2026-04-26 doctor を bin/ から scripts/ に移動 (PATH 配置とメンテ用の置き場分離)

### scripts/doctor (旧 bin/doctor)
- `bin/doctor` → `scripts/doctor` に `git mv`
- `bin/` は PATH に通す汎用コマンドの置き場として運用し、dotfiles リポジトリ内でのみ叩くメンテナンス用スクリプトは `scripts/` に分けた
- ヘッダコメントの "Run from repo root: `./scripts/doctor`" を追記し、PATH に乗せない旨を明示
- doctor の Symlinks チェックでも `bin/*` ループから自身を除外する特例を削除

### setup.sh
- `bin/` ループに入れていた `doctor` 特例除外 (`[ "$name" = "doctor" ] && continue`) を削除
- `bin/` セクション冒頭に「scripts/ との使い分け」をコメントで明記

### AGENTS.md
- 「リポジトリ構成」に `bin/` (PATH 通す汎用コマンド) と `scripts/` (リポジトリ内メンテ用) の使い分けルールを追記
- なぜ: `gh-ruleset` のような汎用ツールは PATH に乗せたいが、`doctor` のように dotfiles のパス前提で固定された専用スクリプトは `bin/` に置くと特例分岐が必要になる。配置で意図を表現する規約に切り替えた

## 2026-04-26 actions/checkout を v4 → v6 に更新

### .github/workflows/lint.yml
- `actions/checkout@v4` (Node.js 20) → `actions/checkout@v6` (Node.js 24) に更新
- なぜ: GitHub Actions が 2026-09-16 に Node.js 20 を runner から削除予定で、`@v4` のままだと将来動かなくなるため。初稼働時の deprecation 警告を解消

## 2026-04-26 .gitignore の `.*` 一括除外を解消し CI ワークフローを追跡対象化

### .gitignore
- 先頭の `.*` (全ドットファイル/ディレクトリ除外) を削除
- 副次的に不要になった例外指定を整理: `!/.claude/`, `!/.mcp.json` を削除
- `/.claude/settings.local.json` は引き続き明示的に除外
- `.DS_Store` / `.env*` / `.ssh/` / `.aws/` 等の secrets ルールはそのまま維持
- なぜ: `.*` が `.github/` まで巻き込んで除外しており、`.github/workflows/lint.yml` が追跡されず CI として機能していなかったため。今後 `.cache/` や `.venv/` 等が出てきた場合は個別に追記する運用に切り替え

### .github/workflows/lint.yml
- 元々 working tree に存在していたが `.*` で gitignore されて追跡されていなかった CI ワークフローを追跡対象に追加
- `shellcheck --severity=warning setup.sh` と全 zsh ファイルの `zsh -n` を main への push / PR で実行
- なぜ: `.gitignore` 整理に伴い、本来意図されていた CI を初めて稼働させるため

## 2026-04-26 Claude Code 設定追加

### apps/claude/settings.json
- `enabledPlugins` に `claude-code-setup@claude-plugins-official` を追加
- 設定追加: `verbose=true`, `remoteControlAtStartup=true`, `agentPushNotifEnabled=true`, `skipAutoPermissionPrompt=true`
- なぜ: リモート操作・通知・自動許可フローを常時有効化し、verbose 出力でデバッグ容易性を上げるため

## 2026-04-26 PostToolUse hook / bin/doctor / context7 MCP の追加

### .claude/settings.json (新規 / project-scoped)
- `PostToolUse` hook を追加: Edit/Write/MultiEdit 後に拡張子で振り分けて lint
  - `*.sh` → `shellcheck --severity=warning`
  - `*.zsh` / `*/zshrc` / `*/zshenv` / `*/zprofile` → `zsh -n`
  - 結果は stderr に出力するのみ（`exit 0` で続行）。`command -v` でガードし未導入環境では何もしない
  - 入力は stdin の JSON から `jq -r '.tool_input.file_path'` で取得
- `enabledMcpjsonServers: ["context7"]` を追加して `.mcp.json` の context7 を自動有効化
- なぜ: push 後に CI で気づいていた構文エラーを Edit 直後にローカルで検知し、Claude の自己修正ループを高速化するため

### .mcp.json (新規 / project-scoped)
- context7 (`@upstash/context7-mcp`) を npx 経由で起動する project-scoped MCP として登録
- なぜ: dotfiles で扱う OSS ツール（starship / mise / lazygit / direnv 等）の docs 引きを WebFetch より低コンテキストで実現するため。man / `--help` では薄い設定ファイル書式の参照に有効
- **採否再評価リマインダ**: 2026-05-26（採用から30日後）に呼び出し回数を確認し、月1回未満なら `.mcp.json` を削除する

### .gitignore
- `.*` で全ドットファイルを除外していたため、project-scoped 設定の追跡を有効化:
  - `!/.claude/` で `.claude/` 配下を追跡対象に
  - `/.claude/settings.local.json` で local 上書きは引き続き除外
  - `!/.mcp.json` を追跡対象に

### Brewfile
- `shellcheck` を追加（PostToolUse hook で `*.sh` の lint に使用）

### bin/doctor (新規)
- dotfiles 環境の健全性チェックスクリプトを追加（純粋な bash、読み取り専用）
- セクション:
  - **Brewfile**: `brew bundle check --file=Brewfile` で不足パッケージ検出
  - **Symlinks**: `setup.sh` が張る各シンボリックリンク（zsh / git / tmux / claude / gh / zeno / fzf / vim / ghostty / `bin/*`）の整合性確認
  - **Tool Versions**: 主要ツールのバージョンを一覧表示（`setup.sh` 末尾と同じ範囲 + `shellcheck`）
  - **Platform**: macOS / WSL2 / Linux を判定し、WSL2 では AppArmor の kernel/userspace 状態を確認
- exit code: すべて OK or 警告のみ → `0` / 修正が必要な不整合あり → `1` / スクリプト異常 → `2`
- 出力フォーマットは `setup.sh` の `✓` / `✗` / `⚠` と統一、`tput` で 8色端末のみカラー化
- なぜ: `setup.sh` 実行後に Brewfile を更新したり手動でファイルを上書きしたりした際の環境ドリフトを `./bin/doctor` 一発で検知できるようにするため

## 2026-04-24 setup.sh にバージョン表示セクションを追加

### setup.sh
- 末尾に「Installed versions」セクションを追加し、主要ツール（brew / rustup / rustc / cargo / deno / git / jj / zsh / tmux / node / npm / claude / jailrun / gh / ghq / vim）のバージョンを一覧表示
  - `print_version` ヘルパーで各ツールの先頭行を整列表示、未インストールは `(not installed)` と表示
  - `brew` は macOS でのみ表示（Linux 環境のノイズを避ける）
  - 個別インストール（Homebrew 外）の `claude` / `jailrun` / `deno` / `rustup` 系もセットアップ後に揃ったかを一目で確認できる
- なぜ: セットアップ後にどのバージョンが入ったかを一目で確認できるようにするため

## 2026-04-19 WSL2 AppArmor 有効化サポート

### setup.sh
- WSL2 環境を検出し、Windows 側 `.wslconfig` に AppArmor 有効化パラメータをマージするセクションを追加
  - `uname -r` / `/proc/version` に `WSL2` が含まれる場合のみ有効化（`.wslconfig` は WSL2 専用のため WSL1 は除外）
  - `/mnt/c/Users/<USERNAME>/.wslconfig` の `[wsl2]` セクションの `kernelCommandLine` に `apparmor=1 security=apparmor` を追記
  - 既存設定は保持したまま不足パラメータのみ追加（冪等）、変更時は `.bak.<timestamp>` を残す
  - Windows ユーザー名は `cmd.exe /c echo %USERNAME%` で interop 経由で取得、取得できない場合は警告のみ出して中断（複数アカウント環境で誤った profile を書き換えるのを避けるため `/mnt/c/Users` の走査はしない）
  - AppArmor ランタイム状態（`/sys/module/apparmor/parameters/enabled`）と userspace ツール（`apparmor_parser`, `aa-status`）の有無を確認
- なぜ: jailrun が AppArmor をサンドボックスの一次プロファイルとして使う構成に移行するため、dotfiles 側で有効化条件を整える

### AGENTS.md
- 「WSL2 AppArmor 有効化」セクションを追加し、dotfiles 側の責務と適用手順（`wsl --shutdown`、apparmor パッケージ）を明記

## 2026-04-17 Claude Code 周りの設定整備と npm 移行

### Brewfile
- `cask "claude-code"` を削除（Homebrew cask 経由のインストールを廃止）

### setup.sh
- Claude Code を npm 経由でインストール/更新（`npm install -g @anthropic-ai/claude-code`）
  - Homebrew より公式 npm パッケージの方が最新版の配信が早いため移行
- プラグインインストールで `--scope user` を明示（project scope と混在して update が失敗する問題を解消）
- update を先に試行し、失敗時のみ marketplace 追加 + install するフォールバック方式に変更
- 新設 `bin/` を `~/.local/bin` へリンクするセクションを追加

### apps/claude/CLAUDE.md
- Codex CLI 連携の詳細化（`codex exec` の使い方、出力は Codex にて検証される旨）
- 設定ファイルのスコープ（user / project）説明を追加
- スキル優先呼び出しルールを追加
- 許可ルールの定期メンテナンス方針（`tools:suggest-permissions`）を追加
- セッションタイトル自動設定を hooks 直接実行へ更新
- トレードオフスライダー（スコープ/予算/納期/品質）を追加
- 「改善の約束は行動で示す」ルールを追加（宣言文を禁止し CLAUDE.md 追記 / Issue / 直接修正のいずれかを求める）

### apps/claude/settings.json
- env: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` を 20→40、`CLAUDE_CODE_NO_FLICKER=1` を追加
- 有効プラグインに `aidlc@ai-dlc-starter-kit` と `codex@openai-codex` を追加（marketplace 登録含む）
- SessionStart hook を session-title スキル呼び出しから inline シェルへ変更
  - macOS 限定、OSC 0 でタイトル更新、iTerm2 は Badge もあわせて設定
- PreToolUse hook: sandbox 未適用検出時の `exit 2` を `exit 0` に変更（警告のみで継続）
- 設定追加: `language=日本語`、`effortLevel=high`、`skipDangerousModePermissionPrompt=true`
- permissions: `Bash(\\rm ...)` → `Bash(rm ...)` に修正、不要な session-title.sh 許可を削除

### bin/gh-ruleset (新規)
- GitHub ブランチルールセット（削除・force push 保護等）を apply/show/remove する補助スクリプト
- `gh api` ベースで `--check`（必須ステータスチェック）や `--bypass`（バイパスアクター）を指定可能

### apps/git/gitignore
- `settings.local.json`、`__pycache__`、`.DS_Store` を無視対象に追加

## 2026-03-25 setup.sh 出力整理・jailrun 自動インストール

### setup.sh
- run_quiet ヘルパー追加: コマンド出力を抑制し、成功時は ✓、失敗時は ✗ + 詳細を表示
- 全セクションにタイトル行を追加し、子要素を 2 スペースインデントで統一
- jailrun セットアップを ghq get -u + make install で自動化（手動案内を廃止）
- brew bundle, rustup, deno, git clone 等の verbose 出力を run_quiet で抑制
- セクション区切りの ====== バナーを廃止
- 関数定義（link_and_backup, check_dependency）をファイル先頭に移動

## 2026-03-24 セキュリティラッパーを jailrun リポジトリに分離

### bin/ (削除)
- _credential-guard.sh, _agent-wrapper.sh, claude, codex, gemini, kiro-cli, kiro-cli-chat, gh-token-rotate を削除
- セキュリティラッパー機能は https://github.com/ikeisuke/jailrun に移行

### setup.sh
- ~/bin シンボリックリンク作成を削除、jailrun インストール案内に置き換え

### Brewfile
- bats-core を追加（jailrun のテスト用）

### docs/security/ (削除)
- README.md, github-pat-setup.md を削除（jailrun リポジトリの docs/ に移行）

## 2026-03-23 Linux/WSL 対応強化

### bin/_credential-guard.sh
- GitHub PAT の環境変数フォールバック削除（セキュアストアのみ）
- secret-tool 未インストール時の WARN メッセージ追加
- ログ表示 "Fine-grained PAT" → "PAT"（classic/fine-grained 共通）
- systemd-run: PrivateTmp=no + ReadWritePaths=/tmp、PrivateDevices=no、--pipe → --pty（GitHub Web で適用済み）
- systemd-run に -E フラグで環境変数を明示的に渡す（子プロセス継承問題の対策）

### bin/gh-token-rotate
- Linux 対応: _get_token / _delete_token / _store_token ヘルパーで macOS/Linux 分岐
- echo -n でパイプして制御文字混入を防止
- secret-tool 未インストール時のエラーメッセージ追加

### zsh/os/linux.zsh
- WSL ブロックに gnome-keyring-daemon 自動起動を追加（ソケット存在チェック付き）

### setup.sh
- Linux 推奨パッケージを bubblewrap → gnome-keyring に変更

### docs/security/README.md
- 環境変数フォールバックの記述を削除
- gnome-keyring のインストール手順を更新
- SSH→HTTPS 変換に Linux -E フラグの説明追記
- secret-tool store 時の制御文字混入の注意を追加

### docs/security/github-pat-setup.md
- Linux/WSL 向け secret-tool セクションを追加（保存・確認・注意事項）
- トークンローテーション手順を gh-token-rotate スクリプトに統一

## 2026-03-22 SSH→HTTPS 完全移行

### bin/_credential-guard.sh
- ~/.ssh を Seatbelt deny リストに復帰（env 変数が正しく継承されることを確認済み）
- ssh://git@github.com/ 形式の insteadOf 変換を追加（GIT_CONFIG_COUNT=2）

### apps/claude/settings.json
- Bash(*~/.ssh/*) を ask → deny に移動

### docs/security/README.md
- ~/.ssh の除外注記を削除、SSH→HTTPS 変換の説明に更新

## 2026-03-22 エイリアス・CLAUDE.md 整理

### zsh/lib/aliases.zsh
- Safety aliases (rm -i, cp -i, mv -i) をインタラクティブシェルのみに限定（AIエージェントの子プロセスで確認プロンプトが出ないように）

### apps/claude/CLAUDE.md
- シェルエイリアス回避ルール（\rm 等）を削除（aliases.zsh のガードで不要に）

### bin/gh-token-rotate
- PAT の有効期限を GitHub API レスポンスヘッダーから取得・表示するように追加

## 2026-03-22 セキュリティラッパー改善

### bin/_credential-guard.sh
- Linux sandbox を bubblewrap から systemd-run に移行（seccomp/cgroup/カーネル保護を統合）
- sandbox 検出を env 変数 + ファイルアクセス（~/.aws/config 読み取り可否）の2段構えに
- ~/.ssh を Seatbelt deny リストから除外（Claude が env 変数を継承しないため SSH→HTTPS 変換が効かない）
- SSH→HTTPS git 変換設定（GIT_ASKPASS / GIT_CONFIG）を追加（env 継承するツール向け）
- GH_KEYCHAIN_SERVICE を classic/fine-grained の2種対応（ai-agent-gh-token-classic / ai-agent-gh-token-fine-grained）
- P1修正: Linux bwrap 未インストール時に SANDBOXED フラグが誤設定される問題
- P2修正: bwrap worktree の bind 引数が zsh で単一要素になる問題
- Seatbelt の known_hosts 読み取り許可を追加後に削除（SSH→HTTPS に統一）

### bin/_agent-wrapper.sh
- codex exec: -s danger-full-access をサブコマンド後に挿入（グローバル位置では無効）
- codex review: -c 'sandbox_mode="danger-full-access"' で内蔵 sandbox 無効化
- ユーザー指定の -s/--sandbox を danger-full-access に強制上書き（警告付き）
- sandbox 検出ヘルパー _is_sandboxed() を追加（env 変数 or ファイルアクセス）
- exec ログを AGENT_SANDBOX_DEBUG 条件付きに

### apps/claude/settings.json
- PreToolUse hook 追加: sandbox 未適用時に全ツール実行をブロック（exit 2）
- permissions.deny から ~/.aws, ~/.ssh, ~/.config/gh の Bash パターンを ask に移動

### docs/security/README.md
- Linux sandbox を bubblewrap → systemd-run に更新
- Codex 内蔵 sandbox 対策（exec/review 別のフラグ）を追記
- sandbox 検出方式（env 変数 + ファイルアクセス）を追記
- Claude Code 固有の保護（PreToolUse hook, permissions）セクション追加
- ~/.ssh の扱い変更と理由を追記

### docs/security/github-pat-setup.md
- Keychain サービス名を classic/fine-grained の2種対応に更新
- config での切り替え方法を追記

## 2026-03-22 AI エージェント セキュリティラッパー追加

### bin/_credential-guard.sh (新規)
- AI エージェント共通のクレデンシャル分離ライブラリを追加
- AWS: SSO 一時クレデンシャルを取得し、許可プロファイルのみの一時 config/credentials ファイルを生成
- GitHub: OS に応じたセキュアストアからトークン取得（macOS: Keychain、Linux: secret-tool / 環境変数フォールバック）
- Linux/WSL2 で GH_TOKEN/GITHUB_TOKEN が不当にクリアされる問題を修正（セキュアストア未使用時は既存トークンを継承）
- SSH: SSH_AUTH_SOCK を無効化
- 継承された危険な環境変数（AWS_ACCESS_KEY_ID, GH_TOKEN 等）を明示的にクリア
- OS サンドボックス: macOS は Seatbelt、Linux/WSL2 は bubblewrap で機密ファイル読み取りを拒否
- 書き込み制限: カレントディレクトリ + /tmp + ツール固有ディレクトリのみ許可
- 設定ファイル（~/.config/security-wrapper/config）は初回自動生成、バイナリパスも自動検出

### bin/_agent-wrapper.sh (新規)
- 共通ラッパーテンプレート: WRAPPER_NAME から BIN 変数名を自動導出
- 各ツールのラッパーは 3 行に簡素化（source するだけ）

### bin/claude, bin/codex, bin/kiro-cli, bin/kiro-cli-chat, bin/gemini (新規)
- 各 AI エージェントのセキュリティラッパースクリプト
- PATH 優先度で実体より先に解決され、クレデンシャル分離済みの環境で起動
- 全ツール共通で credential_guard_sandbox_exec を使用（ラッパーの Seatbelt/bwrap で保護）
- AGENT_UNSAFE=1 でバイパス可能
- AGENT_AWS_PROFILES でロードするプロファイルを選択可能（未指定時は DEFAULT_AWS_PROFILE のみ）

### apps/claude/settings.json
- sandbox.enabled: false（ラッパーの Seatbelt に統一、内蔵 sandbox は TLS 問題のため無効化）
- permissions.deny に Bash 経由の機密アクセスパターンを追加
- permissions.ask に git tag -d, git checkout --, gh pr merge 等を追加

### apps/claude/CLAUDE.md
- `$(...)` の制約を「回避」から「絶対禁止」に格上げ、PreToolUse hook の限界を明記
- Codex CLI との連携（codex review, codex exec resume）の使い方を追記

### setup.sh
- ~/bin ディレクトリへのセキュリティラッパーのシンボリックリンク作成処理を追加

### docs/security/README.md (新規)
- セキュリティラッパーの全体アーキテクチャ、セットアップ手順、使い方、トラブルシューティングのドキュメント

### docs/security/github-pat-setup.md (新規)
- GitHub Fine-grained PAT の作成・Keychain 保存・ローテーション手順のガイド
- エンタープライズ管理者向けの注意事項を含む

## 2026-03-20 Claude Code ステータスライン対応

### apps/claude/statusline.py
- 値が未取得の場合に項目が消えるのではなくデフォルト値(0)を表示するよう変更
- cost→$0.00、duration→0m00s、lines→+0 -0、ctx→0%、5h/7d→0% をデフォルトに
- `/clear` 後に `used_percentage` が `null` で送られる問題を修正（`.get(key, 0)` → `or 0`）

### apps/claude/statusline.py (新規)
- Braille dots パターンでAPIレート制限をステータスバーに表示するスクリプトを追加
- コンテキスト使用率(ctx)、5時間枠(5h)、7日枠(7d)をTrueColorグラデーション付きで表示
- レート制限のリセットまでの残り時間を表示（`resets_at` フィールドから算出、`Xh XXm` 形式）
- 参考: https://nyosegawa.com/posts/claude-code-statusline-rate-limits/

### apps/claude/settings.json
- `statusLine` 設定を追加（`~/.claude/statusline.py` をコマンドとして実行）
- `permissions.defaultMode` を `"auto"` に変更（auto mode をデフォルト有効化）

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
