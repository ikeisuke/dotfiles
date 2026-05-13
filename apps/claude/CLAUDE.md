@~/.agents/AGENTS.md

## Claude Code 固有

### スキル優先呼び出し

対応するスキルが存在する場合は必ずスキル経由で実行する。ロジックを手動再現しない。

### シェルコマンド置換 `$(...)` の絶対禁止

理由: 確認ダイアログが毎回出る（PreToolUse hook では止められず CLAUDE.md 指示のみで担保）。

- git commit は `-m "..."`（複数 `-m` も可、ヒアドキュメント禁止）
- 変数代入は複数ステップに分割
- パイプ `|` / リダイレクト `>` は OK
- バッククォートも同じ扱い

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

### 設定ファイルのスコープ（settings.json）

- User: `~/.claude/settings.json`
- Project: `.claude/settings.json`
- Local: `.claude/settings.local.json`
- 不明な場合は書き込み前にユーザー確認

### セッションタイトル自動設定

SessionStart hook で自動設定済み（フォーマット: `リポジトリ名 / ブランチ名`）。必要なら手動変更可。
