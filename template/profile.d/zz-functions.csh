# ==== 1. 簡易工具別名 (取代簡單的 Bash Function) ====

# mkcd: 建立並進入目錄 (csh alias 不支援 &&，改用分號)
alias mkcd 'mkdir -p \!* && cd \!*'

# bigfiles: 列出前 10 大檔案
alias bigfiles 'du -ah . | sort -rh | head -n 10'

# usage: 使用量
alias usage 'du -sh'

# bak: 快速備份檔案
alias bak 'cp -ir \!* \!*.bak_`date +%Y%m%d_%H%M%S`'

# ==== 2. 複雜邏輯 (建議呼叫外部腳本或使用 csh 特殊語法) ====

# extract: 由於 csh alias 內做不到複雜的 case 判斷
# 建議你在安裝包中把 Bash 版的 extract 存成 /usr/bin/extract 並加上 +x 權限
# 然後在這裡做 alias
alias extract '/usr/bin/extract'

# chto: 同上，csh 沒辦法處理互動式 read 和 mapfile
# 建議將原 Bash 版 chto 存成 /usr/bin/chto
alias chto '/usr/bin/chto'

# ==== 3. 安全刪除檢查 (rm & del) ====

# 在 tcsh 中，我們沒辦法直接在 alias 裡寫這麼長的 if/else 邏輯
# 為了保護學生，建議維持基本的 -i 保護，或呼叫你寫好的安全刪除腳本
alias rm 'rm -i'

# 如果你堅持要用你寫的那個帶有安全檢查的 del：
# 請將該 del 函數存為一個獨立檔案 /usr/bin/del (需為 Bash 腳本)
alias del '/usr/bin/del'

# ==== 4. 權限控管與條件判斷 ====

# 檢查使用者是否同時屬於 rocky 與 Manager 群組
# csh 判斷群組的方式與 bash 不同
set groups_list = `groups`
echo "$groups_list" | grep -q '\brocky\b'
set is_rocky = $?
echo "$groups_list" | grep -q '\bManager\b'
set is_manager = $?

if ( $is_rocky == 0 && $is_manager == 0 ) then
    # myip 功能
    alias myip 'echo "Internal IP: `hostname -I`"; echo "External IP: `curl -s ifconfig.me`"'
endif

# ==== 5. 補完功能 (Completion) ====

# tcsh 的補完語法與 Bash 的 complete 完全不同
# 這裡幫 chto 實做從 /etc/hosts 抓取主機名稱的補完
if ( -f /etc/hosts ) then
    set hosts_completions = `grep -v '^#' /etc/hosts | awk '{for (i=2; i<=NF; i++) print $i}' | sort -u`
    complete chto 'p/1/($hosts_completions)/'
endif

# 其他常用補完
complete {cd,pushd,ls,ll,usage} 'p/1/d/'  # 只補完目錄
complete {extract,bak,del} 'p/1/f/'      # 只補完檔案