# Git 設定

## 基本設定

| 設定 | 値 | 効果 |
|------|-----|------|
| `pull.rebase` | `true` | pull 時に自動 rebase（マージコミットを作らない） |
| `rebase.autostash` | `true` | rebase 前に未コミットの変更を自動 stash |
| `rebase.autosquash` | `true` | fixup/squash コミットを rebase 時に自動整列 |
| `push.autoSetupRemote` | `true` | 初回 push で自動的にリモート追跡ブランチを設定 |
| `merge.conflictStyle` | `zdiff3` | 3-way マージコンフリクト表示（ours/base/theirs） |
| `fetch.prune` | `true` | fetch 時に削除済みリモートブランチを自動削除 |
| `help.autocorrect` | `prompt` | タイポ時に修正候補を提示 |
| `core.pager` | `delta` | Dracula テーマの side-by-side diff |

## エイリアス

### 基本操作

```bash
git st          # status
git co          # checkout
git br          # branch
git ci          # commit
git lg          # pretty log graph（コミットグラフを色付き表示）
```

### モダンワークフロー

```bash
git fixup <ref>   # 指定コミットの修正を fixup コミットとして作成
git amend         # 直前のコミットにステージ中の変更を追加（メッセージ変更なし）
git unstage       # ステージングを取り消す
git last          # 直前のコミットを表示
git wt            # worktree の短縮形
git sync          # pull --rebase && push（リモートと同期）
```

## fixup ワークフロー

`autosquash = true` と `fixup` エイリアスを組み合わせることで、コミット履歴をきれいに保てる:

```bash
# 1. 何かの作業をしてコミット
git commit -m "ユーザー認証を追加"

# 2. レビュー指摘などで修正が必要になった
vim auth.ts

# 3. 修正対象のコミットを指定して fixup コミットを作成
git add auth.ts
git fixup abc1234     # abc1234 = "ユーザー認証を追加" のハッシュ

# 4. rebase すると fixup が自動的に対象コミットの直後に配置・統合される
git rebase -i main
# → fixup! コミットが abc1234 の直後に自動配置済み。そのまま保存すれば OK
```

`autosquash` がないと、手動でコミットを並べ替える必要があった。

## worktree の使い方

メインの作業を中断せずに別ブランチで作業できる:

```bash
# 別ディレクトリに hotfix ブランチをチェックアウト
git wt add ../hotfix hotfix-branch

# そのディレクトリで作業
cd ../hotfix
# ... 修正してコミット ...

# 終わったら削除
git wt remove ../hotfix
```

`git stash` と違い、元のブランチの作業状態は一切触らない。

## ローカル設定

個人情報やマシン固有の設定は `~/.gitconfig.local` に書く（git 管理外）。詳しくは [Git ローカル設定ガイド](git-local.md) を参照。

```bash
# 基本
[user]
  name = Your Name
  email = your@email.com

# ディレクトリ別に設定を切り替え（仕事 / 個人）
[includeIf "gitdir:~/work/"]
  path = ~/.gitconfig.work
```
