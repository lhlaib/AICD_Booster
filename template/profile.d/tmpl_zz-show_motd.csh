#!/bin/tcsh

# 1. 定義顏色變數 (Csh 使用 set 代替 export)
set BOLD = "\033[1m"
set CYAN = "\033[36m"
set GREEN = "\033[32m"
set BLUE = "\033[34m"
set YELLOW = "\033[33m"
set RED = "\033[31m"
set RESET = "\033[0m"
set UNDERLINE = "\033[4m"

# 2. 僅在互動式 Shell 且非 SSH 重複連線時執行
if ( $?prompt ) then
    # 檢查是否為 SSH 連線 (Csh 檢查環境變數的方式)
    if ( ! $?SSH_CONNECTION ) then
        if ( -f "/etc/motd" ) then
            cat /etc/motd
        endif
    endif

    # 3. 硬體與狀態偵測
    set HOSTNAME = `hostname`
    set CPU_MODEL = `grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^\s//'`
    set MEM_TOTAL = `free -h | awk '/^Mem:/ {print $2}'`
    
    # 處理作業系統資訊 (預防檔案不存在)
    set OS_INFO = "Rocky Linux 8.x"
    if ( -f /etc/redhat-release ) then
        set OS_INFO = "`cat /etc/redhat-release`"
    endif

    set UPTIME = `uptime -p | sed 's/up //'`
    set LOAD = `uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //'`

    # --- Header ---
    echo "${BLUE}====================================================================${RESET}"
    echo "  ${BOLD}${CYAN}SYSTEM DASHBOARD${RESET}  -  ${YELLOW}${HOSTNAME}${RESET}"
    echo "${BLUE}====================================================================${RESET}"

    # Section 1: Hardware Specifications
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "Operating Sys" "$OS_INFO"
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "CPU Model"     "$CPU_MODEL"
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "Total Memory"  "$MEM_TOTAL"
    
    # Section 2: Real-time Status
    echo "  ------------------------------------------------------------------"
    printf "  %-15s : ${YELLOW}%-s${RESET}\n" "System Uptime" "$UPTIME"
    printf "  %-15s : ${YELLOW}%-s${RESET}\n" "Load Average"  "$LOAD"

    # Section 3: Online User Statistics
    echo "  ------------------------------------------------------------------"
    # Csh 處理管道與變數較敏感，直接呼叫 shell 指令輸出
    set USER_COUNT = `who | wc -l`
    
    echo "  ${BOLD}${CYAN}Online Users (${USER_COUNT})${RESET}"
    if ( $USER_COUNT > 0 ) then
        # 顯示前 5 位使用者
        who | awk '{print $1" ("$5")"}' | sed 's/()/(local)/' | sort | uniq -c | head -n 5 | awk '{ \
            printf "   > %-15s %-10s (x%d)\n", $2, $3, $1 \
        }'
        if ( `who | awk '{print $1}' | sort | uniq | wc -l` > 5 ) then
            echo "   ... and more. (use the command: who)"
        endif
    else
        echo "   > No active remote sessions."
    endif

    # Section 3.5: Software Environment (Lmod)
    echo "  ------------------------------------------------------------------"
    echo "  ${BOLD}${CYAN}SOFTWARE MODULES (Lmod)${RESET}"
    echo "   > ${YELLOW}module avail${RESET}            : List all available software"
    echo "   > ${YELLOW}module load <name>${RESET}      : Load a specific module"
    echo "   > ${YELLOW}module list${RESET}             : List currently loaded modules"
    echo "   > ${YELLOW}module purge${RESET}            : Unload all modules"
    echo "   > ${YELLOW}module spider <name>${RESET}    : Search for a specific module/version"

    echo "  ${BOLD}${CYAN}PYTHON PACKAGE MANAGER (uv)${RESET}"
    echo "   > ${YELLOW}1. module load uv${RESET}       : Load uv module"
    echo "   > ${YELLOW}2. uv venv${RESET}              : Create a virtual environment for current folder"
    echo "   > ${YELLOW}3. uv pip install <pkg>${RESET} : Download required package from online marketplace"
    echo "   > ${YELLOW}4. uv-off-install <pkg>${RESET} : Download required package from offline shared wheel house"

    echo "  ------------------------------------------------------------------"
    echo "  ${BOLD}${CYAN}COMMON TOOLS (Helpers)${RESET}"
    echo "   > ${YELLOW}mypdf${RESET}           : PDF viewer"
    echo "   > ${YELLOW}force-logout${RESET}    : Force users logout all sessions (Shortcut: fl)"
    echo "   > ${YELLOW}task-manager${RESET}    : Manage the running tasks in server (Shortcut: tm)"
    echo "   > ${YELLOW}code-lab${RESET}        : Launch VS Code with shared lab extensions"
    echo "   > ${YELLOW}bye${RESET}             : force-logout + task-manager"

    # Section 4: Contact & Support (Localized via config.sh)
    echo "  ------------------------------------------------------------------"
    echo "  ${BOLD}${RED}CONTACT & SUPPORT${RESET}"
    echo "   > TA Support : ${BOLD}${BLUE}${MAIN_MANAGER}${RESET} (${MAIN_MANAGER_EMAIL})"
    echo "   > Website    : ${UNDERLINE}${YELLOW}${WEBSITE_URL}${RESET}"

    echo "${BLUE}====================================================================${RESET}"
    echo ""
endif