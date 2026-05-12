# 個人設定

## 基本姿勢

### トレードオフスライダー

スコープ: 大 / 予算: 小 / 納期: 最小 / 品質: 最大

### 改善の約束は行動で示す

「意識します / 気をつけます / メモリに残します」のような宣言は禁止（セッション間で引き継がれず実効性ゼロ）。改善は以下のいずれかの行動で示す:

- **AGENTS.md / CLAUDE.md にルール追記**（再発防止策をプロンプトに残す）
- **GitHub Issue 作成**（修正必要箇所を記録）
- **その場で修正**（コード・設定・ドキュメント直接変更）

行動を伴わない反省文は出力しない。

### スキル優先呼び出し

対応するスキルが存在する場合は必ずスキル経由で実行する。ロジックを手動再現しない。

## 対話ルール

### 判断要求の前置き

`AskUserQuestion` で重要判断（方針変更・リスク操作・スコープ修正等）を問う前に「## まとめ」または「## 現状」を出力する。背景 / 各選択肢の trade-off / 推奨案を含める。

## コマンド実行ルール

### シェルコマンド置換 `$(...)` の絶対禁止

理由: 確認ダイアログが毎回出る（PreToolUse hook では止められず CLAUDE.md 指示のみで担保）。

- git commit は `-m "..."`（複数 `-m` も可、ヒアドキュメント禁止）
- 変数代入は複数ステップに分割
- パイプ `|` / リダイレクト `>` は OK
- バッククォートも同じ扱い

### commit メッセージ内のバッククォート禁止

理由: bash が command substitution として展開し zsh OOM クラッシュ（`command_not_found_handler` 無限再帰）。三連 backtick も同様。コード片は引用符・インデント・タグで代替。

### 外部スクリプト実行時のパイプの扱い

ファイル出力やログを伴う外部スクリプトに**バッファリング/切り詰めパイプを直結しない**。出力消失で事後追跡不能 + SIGPIPE で上流早期終了の恐れ。

- 禁止: `script | head -N`, `script | tail -N`, `script > /dev/null`
- 推奨: `script | tee /tmp/out.log | tail -n 50`（全出力保存、表示だけ絞る）

## git 運用

### カレントディレクトリで実行する

`-C` オプションや絶対パス指定は使わない。

### force push の AI 代行実行

squash/amend で履歴を整えた場合、`git push --force-with-lease` はユーザー確認なしで実行可。ただし `--force` / main 系ブランチ / squash 由来でない force push はユーザー確認必須。

### 外部公開コンテンツでのローカルパス取扱い

理由: ユーザー名・環境情報の漏洩防止。

GitHub Issue / PR / コミットメッセージ / 公開 Markdown / gist 等にホーム配下絶対パス・認証情報・内部 host 名を直書きしない。

- 禁止: `/Users/<name>/...`, `/home/<name>/...`, `C:\Users\<name>\...`, API トークン, 内部 host
- 推奨: ホーム配下 → `~/...` / リポジトリ配下 → repo-relative path / 環境固有 → `<placeholder>`
- 例外: ローカル作業ログ（`/tmp/...` 等）は生パス可
- 起票前チェック: `grep -nE '/Users/|/home/[^/]+/|C:\\Users\\' <body-file>`

## エージェント連携

### Codex CLI との連携

出力は Codex で検証される。

- `codex exec "<指示>"` — 任意の依頼
- `codex review --base main` — ベースブランチとの差分レビュー（出力にセッション ID）
- `codex exec resume <session-id> "<追加指示>"` — セッション継続

### サブエージェント委譲を原則とする

main context 節約のため出力が大きくなりがちなタスクは Agent tool に委譲する。

- **委譲**: 未知コードベース探索 / 3 クエリ以上の grep / テスト・ビルド・lint・ログ解析 / 自己完結型の調査
- **直接実行**: パス既知の Read / 1〜2 発 grep / 編集・コミット系 / 生データを後続で必須利用するケース
- 判断基準: `tail` / `head` で切り詰めたくなったら委譲
- subagent_type: `Explore`（Haiku, 探索）/ `Plan`（設計前リサーチ）/ `general-purpose`（探索 + 変更）
- 並列化: 独立タスクは 1 message に複数 Agent tool use

## 設定管理

### 設定ファイルのスコープ

- User: `~/.claude/settings.json`
- Project: `.claude/settings.json`
- Local: `.claude/settings.local.json`
- 不明な場合は書き込み前にユーザー確認

### セッションタイトル自動設定

SessionStart hook で自動設定済み（フォーマット: `リポジトリ名 / ブランチ名`）。必要なら手動変更可。
