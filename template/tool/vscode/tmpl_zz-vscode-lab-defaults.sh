#!/usr/bin/env bash
CODE_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/Code"
USER_DIR="$CODE_HOME/User"
SRC="${TOOL_ROOT}/vscode/defaults/User"
if [[ ! -e "$USER_DIR/settings.json" ]]; then
  mkdir -p "$USER_DIR"
  cp -n $SRC/* $USER_DIR/ 2>/dev/null || true
fi
