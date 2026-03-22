#!/bin/zsh
# AI エージェント共通ラッパー
# 各ツールのラッパースクリプト（claude, codex 等）から source して使う
# basename からツール名と BIN 変数名を自動解決する
#
# 設定: ~/.config/security-wrapper/config
# バイパス: AGENT_UNSAFE=1 <tool>
# プロファイル指定: AGENT_AWS_PROFILE=dev <tool>

set -euo pipefail

# WRAPPER_NAME は呼び出し元で設定すること
if [[ -z "${WRAPPER_NAME:-}" ]]; then
  echo "[_agent-wrapper.sh] ERROR: WRAPPER_NAME が未設定です" >&2
  exit 1
fi
source "${0:A:h}/_credential-guard.sh"

# sandbox 検出ヘルパー（env 変数 or ファイルアクセス）
_is_sandboxed() {
  [[ "${_CREDENTIAL_GUARD_SANDBOXED:-}" == "1" ]] && return 0
  [[ -f "$HOME/.aws/config" ]] && ! test -r "$HOME/.aws/config" 2>/dev/null && return 0
  return 1
}

# AGENT_UNSAFE または sandbox 済み → 実体を直接 exec
if [[ "${AGENT_UNSAFE:-}" == "1" ]] || _is_sandboxed; then
  # ~/bin を除外した PATH で実体を探して exec
  _orig_path=("${path[@]}")
  path=("${path[@]:#$HOME/bin}")
  REAL_BIN="$(command -v "$WRAPPER_NAME" 2>/dev/null)" || true
  path=("${_orig_path[@]}")
  if [[ -z "$REAL_BIN" ]]; then
    echo "[$WRAPPER_NAME] ERROR: 実体が見つかりません" >&2
    exit 1
  fi
  # ツールの内蔵 sandbox を無効化（ラッパーの Seatbelt/systemd-run に統一）
  # codex: -s はサブコマンドオプションのため、サブコマンドの後に挿入
  case "$WRAPPER_NAME" in
    codex)
      _codex_args=()
      _sandbox_inserted=false
      for _arg in "$@"; do
        _codex_args+=("$_arg")
        if [[ "$_sandbox_inserted" == false ]]; then
          case "$_arg" in
            exec|e)
              _codex_args+=(-s danger-full-access)
              _sandbox_inserted=true
              ;;
            review)
              _codex_args+=(-c 'sandbox_mode="danger-full-access"')
              _sandbox_inserted=true
              ;;
          esac
        fi
      done
      [[ "${AGENT_SANDBOX_DEBUG:-}" == "1" ]] && echo "[$WRAPPER_NAME] exec: $REAL_BIN ${_codex_args[*]}" >&2
      exec "$REAL_BIN" "${_codex_args[@]}"
      ;;
  esac
  [[ "${AGENT_SANDBOX_DEBUG:-}" == "1" ]] && echo "[$WRAPPER_NAME] exec: $REAL_BIN $*" >&2
  exec "$REAL_BIN" "$@"
fi

# BIN 変数名を導出: kiro-cli → KIRO_CLI_BIN
_bin_var="${${WRAPPER_NAME:u}//-/_}_BIN"
REAL_BIN="${(P)_bin_var}"
if [[ -z "$REAL_BIN" ]]; then
  echo "[$WRAPPER_NAME] ERROR: ${_bin_var} が設定されていません ($CONFIG_FILE)" >&2
  exit 1
fi

credential_guard_sandbox_exec "$REAL_BIN" "$@"
