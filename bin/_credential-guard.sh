#!/bin/zsh
# AI エージェント共通クレデンシャル分離ライブラリ
# 各ラッパースクリプトから source して使う
#
# 設定ファイル: ~/.config/security-wrapper/config
# deny パス一覧は apps/claude/settings.json の sandbox.filesystem.denyRead と同期すること
#
# 提供する関数:
#   credential_guard_exec <command> [args...] - クレデンシャル分離して exec
#   credential_guard_sandbox_exec <command> [args...] - クレデンシャル分離 + OS sandbox して exec

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/security-wrapper"
CONFIG_FILE="$CONFIG_DIR/config"
_WRAPPER_NAME="${WRAPPER_NAME:-security-wrapper}"

# AGENT_UNSAFE=1 の場合は全処理をスキップ（config 未生成でも動作する）
if [[ "${AGENT_UNSAFE:-}" == "1" ]]; then
  echo "[$_WRAPPER_NAME] UNSAFE mode: セキュリティラッパーをバイパス" >&2
  return 0 2>/dev/null || true
fi

# ─── デフォルト値 ───────────────────────────────────────
ALLOWED_AWS_PROFILES=""
DEFAULT_AWS_PROFILE=""
GH_KEYCHAIN_SERVICE="ai-agent-gh-token"
_DEFAULT_REGION="ap-northeast-1"

# バイナリパス（マシンごとに異なる可能性がある）
CLAUDE_BIN=""
CODEX_BIN=""
KIRO_CLI_BIN=""
KIRO_CLI_CHAT_BIN=""
GEMINI_BIN=""

# ─── 設定ファイル読み込み ───────────────────────────────
# 未定義の *_BIN を自動検出して config に追記するヘルパー
_auto_detect_bin() {
  local _var="$1" _cmd="$2"
  if [[ -z "${(P)_var}" ]]; then
    local _orig_path=("${path[@]}")
    path=("${path[@]:#$HOME/bin}")
    local _found
    _found=$(command -v "$_cmd" 2>/dev/null) || true
    path=("${_orig_path[@]}")
    if [[ -n "$_found" ]]; then
      echo "$_var=\"$_found\"" >> "$CONFIG_FILE"
      eval "$_var=\"$_found\""
      echo "[$_WRAPPER_NAME] 自動検出: $_var=$_found (config に追記)" >&2
    fi
  fi
}

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
  # 新しいツールが追加された場合、未定義のパスを自動補完
  _auto_detect_bin CLAUDE_BIN claude
  _auto_detect_bin CODEX_BIN codex
  _auto_detect_bin KIRO_CLI_BIN kiro-cli
  _auto_detect_bin KIRO_CLI_CHAT_BIN kiro-cli-chat
  _auto_detect_bin GEMINI_BIN gemini
else
  echo "[$_WRAPPER_NAME] 設定ファイルがありません: $CONFIG_FILE" >&2
  echo "[$_WRAPPER_NAME] 初期設定ファイルを作成します..." >&2
  mkdir -p "$CONFIG_DIR"

  # バイナリパスを自動検出（ラッパー自身を除外するため PATH から ~/bin を外して検索）
  # zsh の path 配列からフィルタして検索
  _detect_bin() {
    local _orig_path=("${path[@]}")
    path=("${path[@]:#$HOME/bin}")
    local _found
    _found=$(command -v "$1" 2>/dev/null) || true
    path=("${_orig_path[@]}")
    echo "${_found:-# not found: $1}"
  }

  cat > "$CONFIG_FILE" <<CONF
# AI エージェント セキュリティラッパー共通設定
# このファイルは git 管理外（マシン固有の設定）
# claude, codex, kiro-cli, gemini で共有される

# 許可する AWS プロファイル（スペース区切り）
# エージェントはここに列挙されたプロファイルのみ使用可能
# AGENT_AWS_PROFILES 環境変数でロードするプロファイルを選択可能（許可リスト内に限る）
ALLOWED_AWS_PROFILES="default"

# デフォルトで使う AWS プロファイル（環境変数 AGENT_AWS_PROFILE で上書き可）
# プロファイルが存在しなければ AWS なしで起動する
DEFAULT_AWS_PROFILE="default"

# Keychain に保存した GitHub PAT のサービス名
GH_KEYCHAIN_SERVICE="ai-agent-gh-token"

