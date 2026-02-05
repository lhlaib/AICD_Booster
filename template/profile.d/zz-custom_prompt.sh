# /etc/profile.d/zz-custom_prompt.sh
if [ -n "$PS1" ]; then
    get_custom_pwd() {
        # 1. 取得 HOME 與 PWD 並同時移除結尾斜線（如果有）
        local my_home="${HOME%/}"
        local my_pwd="${PWD%/}"
        
        # 2. 精確比對移除斜線後的路徑
        if [ "$my_pwd" = "$my_home" ]; then
            # 即使剛登入時 PWD 帶斜線，現在也會匹配成功
            echo "~"
        elif [[ "$PWD" == "$my_home/"* ]]; then
            # 子目錄邏輯：將 $my_home 部分替換為 ~
            echo "${PWD/#$my_home/\~}"
        else
            # 不在範圍內，顯示原始 PWD
            echo "$PWD"
        fi
    }

    # 套用 PS1
    export PS1="\[\e[36m\]\A \[\e[m\]\u@\h[\[\e[36m\]\$(get_custom_pwd)\[\e[m\]]\$ "
fi
