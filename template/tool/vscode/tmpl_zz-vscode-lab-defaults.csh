# 1. 處理 CODE_HOME (模擬 Bash 的 ${XDG_CONFIG_HOME:-$HOME/.config})
set _config_home = "$HOME/.config"
if ( $?XDG_CONFIG_HOME ) then
    set _config_home = "$XDG_CONFIG_HOME"
endif

set CODE_HOME = "$_config_home/Code"
set USER_DIR  = "$CODE_HOME/User"

# 2. 取得來源路徑
set SRC = "${TOOL_ROOT}/vscode/defaults/User"

if ( ! -e "$USER_DIR/settings.json" ) then
    mkdir -p "$USER_DIR"
    # csh 沒有 cp -n 的直接等價，但我們可以先檢查目錄是否有檔案
    # 使用 if ( -d "$SRC" ) 確保來源存在，避免 cp 報錯
    if ( -d "$SRC" ) then
        cp -pn $SRC/* "$USER_DIR/" >& /dev/null
    endif
endif

# 釋放暫存變數
unset _config_home