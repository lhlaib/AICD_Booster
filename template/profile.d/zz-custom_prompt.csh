# 檢查是否為互動式 Shell (類似 Bash 的 [ -n "$PS1" ])
if ( $?prompt ) then
    # 定義顏色轉義碼 (tcsh 提示字元內建支援 %{\033[...%})
    set c_cyan  = "%{\033[36m%}"
    set c_reset = "%{\033[0m%}"

    # 設定提示字元
    # %P : 目前時間 (24小時制，包含秒) -> 建議改用 %T (15:30) 較接近 Bash 的 \A
    # %n : 使用者名稱 (\u)
    # %m : 主機名稱 (\h)
    # %~ : 目前路徑，且自動將 $HOME 替換為 ~ (這就解決了你 get_custom_pwd 的邏輯)
    # %# : 一般使用者顯示 >，root 顯示 # (類似 Bash 的 \$)

    set prompt = "${c_cyan}%T ${c_reset}%n@%m[${c_cyan}%~${c_reset}]%# "
endif