# 各ツールの実体パス（自動検出済み、必要に応じて修正）
CLAUDE_BIN="$(_detect_bin claude)"
CODEX_BIN="$(_detect_bin codex)"
KIRO_CLI_BIN="$(_detect_bin kiro-cli)"
KIRO_CLI_CHAT_BIN="$(_detect_bin kiro-cli-chat)"
GEMINI_BIN="$(_detect_bin gemini)"
CONF
  unfunction _detect_bin
  echo "[$_WRAPPER_NAME] 作成しました: $CONFIG_FILE" >&2
  echo "[$_WRAPPER_NAME] AWS プロファイル設定を確認してください: $CONFIG_FILE" >&2
  exit 1
fi

# 環境変数でのオーバーライド（AGENT_AWS_PROFILE > AWS_PROFILE > config の DEFAULT_AWS_PROFILE）
DEFAULT_AWS_PROFILE="${AGENT_AWS_PROFILE:-${AWS_PROFILE:-$DEFAULT_AWS_PROFILE}}"

# ロードするプロファイル（AGENT_AWS_PROFILES > デフォルトのみ）
# AGENT_AWS_PROFILES が指定されていればそれを、未指定なら DEFAULT_AWS_PROFILE のみロード
# 許可リスト外のプロファイルは拒否する
_LOAD_PROFILES="${AGENT_AWS_PROFILES:-$DEFAULT_AWS_PROFILE}"
if [[ -n "$_LOAD_PROFILES" && -n "$ALLOWED_AWS_PROFILES" ]]; then
  for _p in ${=_LOAD_PROFILES}; do
    if [[ " ${ALLOWED_AWS_PROFILES} " != *" $_p "* ]]; then
      echo "[$_WRAPPER_NAME] ERROR: AWS '$_p' は許可リストにありません (ALLOWED_AWS_PROFILES)" >&2
      exit 1
    fi
  done
fi

# ─── 一時ディレクトリ ───────────────────────────────────
_tmpdir=$(mktemp -d)
trap '\rm -rf "$_tmpdir"' EXIT

# ─── AWS クレデンシャル ─────────────────────────────────
# 許可プロファイルの一時 config/credentials を生成
# エージェントは --profile で許可されたプロファイル間を切り替えられる
_aws_config="$_tmpdir/aws-config"
_aws_creds="$_tmpdir/aws-credentials"
touch "$_aws_config" "$_aws_creds"

# プロファイルセクションを一時ファイルに書き出すヘルパー
_write_aws_profile() {
  local _section_config="$1" _section_creds="$2" _ak="$3" _sk="$4" _st="$5" _region="$6"
  echo "[$_section_config]" >> "$_aws_config"
  echo "region = $_region" >> "$_aws_config"
  echo "" >> "$_aws_config"
  echo "[$_section_creds]" >> "$_aws_creds"
  echo "aws_access_key_id = $_ak" >> "$_aws_creds"
  echo "aws_secret_access_key = $_sk" >> "$_aws_creds"
  [[ -n "$_st" ]] && echo "aws_session_token = $_st" >> "$_aws_creds"
  echo "" >> "$_aws_creds"
}

_default_written=false
_default_ak="" _default_sk="" _default_st="" _default_region=""

