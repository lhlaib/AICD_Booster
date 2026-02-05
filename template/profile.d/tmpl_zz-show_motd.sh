#!/usr/bin/env bash

# Define ANSI Color Codes
export BOLD='\e[1m'
export CYAN='\e[36m'
export GREEN='\e[32m'
export BLUE='\e[34m'
export YELLOW='\e[33m'
export RED='\e[31m'
export RESET='\e[0m'
export UNDERLINE='\e[4m'

# 1. Only execute in interactive shells and exclude SSH sessions to avoid duplication
if [[ $- == *i* ]]; then

    # 2. Display Static ASCII Art / Banner if exists
    if [[ -z "${SSH_CONNECTION}" ]] && [[ -f "/etc/motd" ]]; then
        cat /etc/motd
    fi

    # 3. Dynamic Hardware & Status Detection
    HOSTNAME=$(hostname)
    CPU_MODEL=$(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^\s//')
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    OS_INFO=$(cat /etc/redhat-release 2>/dev/null || echo "Rocky Linux 8.x")
    UPTIME=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')

    # --- Header ---
    echo -e "${BLUE}====================================================================${RESET}"
    echo -e "  ${BOLD}${CYAN}SYSTEM DASHBOARD${RESET}  -  ${YELLOW}${HOSTNAME}${RESET}"
    echo -e "${BLUE}====================================================================${RESET}"

    # Section 1: Hardware Specifications
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "Operating Sys" "$OS_INFO"
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "CPU Model"     "$CPU_MODEL"
    printf "  %-15s : ${GREEN}%-s${RESET}\n" "Total Memory"  "$MEM_TOTAL"
    
    # Section 2: Real-time Status
    echo -e "  ------------------------------------------------------------------"
    printf "  %-15s : ${YELLOW}%-s${RESET}\n" "System Uptime" "$UPTIME"
    printf "  %-15s : ${YELLOW}%-s${RESET}\n" "Load Average"  "$LOAD"

    # Section 3: Online User Statistics
    echo -e "  ------------------------------------------------------------------"
    USER_LIST=$(who | awk '{print $1" ("$5")"}' | sed 's/()/(local)/' | sort | uniq -c)
    USER_COUNT=$(echo "$USER_LIST" | awk '{sum+=$1} END {print sum}')
    
    echo -e "  ${BOLD}${CYAN}Online Users (${USER_COUNT})${RESET}"
    if [[ $USER_COUNT -gt 0 ]]; then
        # Display top 5 users to keep terminal clean
        echo "$USER_LIST" | head -n 5 | awk '{
            printf "   > %-15s %-10s (x%d)\n", $2, $3, $1
        }'
        [[ $(echo "$USER_LIST" | wc -l) -gt 5 ]] && echo "   ... and more. (use the command: who)"
    else
        echo -e "   > No active remote sessions."
    fi

    # Section 3.5: Software Environment (Lmod)
    echo -e "  ------------------------------------------------------------------"
    echo -e "  ${BOLD}${CYAN}SOFTWARE MODULES (Lmod)${RESET}"
    echo -e "   > ${YELLOW}module avail${RESET}            : List all available software"
    echo -e "   > ${YELLOW}module load <name>${RESET}      : Load a specific module (e.g., module load python3)"
    echo -e "   > ${YELLOW}module list${RESET}             : List currently loaded modules"
    echo -e "   > ${YELLOW}module purge${RESET}            : Unload all currently loaded modules"
    echo -e "   > ${YELLOW}module spider <name>${RESET}    : Search for a specific module/version"
    echo -e "  ${BOLD}${CYAN}PYTHON PACKAGE MANAGER (uv)${RESET}"
    echo -e "   > ${YELLOW}1. module load uv${RESET}       : Load uv module"
    echo -e "   > ${YELLOW}2. uv venv${RESET}              : Create a virtual environment for current folder"
    echo -e "   > ${YELLOW}3. uv pip install <pkg>${RESET} : Download required package from online marketplace"
    echo -e "   > ${YELLOW}4. uv-off-install <pkg>${RESET} : Download required package from offline shared wheel house"

    echo -e "  ------------------------------------------------------------------"
    echo -e "  ${BOLD}${CYAN}COMMON TOOLS (Helpers)${RESET}"
    echo -e "   > ${YELLOW}mypdf${RESET}           : PDF viewer"
    echo -e "   > ${YELLOW}force-logout${RESET}    : Force users logout all sessions (Shortcut: fl)"
    echo -e "   > ${YELLOW}task-manager${RESET}    : Manage the running tasks in server (Shortcut: tm)"
    echo -e "   > ${YELLOW}code-lab${RESET}        : Launch VS Code with shared lab extensions"
    echo -e "   > ${YELLOW}bye${RESET}             : force-logout + task-manager"

    # Section 4: Contact & Support (Localized via config.sh)
    echo -e "  ------------------------------------------------------------------"
    echo -e "  ${BOLD}${RED}CONTACT & SUPPORT${RESET}"
    echo -e "   > TA Support : ${BOLD}${BLUE}${MAIN_MANAGER}${RESET} (${MAIN_MANAGER_EMAIL})"
    echo -e "   > Website    : ${UNDERLINE}${YELLOW}${WEBSITE_URL}${RESET}"

    echo -e "${BLUE}====================================================================${RESET}"
    echo ""
fi
