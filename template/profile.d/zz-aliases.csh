# ------- global aliases & colors -------

# 1. 彩色 ls 的顏色表 (使用 dircolors 的 -c 參數來產生 csh 語法)
if ( -x /usr/bin/dircolors ) then
    if ( -r ~/.dircolors ) then
        eval `dircolors -c ~/.dircolors`
    else
        eval `dircolors -c`
    endif
endif

# 2. GNU ls 彩色與常用別名 (csh 的 alias 語法：alias 名稱 '指令')
alias ls 'ls --color=auto'
alias ll 'ls -lh'               # 加入 -h 顯示 MB/GB
alias lla 'ls -lah'             # 詳細、隱藏檔、MB/GB
alias la 'ls -A'                # 隱藏檔但排除 . 與 ..
alias l 'ls -C'

# 3. 安全確認別名
alias cp 'cp -i'                # 若有同名檔案會警告
alias mv 'mv -i'                # 若有同名檔案會警告
# alias rm 'rm -i'              # tcsh 較不支援 rm -I，建議視需求開啟 -i

# 4. 系統資訊檢視
alias df 'df -h'
alias usage 'du -sh'

# 5. 目錄跳轉
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'