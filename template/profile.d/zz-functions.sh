# 以 root 執行

# ==== chto：從 /etc/hosts 找 hostname，支援簡寫 ====
chto() {
    if [ -z "${1:-}" ]; then
        echo "Usage: chto <hostname|IP|user@host>"
        return 1
    fi

    local arg="$1"
    local target=""

    if [[ "$arg" == *@* ]] || [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        target="$arg"
    else
        local hosts
        mapfile -t hosts < <(grep -Ev '^(#|$)' /etc/hosts | awk '{for (i=2; i<=NF; i++) print $i}' | sort -u)

        local exact=()
        for h in "${hosts[@]}"; do
            [[ "$h" == "$arg" ]] && exact+=("$h")
        done

        if (( ${#exact[@]} == 1 )); then
            target="${exact[0]}"
        else
            local matches=()
            for h in "${hosts[@]}"; do
                [[ "$h" == "$arg"* ]] && matches+=("$h")
            done

            if (( ${#matches[@]} == 1 )); then
                target="${matches[0]}"
            elif (( ${#matches[@]} > 1 )); then
                echo "找到多個符合「$arg」的主機，請選擇："
                local i=1
                for h in "${matches[@]}"; do
                    echo "  $i) $h"
                    ((i++))
                done
                read -rp "請輸入數字： " idx
                if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx>=1 && idx<=${#matches[@]} )); then
                    target="${matches[idx-1]}"
                else
                    echo "選項無效，取消。"
                    return 1
                fi
            else
                echo "在 /etc/hosts 找不到符合「$arg」的主機，直接用它當 hostname。"
                target="$arg"
            fi
        fi
    fi

    if [[ "$target" != *@* ]]; then
        target="${USER}@$target"
    fi

    echo "→ ssh $target"
    ssh "$target"
}

_chto_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local hosts
    hosts=$(grep -Ev '^(#|$)' /etc/hosts | awk '{for (i=2; i<=NF; i++) print $i}' | sort -u)
    COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
}
complete -F _chto_complete chto

# ==== 常用工具函式 ====
extract () {
   if [ -f "$1" ] ; then
       case "$1" in
           *.tar.bz2)   tar xvjf "$1"    ;;
           *.tar.gz)    tar xvzf "$1"    ;;
           *.bz2)       bunzip2 "$1"     ;;
           *.rar)       unrar x "$1"     ;;
           *.gz)        gunzip "$1"      ;;
           *.tar)       tar xvf "$1"     ;;
           *.tbz2)      tar xvjf "$1"    ;;
           *.tgz)       tar xvzf "$1"    ;;
           *.zip)       unzip "$1"       ;;
           *.Z)         uncompress "$1"  ;;
           *.7z)        7z x "$1"        ;;
           *)           echo "'$1' cannot be extracted via extract()" ;;
       esac
   else
       echo "'$1' is not a valid file"
   fi
}

mkcd() {
  mkdir -p "$1" && cd "$1"
}

bak() {
  if [ -z "$1" ]; then
    echo "Usage: bak <file_or_directory>"
    return 1
  fi
  local timestamp=$(date +%Y%m%d_%H%M%S)
  if [ -d "$1" ]; then
    cp -ir "$1" "$1.bak_$timestamp"
  elif [ -f "$1" ]; then
    cp -i "$1" "$1.bak_$timestamp"
  else
    echo "Error: '$1' is invalid"
    return 1
  fi
}

# ==== 安全刪除檢查 ====
rm() {
    local forbidden=("$HOME" "/home" "/etc" "/usr" "/var" "." "..")
    local has_r=false
    local has_f=false

    # 1. 檢查參數
    for arg in "$@"; do
        # 安全清單檢查
        for p in "${forbidden[@]}"; do
            if [[ "$arg" == "$p" || "$arg" == "$p/" ]]; then
                echo -e "\e[1;31m[SECURITY]\e[0m Access denied: Cannot delete $arg"
                return 1
            fi
        done

        # 偵測是否包含 -r 和 -f (支援組合寫法如 -rf 或拆開寫 -r -f)
        if [[ "$arg" =~ ^-.*r ]]; then has_r=true; fi
        if [[ "$arg" =~ ^-.*f ]]; then has_f=true; fi
    done

    # 2. 如果偵測到 -rf 組合，跳出額外警告
    if [ "$has_r" = true ] && [ "$has_f" = true ]; then
        echo -e "\e[1;33m[WARNING]\e[0m Dangerous command 'rm -rf' detected!"
        read -p "This will permanently delete directories. Are you sure? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    # 3. 執行原始指令
    command rm -I "$@"
}

del() {
    # 1. 檢查是否有輸入參數
    if [ -z "$1" ]; then
        echo "Usage: del <file_or_directory>"
        return 1
    fi

    # 2. 檢查檔案或資料夾是否存在
    if [ ! -e "$1" ]; then
        echo "Error: '$1' does not exist."
        return 1
    fi

    # 3. 顯示警告訊息 (黃色粗體)
    echo -e "\e[1;33mWARNING: You are about to permanently delete '$1' and all its contents.\e[0m"
    
    # 4. 詢問確認
    read -p "Are you sure you want to proceed? (y/n): " -n 1 -r
    echo "" 

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 執行刪除
        if [ -d "$1" ]; then
            # 使用 command rm 避開自定義 rm 函式，防止遞迴或衝突
            command rm -rf "$1"
            echo "Successfully deleted directory: '$1'"
        else
            command rm -f "$1"
            echo "Successfully deleted file: '$1'"
        fi
    else
        echo "Operation cancelled."
    fi
}

bigfiles() {
  du -ah . | sort -rh | head -n 10
}

# ==== 權限控管工具 ====
# 修正後的群組判斷語法
if groups "$USER" | grep -q '\brocky\b' && groups "$USER" | grep -q '\bManager\b'; then
    myip() {
        echo "Internal IP: $(hostname -I)"
        echo "External IP: $(curl -s ifconfig.me)"
    }
fi