if command -v aws >/dev/null 2>&1 && [[ -n "$_LOAD_PROFILES" ]]; then
  for _profile in ${=_LOAD_PROFILES}; do
    # 一時クレデンシャルを取得（jq がなければ grep/cut にフォールバック）
    if _exported=$(aws configure export-credentials --profile "$_profile" --format process 2>/dev/null); then
      if command -v jq >/dev/null 2>&1; then
        _ak=$(echo "$_exported" | jq -r .AccessKeyId)
        _sk=$(echo "$_exported" | jq -r .SecretAccessKey)
        _st=$(echo "$_exported" | jq -r '.SessionToken // empty')
      else
        _ak=$(echo "$_exported" | grep -o '"AccessKeyId"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        _sk=$(echo "$_exported" | grep -o '"SecretAccessKey"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        _st=$(echo "$_exported" | grep -o '"SessionToken"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
      fi

      _region=$(aws configure get region --profile "$_profile" 2>/dev/null || echo "$_DEFAULT_REGION")

      # default セクション（DEFAULT_AWS_PROFILE と一致するプロファイルで生成）
      if [[ "$_default_written" == "false" && "$_profile" == "$DEFAULT_AWS_PROFILE" ]]; then
        _write_aws_profile "default" "default" "$_ak" "$_sk" "$_st" "$_region"
        _default_written=true
      fi

      # デフォルトプロファイルのクレデンシャルをキャッシュ（後方の fallback 用）
      if [[ "$_profile" == "$DEFAULT_AWS_PROFILE" ]]; then
        _default_ak="$_ak" _default_sk="$_sk" _default_st="$_st" _default_region="$_region"
      fi

      _write_aws_profile "profile $_profile" "$_profile" "$_ak" "$_sk" "$_st" "$_region"

      echo "[$_WRAPPER_NAME] AWS: $_profile (一時クレデンシャル)" >&2
    else
      echo "[$_WRAPPER_NAME] WARN: AWS '$_profile' のクレデンシャル取得失敗（aws sso login が必要？）" >&2
    fi
  done

  # DEFAULT_AWS_PROFILE がループ内で default セクション未生成の場合、キャッシュから生成
  if [[ "$_default_written" == "false" && -n "$_default_ak" ]]; then
    _write_aws_profile "default" "default" "$_default_ak" "$_default_sk" "${_default_st:-}" "${_default_region:-$_DEFAULT_REGION}"
  fi
fi

# ─── GitHub トークン ────────────────────────────────────
# OS に応じたセキュアストアからトークンを取得
# macOS: Keychain (security コマンド)
# Linux: secret-tool (GNOME Keyring) → 既存の GH_TOKEN/GITHUB_TOKEN にフォールバック
_gh_token=""
_gh_token_source=""
case "$(uname)" in
  Darwin)
    _gh_token=$(security find-generic-password -s "$GH_KEYCHAIN_SERVICE" -a "$USER" -w 2>/dev/null) || true
    [[ -n "$_gh_token" ]] && _gh_token_source="Keychain"
    ;;
  Linux)
    if command -v secret-tool >/dev/null 2>&1; then
      _gh_token=$(secret-tool lookup service "$GH_KEYCHAIN_SERVICE" account "$USER" 2>/dev/null) || true
      [[ -n "$_gh_token" ]] && _gh_token_source="GNOME Keyring"
    fi
    # secret-tool 未インストールまたはトークン未登録 → 既存の環境変数を継承
    if [[ -z "$_gh_token" ]]; then
      _gh_token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
      [[ -n "$_gh_token" ]] && _gh_token_source="環境変数"
    fi
    ;;
esac

if [[ -n "$_gh_token" ]]; then
  echo "[$_WRAPPER_NAME] GitHub: Fine-grained PAT ($_gh_token_source)" >&2
else
  echo "[$_WRAPPER_NAME] WARN: GitHub PAT 未設定（docs/security/github-pat-setup.md を参照）" >&2
fi

# ─── OS サンドボックス ───────────────────────────────────
# sandbox 非内蔵ツール用に OS レベルの制限を適用
# macOS: Seatbelt (sandbox-exec)、Linux/WSL2: bubblewrap (bwrap)
#
# 読み取り拒否: 機密ディレクトリ
# 書き込み許可: カレントディレクトリ + /tmp + ツール・シェルが使うディレクトリ（ホワイトリスト方式）

_SANDBOX_DENY_READ_PATHS=(
  "$HOME/.aws"
  "$HOME/.ssh"
  "$HOME/.config/gh"
  "$HOME/.gnupg"
  "$HOME/.config/security-wrapper"
)

_SANDBOX_ALLOW_WRITE_PATHS=(
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.kiro"
  "$HOME/.gemini"
  "$HOME/.local/share"
  "$HOME/.local/state"
  "$HOME/.cache"
  "$HOME/.npm"
  "$HOME/.config/claude"
  "$HOME/.config/codex"
  "$HOME/.config/kiro"
)

_SANDBOX_ALLOW_WRITE_FILES=(
  "$HOME/.claude.json"
)

_sandbox_cmd=()

