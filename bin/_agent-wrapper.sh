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

# AGENT_UNSAFE または sandbox 済み → 実体を直接 exec
if [[ "${AGENT_UNSAFE:-}" == "1" || "${_CREDENTIAL_GUARD_SANDBOXED:-}" == "1" ]]; then
  # ~/bin を除外した PATH で実体を探して exec
  _orig_path=("${path[@]}")
  path=("${path[@]:#$HOME/bin}")
  REAL_BIN="$(command -v "$WRAPPER_NAME" 2>/dev/null)" || true
  path=("${_orig_path[@]}")
  if [[ -z "$REAL_BIN" ]]; then
    echo "[$WRAPPER_NAME] ERROR: 実体が見つかりません" >&2
    exit 1
  fi
  # sandbox 済みの場合、ツールの内蔵 sandbox を無効化（二重 sandbox 防止）
  _extra_args=()
  if [[ "${_CREDENTIAL_GUARD_SANDBOXED:-}" == "1" ]]; then
    case "$WRAPPER_NAME" in
      codex) _extra_args=(--sandbox danger-full-access) ;;
    esac
  fi
  exec "$REAL_BIN" "${_extra_args[@]}" "$@"
fi

# BIN 変数名を導出: kiro-cli → KIRO_CLI_BIN
_bin_var="${${WRAPPER_NAME:u}//-/_}_BIN"
REAL_BIN="${(P)_bin_var}"
if [[ -z "$REAL_BIN" ]]; then
  echo "[$WRAPPER_NAME] ERROR: ${_bin_var} が設定されていません ($CONFIG_FILE)" >&2
  exit 1
fi

credential_guard_sandbox_exec "$REAL_BIN" "$@"
