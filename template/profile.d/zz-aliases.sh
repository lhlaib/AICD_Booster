# 以 root 執行

# ------- global aliases & colors -------
# 彩色 ls 的顏色表（若自訂 .dircolors 則會套用）
if command -v dircolors >/dev/null 2>&1; then
  if [ -r ~/.dircolors ]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
fi

# GNU ls 彩色與常用別名
alias ls='ls --color=auto'
alias ll='ls -lh'              # 加入 -h 顯示 MB/GB
alias lla='ls -lah'            # 詳細、隱藏檔、MB/GB
alias la='ls -A'               # 隱藏檔但排除 . 與 ..
alias l='ls -C'

alias cp='cp -i'               # 若有同名檔案會警告
alias mv='mv -i'               # 若有同名檔案會警告
# alias rm='rm -I'               # 維持大寫 I，大量刪除才警告

alias df='df -h'
alias usage='du -sh'

# 目錄跳轉
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