_setup_sandbox() {
  local _cwd="$PWD"

  case "$(uname)" in
    Darwin)
      local _sb="$_tmpdir/sandbox.sb"
      {
        echo '(version 1)'
        echo '(allow default)'
        echo ''
        # AGENT_SANDBOX_DEBUG=1 で deny 時にシステムログに記録
        local _report=""
        [[ "${AGENT_SANDBOX_DEBUG:-}" == "1" ]] && _report=" (with report)"
        echo ';; 機密ディレクトリの読み取りを拒否'
        echo "(deny file-read*${_report}"
        for _p in "${_SANDBOX_DENY_READ_PATHS[@]}"; do
          echo "  (subpath \"$_p\")"
        done
        echo ')'
        echo ''
        echo ';; 書き込みをホワイトリストに制限'
        echo "(deny file-write*${_report}"
        echo '  (require-not'
        echo '    (require-any'
        echo "      (subpath \"$_cwd\")"
        echo '      (subpath "/tmp")'
        echo '      (subpath "/private/tmp")'
        echo '      (subpath "/private/var/folders")'
        echo '      (literal "/dev/null")'
        echo '      (literal "/dev/zero")'
        echo '      (literal "/dev/random")'
        echo '      (literal "/dev/urandom")'
        echo "      (subpath \"$_tmpdir\")"
        for _p in "${_SANDBOX_ALLOW_WRITE_PATHS[@]}"; do
          echo "      (subpath \"$_p\")"
        done
        for _f in "${_SANDBOX_ALLOW_WRITE_FILES[@]}"; do
          echo "      (literal \"$_f\")"
        done
        echo ')))'
      } > "$_sb"
      _sandbox_cmd=(sandbox-exec -f "$_sb")
      ;;
    Linux)
      if ! command -v bwrap >/dev/null 2>&1; then
        echo "[$_WRAPPER_NAME] WARN: bwrap 未インストール（sudo apt install bubblewrap）、サンドボックスなしで起動" >&2
        return
      fi
      # 全体を読み取り専用でマウントし、書き込み可能なパスだけ bind し直す
      _sandbox_cmd=(
        bwrap
        --ro-bind / /
        --bind "$_cwd" "$_cwd"
        --bind /tmp /tmp
        --bind "$_tmpdir" "$_tmpdir"
        --dev /dev
        --proc /proc
      )
      # ホワイトリストのディレクトリを書き込み可能に（mkdir -p は冪等）
      for _p in "${_SANDBOX_ALLOW_WRITE_PATHS[@]}"; do
        mkdir -p "$_p" 2>/dev/null || true
        _sandbox_cmd+=(--bind "$_p" "$_p")
      done
      # 機密ディレクトリを空に差し替え（読み取り拒否）
      for _p in "${_SANDBOX_DENY_READ_PATHS[@]}"; do
        [[ -d "$_p" ]] && _sandbox_cmd+=(--tmpfs "$_p")
      done
      ;;
  esac
}

# ─── exec ヘルパー ──────────────────────────────────────
# 共通の env 引数を構築（継承された危険な環境変数を明示的にクリア）
_build_env_args() {
  # env コマンドは -u オプションを VAR=val より前に置く必要がある
  # まず -u を全て集め、その後に VAR=val を追加する
  _env_args=(
    env
    # 継承された AWS クレデンシャルをクリア（config/credentials file より優先されるため）
    -u AWS_ACCESS_KEY_ID
    -u AWS_SECRET_ACCESS_KEY
    -u AWS_SESSION_TOKEN
    -u AWS_PROFILE
    -u AWS_DEFAULT_PROFILE
    -u AWS_ROLE_ARN
    -u AWS_ROLE_SESSION_NAME
  )
  # GitHub トークン: セキュアストアから取得できた場合は既存を上書き
  # 環境変数フォールバックの場合はそのまま継承（クリアしない）
  if [[ "$_gh_token_source" == "Keychain" || "$_gh_token_source" == "GNOME Keyring" ]]; then
    _env_args+=(-u GH_TOKEN -u GITHUB_TOKEN)
  elif [[ -z "$_gh_token" ]]; then
    # トークンなし: 既存もクリア（未認証で動作）
    _env_args+=(-u GH_TOKEN -u GITHUB_TOKEN)
  else
    # 環境変数から継承: GITHUB_TOKEN はクリア（GH_TOKEN に統一）
    _env_args+=(-u GITHUB_TOKEN)
  fi
  # 制限済みクレデンシャルを注入（-u の後に VAR=val）
  _env_args+=(
    AWS_CONFIG_FILE="$_aws_config"
    AWS_SHARED_CREDENTIALS_FILE="$_aws_creds"
    GH_CONFIG_DIR="$_tmpdir/gh"
    SSH_AUTH_SOCK=
  )
  if [[ -n "$_gh_token" ]]; then
    _env_args+=(GH_TOKEN="$_gh_token")
  fi
}

# exec 前に一時ファイルの cleanup をスケジュール
# exec はプロセスを置き換えるため trap EXIT は実行されない
# → バックグラウンドプロセスでエージェント終了を待ち、終了後に削除する
_schedule_cleanup() {
  (
    # 親プロセス（exec 後のエージェント）の終了を待つ
    while kill -0 $$ 2>/dev/null; do
      sleep 5
    done
    \rm -rf "$_tmpdir"
  ) &
  disown
}

# クレデンシャル分離のみ（sandbox 内蔵ツール向け: claude）
credential_guard_exec() {
  _build_env_args
  _schedule_cleanup
  exec "${_env_args[@]}" "$@"
}

# クレデンシャル分離 + OS サンドボックス（sandbox 非内蔵ツール向け: codex, kiro）
credential_guard_sandbox_exec() {
  _build_env_args
  _setup_sandbox
  _schedule_cleanup
  exec "${_env_args[@]}" "${_sandbox_cmd[@]}" "$@"
}
