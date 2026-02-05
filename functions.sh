#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:   Campus Linux Environment Automation (CLEA)
# File Name: functions.sh
# Description: Functions used in scripts
# Organization: NYCU-IEE-SI2 Lab
#
# Author:    Lin-Hung Lai
# Editor:    Bang-Yuan Xiao
# Released:  2026.01.26
# Platform:  Rocky Linux 8.x
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set -Eeuo pipefail

#==================================================
# Messenge Function
#==================================================
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m" 
BOLD="\033[1m"

# Header Function: Magenta/Yellow Theme with Alignment Correction
header() {
    # Usage: header "Project Title" "Current Action" "${LOG_FILE}"
    local title="${1:-CLEA Project}"
    local desc="${2:-Processing...}"
    local timestamp=$(date '+%F %T')
    local log_file="${3:-}"
    
    # Define colors locally for clarity
    local C_BORDER="${YELLOW}${BOLD}"
    local C_TEXT="${RESET}"
    local C_RESET="${RESET}"

    # Top border (Fixed width: 80 characters total)
    printf "\n${C_BORDER}┌────────────────────────────────────────────────────────────────────────────────┐${C_RESET}\n"
    
    # Body rows: Using %-76s ensures the text is padded to 76 chars, 
    # and the border "│" is placed at exactly the 80th column.
    printf "${C_BORDER}│${C_RESET}  ${BOLD}%-76s${C_RESET}  ${C_BORDER}│${C_RESET}\n" "${title}"
    printf "${C_BORDER}│${C_RESET}  %-76s  ${C_BORDER}│${C_RESET}\n" "Action: ${desc}"
    printf "${C_BORDER}│${C_RESET}  %-76s  ${C_BORDER}│${C_RESET}\n" "Time  : ${timestamp}"
    
    # Bottom border
    printf "${C_BORDER}└────────────────────────────────────────────────────────────────────────────────┘${C_RESET}\n"

    # Plain text logging (No ANSI colors in log files)
    if [[ -n "${log_file}" ]]; then
        {
            echo -e "\n[HEADER] ========================================"
            echo "  Title : ${title}"
            echo "  Action: ${desc}"
            echo "  Time  : ${timestamp}"
            echo -e "================================================\n"
        } >> "${log_file}"
    fi
}

# Finish Function: Cyan Theme for Success
finish() {
    # Usage: finish "Module/Script Name" "${LOG_FILE}"
    local name="${1:-Script}"
    local log_file="${2:-}"
    local timestamp=$(date '+%F %T')
    
    local C_BORDER="${CYAN}${BOLD}"
    local C_RESET="${RESET}"

    printf "\n${C_BORDER}╘══════════════════════════════════════════════════════════════════════════════╛${C_RESET}\n"
    printf "  ${GREEN}${BOLD}✔${C_RESET}  ${BOLD}%-72s${C_RESET}\n" "SUCCESSFULLY COMPLETED"
    printf "     %-76s\n" "Script: ${name}"
    printf "     %-76s\n" "End At: ${timestamp}"
    printf "${C_BORDER}╒══════════════════════════════════════════════════════════════════════════════╕${C_RESET}\n\n"

    if [[ -n "${log_file}" ]]; then
        echo -e "[FINISH] ${name} successfully finished at ${timestamp}\n" >> "${log_file}"
    fi
}

# step Function
step() { 
    # Usage: step "Step 1: System Init" "${LOG_FILE}"
    local msg="========== $1 =========="
    local log_file="${2:-}"
    local timestamp=$(date '+%F %T')
    
    # Terminal Display: Using Magenta and Bold
    printf "\n${MAGENTA}${BOLD}[${timestamp}] %s${RESET}\n" "${msg}"
    
    # If log_file is provided, write to the file
    if [[ -n "${log_file}" ]]; then
        # Ensure the directory exists before logging (Optional but recommended)
        # mkdir -p "$(dirname "${log_file}")"
        echo -e "\n[${timestamp}] ${msg}" >> "${log_file}"
    fi
}

# Task Function
task() { # Usage: task "Configuring Network Interface" "${LOG_FILE}"
    
    local msg="---------- $1 ----------"
    local log_file="${2:-}"
    local timestamp=$(date '+%F %T')
    
    # Terminal Display: Using Blue and Bold
    # Unlike the step, we don't necessarily need a leading newline here 
    # unless you want extra spacing.
    printf "${BLUE}${BOLD}[${timestamp}] %s${RESET}\n" "${msg}"
    
    # If log_file is provided, write to the file
    if [[ -n "${log_file}" ]]; then
        echo "[${timestamp}] ${msg}" >> "${log_file}"
    fi
}

# This handles the timestamp, color output, and optional logging.
_log_base() {
    # Usage: _log_base "COLOR_PREFIX" "LEVEL_TEXT" "MESSAGE" "LOG_FILE"
    local color_prefix="$1"
    local level="$2"
    local msg="$3"
    local log_file="$4"
    local timestamp=$(date '+%F %T')

    # 1. Format for Terminal (Keeps internal colors for nested highlighting)
    local term_output="[${timestamp}] ${color_prefix}${level}${RESET} ${msg}"
    
    # 2. Format for File (Strips ANSI color codes for clean text)
    # This regex removes sequences like \033[1;32m
    local plain_msg=$(echo -e "${msg}" | sed "s/$(printf '\033')\[[0-9;]*m//g")
    local file_output="[${timestamp}] ${level} ${plain_msg}"

    # Print to console
    printf "%b\n" "${term_output}"

    # Append to log file if path is provided
    if [[ -n "${log_file}" ]]; then
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "${log_file}")" 2>/dev/null
        echo "${file_output}" >> "${log_file}"
    fi
}

# Use: ok "Message" "${LOG_FILE}"
ok()   { _log_base "${GREEN}" "✔ [OK]  " "$1" "${2:-}"; }
note() { _log_base "${CYAN}"  "ℹ [NOTE]" "$1" "${2:-}"; }
info() { _log_base "${CYAN}"  "ℹ [INFO]" "$1" "${2:-}"; }
warn() { _log_base "${YELLOW}" "⚠ [WARN]" "$1" "${2:-}"; }
err()  { _log_base "${RED}"    "✘ [ERR] " "$1" "${2:-}"; }
msg()  { _log_base "${CYAN}"  "" "$1" "${2:-}"; }

fail() { err "$1" "${2:-}"; exit 1; }

# Just for bold text on screen (no log)
bold() { printf "${BOLD}%s${RESET}\n" "$*"; }

#==================================================
# Script Functions
#==================================================
must_root() {
    if [[ ${EUID} -ne 0 ]]; then
        fail "Root privileges required. Please use sudo: sudo bash ${0}"
    fi
}

enable_sudo_keep_alive() {
    # Update existing sudo timestamp every 60 seconds to prevent timeout
    ( while true; do sleep 60; sudo -n true || exit; done ) 2>/dev/null &
    local pid=${!}

    # Define a trap within the function to kill the background process 
    # when the parent script (main.sh) exits or is interrupted.
    trap "kill ${pid} 2>/dev/null || true" EXIT INT TERM
    
    info "Sudo keep-alive process started (PID: ${pid})"
}

# Usage: dnf_install "vim" "${LOG_FILE}" "update"
dnf_install() {
    local pkg_name="${1}"
    local log_file="${2:-/dev/null}"
    local mode="${3:-check}" # 預設為 check (存在就跳過)

    if [[ "${mode}" == "update" ]]; then
        info "Ensuring '${pkg_name}' is latest..." "${log_file}"
        dnf -y install "${pkg_name}" >> "${log_file}" 2>&1
    elif rpm -q "${pkg_name}" > /dev/null 2>&1; then
        note "Package '${pkg_name}' is already installed. Skipping." "${log_file}"
    else
        info "Package '${pkg_name}' not found. Installing..." "${log_file}"
        dnf -y install "${pkg_name}" >> "${log_file}" 2>&1
    fi
}

render_template() {
    local src="${1}"
    local dest="${2}"
    local log_file="${3:-}"

    # Verify if the source template file exists
    if [[ ! -f "${src}" ]]; then
        err "Template not found: ${src}" "${log_file:-}"
        return 1
    fi

    # Extract all defined variable names from config.sh
    # 1. Ignore comments and empty lines
    # 2. Strip the 'export' keyword
    # 3. Extract the variable name before the '=' sign
    # 4. Prefix with '$' and join with commas for envsubst compatibility
    local vars_array=()
    vars_array=($(grep '=' "${PKG_ROOT}/config.sh" | \
                  grep -v '^#' | \
                  sed -E 's/^\s*export\s+//g' | \
                  cut -d= -f1))
    
    render_vars

    vars_array+=(
        "FIREWALLD_RICH_RULES"
        "SSH_GLOBAL_PORT_TAG"
        "XRDP_GLOBAL_PORT_TAG"
        "SUDOERSD_GROUP_LIST_TMP"
        "SUDOERSD_USER_LIST_TMP"
        "HOSTS_LIST_TMP"
        "VSCODE_EXT_LIST_TMP"
    )

    local defined_vars
    defined_vars=$(printf '$%s,' "${vars_array[@]}")
    defined_vars="${defined_vars%,}"

    # Perform variable substitution
    # Using the whitelist in $defined_vars prevents accidental overwriting of system env vars
    if envsubst "${defined_vars}" < "${src}" > "${dest}"; then
        ok    "Render successfully: ${GREEN}${dest}${RESET} from: ${CYAN}${src}${RESET})" "${log_file:-}"
    else
        err   "Render failed      : ${RED}${dest}${RESET})" "${log_file:-}"
        return 1
    fi
}

render_vars() {
    # Security & Firewall
    FIREWALLD_RICH_RULES=""
    SSH_GLOBAL_PORT_TAG=""
    XRDP_GLOBAL_PORT_TAG=""

    if [[ -n "${FIREWALLD_WHITE_IP_LIST}" ]]; then
        for ip in ${FIREWALLD_WHITE_IP_LIST}; do
            FIREWALLD_RICH_RULES+="
    <rule family=\"ipv4\">
        <source address=\"${ip}\"/>
        <port protocol=\"tcp\" port=\"${SSH_SPEC_PORT}\"/>
        <accept/>
    </rule>
    <rule family=\"ipv4\">
        <source address=\"${ip}\"/>
        <port protocol=\"tcp\" port=\"${XRDP_PORT}\"/>
        <accept/>
    </rule>"
        done
    else
        SSH_GLOBAL_PORT_TAG="<port port=\"${SSH_SPEC_PORT}\" protocol=\"tcp\"/>"
        XRDP_GLOBAL_PORT_TAG="<port port=\"${XRDP_PORT}\" protocol=\"tcp\"/>"
    fi

    export FIREWALLD_RICH_RULES
    export SSH_GLOBAL_PORT_TAG
    export XRDP_GLOBAL_PORT_TAG

    # Sudoers.d
    export SUDOERSD_GROUP_LIST_TMP=$(printf "%b\n" "$(printf "%s\n" "${SUDOERSD_GROUP_LIST[@]}")")
    export SUDOERSD_USER_LIST_TMP=$(printf "%b\n" "$(printf "%s\n" "${SUDOERSD_USER_LIST[@]}")")

    # Hosts
    export HOSTS_LIST_TMP=$(printf "%b\n" "$(printf "%s\n" "${HOSTS_LIST[@]}")")

    # vscode extension
    export VSCODE_EXT_LIST_TMP=$(printf "%b\n" "$(printf "%s\n" "${VSCODE_EXT_LIST[@]}")")
}

sync_with_policy() {
    local src="${1}"
    local dest="${2}"
    local policy="${3}"           # Y: Override existing | N: Ignore existing
    local chmod_val="${4:-D755,F644}" 
    local log_file="${5:-}"       # Added log_file parameter

    if [[ ! -d "${src}" ]]; then
        err "Source directory not found: ${src}" "${log_file}"
        return 1
    fi

    local opts="-avL"
    if [[ "${policy}" == "Y" ]]; then
        info "  Sync Policy: Overwrite mode enabled" "${log_file}"
    else
        opts="${opts} --ignore-existing"
        info "  Sync Policy: Skip existing files" "${log_file}"
    fi

    mkdir -p "${dest}" >> "${log_file}" 2>&1

    # Redirect rsync output to log file
    if rsync ${opts} --chmod="${chmod_val}" "${src}/" "${dest}/" >> "${log_file}" 2>&1; then
        return 0
    else
        err "Synchronization failed for ${dest}" "${log_file}"
        return 1
    fi
}

ensure_symlink() {
  local link_path="${1}"
  local target_path="${2}"
  local log_file="${3:-}"

  if [[ ! -e "${target_path}" ]]; then
    err "Target path does not exist: ${target_path}" "${log_file}"
    return 1
  fi

  # Redirect internal cleanup/creation to log file
  if [[ -L "${link_path}" || -e "${link_path}" ]]; then
    rm -rf "${link_path}" >> "${log_file}" 2>&1
  fi

  if ln -s "${target_path}" "${link_path}" >> "${log_file}" 2>&1; then
    ok "Link Successfully: ${link_path} -> ${target_path}" "${log_file}"
  else
    err "Link Failed: ${link_path}" "${log_file}"
    return 1
  fi
  
  # Silent restorecon
  command -v restorecon >/dev/null 2>&1 && restorecon -RF "$(dirname "${link_path}")" >> "${log_file}" 2>&1 || true
}

write_desktop_file() {
    local file_path="${1}"
    local name="${2}"
    local comment="${3}"
    local exec_cmd="${4}"
    local icon_path="${5}"
    local categories="${6}"
    local terminal="${7:-false}"
    local mime_type=""
    local log_file=""

    if [[ $# -le 8 ]]; then
        log_file="${8:-}"
    else
        mime_type="${8:-}"
        log_file="${9:-}"
    fi

    mkdir -p /etc/skel/Desktop

    cat >"${file_path}" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${name}
Comment=${comment}
Exec=${exec_cmd}
Icon=${icon_path}
Terminal=${terminal}
Categories=${categories}
MimeType=${mime_type}
StartupNotify=true
EOF

    if [[ -f "${file_path}" ]]; then
        # Update the system desktop database to recognize the new shortcut and MIME types
        chmod 644 "${file_path}"
        update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
        ok "Desktop shortcut created: ${name}" "${log_file:-}"
    else
        err "Failed to create ${file_path}" "${log_file:-}"
    fi
}

# 設定登入自動同步桌面圖示" (Bash version)
write_desktop_init_file_bash() {
    local tool_name="${1}"
    local log_file="${2:-}"
    local profile_script="/etc/profile.d/zz-${tool_name}_init.sh"

    # Create a global initialization script to deploy desktop icons upon user login
    cat > "${profile_script}" <<EOF
# Automatically deploy the ${tool_name} shortcut ONLY for graphical sessions (e.g., xrdp)
# This prevents creating a 'Desktop' folder during pure SSH logins.

if [ "\${USER}" != "root" ] && [ -n "\${DISPLAY}" ]; then
    
    # Check if this is an xrdp session or a recognized desktop environment
    if [ -n "\${XRDP_SESSION}" ] || [ -n "\${XDG_CURRENT_DESKTOP}" ]; then
        
        DESKTOP_PATH="\${HOME}/Desktop"
        
        # Only proceed if the Desktop directory has already been created by the system
        if [ -d "\${DESKTOP_PATH}" ]; then
            
            # Deploy shortcut if it does not already exist
            if [ ! -f "\${DESKTOP_PATH}/${tool_name}.desktop" ]; then
                
                # Verify source file existence before copying
                if [ -f "/etc/skel/Desktop/${tool_name}.desktop" ]; then
                    cp "/etc/skel/Desktop/${tool_name}.desktop" "\${DESKTOP_PATH}/${tool_name}.desktop"
                    chmod 755 "\${DESKTOP_PATH}/${tool_name}.desktop"
                fi
            fi
        fi
    fi
fi
EOF

    chmod 644 "${profile_script}"
    ok "Global login script established: ${profile_script}" "${log_file:-}"
}

# 設定登入自動同步桌面圖示" (Tcsh version)
write_desktop_init_file_tcsh() {
    local tool_name="${1}"
    local log_file="${2:-}"
    local profile_script="/etc/profile.d/zz-${tool_name}_init.csh"

    cat > "${profile_script}" << EOF
# Automatically deploy the ${tool_name} shortcut ONLY for graphical sessions (e.g., xrdp)
# This prevents creating a 'Desktop' folder during pure SSH logins.

if ( \$?prompt && "\$user" != "root" ) then
    if ( \$?DISPLAY ) then
        # Check if this is an xrdp session or a recognized desktop environment
        if ( \$?XRDP_SESSION || \$?XDG_CURRENT_DESKTOP ) then
            
            set DESKTOP_PATH = "\$HOME/Desktop"
            
            # Only proceed if the Desktop directory has already been created by the system
            if ( -d "\$DESKTOP_PATH" ) then
                
                # Deploy shortcut if it does not already exist
                if ( ! -e "\$DESKTOP_PATH/${tool_name}.desktop" ) then
                    set SRC_FILE = "/etc/skel/Desktop/${tool_name}.desktop"
                    
                    # Verify source file existence before copying
                    if ( -f "\$SRC_FILE" ) then
                        cp "\$SRC_FILE" "\$DESKTOP_PATH/${tool_name}.desktop"
                        chmod 755 "\$DESKTOP_PATH/${tool_name}.desktop"
                    endif
                    
                    unset SRC_FILE
                endif
            endif
            
            unset DESKTOP_PATH
        endif
    endif
endif
EOF

    chmod 644 "${profile_script}"
    ok "Global login script established: ${profile_script}" "${log_file:-}"
}

# Usage: create_setup <src> <dest> [log_file] [max_depth] [current_depth]
create_setup() {
    local template_dir="${1}"
    local setup_dir="${2}"
    local log_file="${3:-}"
    local max_depth="${4:--1}"     # Default -1 means infinite/all levels
    local current_depth="${5:-0}"   # Track current nesting level

    # 1. Safety Check: Verify source directory
    if [[ ! -d "${template_dir}" ]]; then
        err "Source directory not found: ${template_dir}" "${log_file}"
        return 1
    fi

    # 2. Depth Check: Stop recursion if limit is reached
    # If max_depth is set (>= 0) and current_depth exceeds it, stop processing subdirectories
    if [[ "${max_depth}" -ge 0 && "${current_depth}" -gt "${max_depth}" ]]; then
        return 0
    fi

    # 3. Preparation: Ensure destination directory exists
    mkdir -p "${setup_dir}"

    # 4. Iteration: Traverse files and folders
    for src_path in "${template_dir}"/*; do
        [[ -e "${src_path}" ]] || continue

        local base_name=$(basename "${src_path}")
        local dest_path="${setup_dir}/${base_name}"

        if [[ -d "${src_path}" ]]; then
            if [[ "${current_depth}" -lt "${max_depth}" ]]; then
                create_setup "${src_path}" "${dest_path}" "${log_file}" "${max_depth}" $((current_depth + 1))
            else
                ensure_symlink "${dest_path}" "${src_path}" "${log_file}"
            fi            
        elif [[ "${base_name}" == tmpl_* ]]; then
            # --- Scenario B: Template file detected ---
            local dest_name="${base_name##tmpl_}"
            local final_dest="${setup_dir}/${dest_name}"
            render_template "${src_path}" "${final_dest}" "${log_file}"
        else
            # --- Scenario C: Standard file ---
            ensure_symlink "${dest_path}" "${src_path}" "${log_file}"
        fi
    done
}

nfs_mount() {
    local server_ip="${1}"
    local remote_dir="${2}"
    local local_dir="${3}"
    local log_file="${4:-}"
    local mount_timeout="30s"

    # Ensure local mount point directory exists
    mkdir -p "${local_dir}"

    # --- Step 1: Handle Existing Mounts (The "Safety Clean" Logic) ---
    # Check if the directory is currently a mount point
    if mountpoint -q "${local_dir}"; then
        note "Mount point '${local_dir}' is currently active. Attempting to safely unmount..." "${log_file}"
        
        # 1. Try standard unmount first
        if ! timeout 5 sudo umount "${local_dir}" >> "${log_file}" 2>&1; then
            warn "Standard umount failed or timed out. Forcing Lazy Unmount on ${local_dir}..." "${log_file}"
            # 2. Use Lazy Unmount to clear stale handles/zombie paths
            sudo umount -fl "${local_dir}" >> "${log_file}" 2>&1
            ok "Lazy unmount executed successfully." "${log_file}"
        else
            ok "Successfully unmounted existing volume." "${log_file}"
        fi
        
        # Give the kernel a moment to release resources
        sleep 1
    fi

    # --- Step 2: Update /etc/fstab ---
    # Construct the fstab entry line
    local line="${server_ip}:${remote_dir} ${local_dir} nfs4 _netdev,vers=4,fsc,async 0 0"

    # We use awk to ensure we don't accidentally match the remote_dir in Column 1
    if awk -v target="${local_dir}" '$2 == target {found=1} END {exit !found}' /etc/fstab; then
        note "Mount point '${local_dir}' already exists in /etc/fstab. Updating entry..." "${log_file}"
        
        # Use sed to replace the entire line where Column 2 matches local_dir
        # The regex ensures we match: Start of line -> Non-space (Col 1) -> Space -> Target (Col 2)
        sed -i "s~^[[:graph:]]\+[[:space:]]\+${local_dir}[[:space:]].*~${line}~" /etc/fstab
        ok "Successfully updated /etc/fstab entry for ${local_dir}" "${log_file}"
    else
        # --- Step 2: If mount point is new, append to the end of file ---
        info "Mount point '${local_dir}' is new. Adding to /etc/fstab..." "${log_file}"
        echo "${line}" >> /etc/fstab
        ok "Successfully added new entry to /etc/fstab" "${log_file}"
    fi

    # --- Step 3: Refresh system and execute mount ---
    systemctl daemon-reload >> "${log_file}" 2>&1
    
    info "Attempting to mount ${local_dir} (Timeout: ${mount_timeout})..." "${log_file}"
    
    if timeout "${mount_timeout}" mount -a >> "${log_file}" 2>&1; then
        ok "NFS volume mounted successfully at ${local_dir}" "${log_file}"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            fail "Mount operation timed out after ${mount_timeout}. Server ${server_ip} might be unreachable." "${log_file}"
        else
            fail "Mount failed with exit code ${exit_code}. Check ${log_file} for detailed error logs." "${log_file}"
        fi
    fi
}


#==================================================
# Function used in 05_install_vscode.sh
#==================================================
ext_exists_in_marketplace() {
    local id="${1}"
    local log_file="${2:-}"
    
    # 使用 curl 檢查 Marketplace 網頁是否存在
    # -s: 安靜模式
    # -I: 僅抓取標頭 (Header) 以節省流量
    # -o /dev/null: 不輸出網頁內容
    # -w "%{http_code}": 僅輸出 HTTP 狀態碼
    local status
    status=$(curl -sL -o /dev/null -w "%{http_code}" "https://marketplace.visualstudio.com/items?itemName=${id}")
    
    if [ "$status" -eq 200 ]; then
        info "Marketplace check: ID '$id' is valid (HTTP 200)." "${log_file}" >&2
        return 0  # 存在
    else
        warn "Marketplace check: ID '$id' not found (HTTP $status)." "${log_file}" >&2
        return 1  # 不存在
    fi
}


download_vsix_from_ovsx() {
    local id="${1}"
    local log_file="${2:-}"
    local id_lower=$(echo "$id" | tr '[:upper:]' '[:lower:]')
    local pub="${id_lower%%.*}"
    local name="${id_lower#*.}"
    
    # 1. 先抓取 JSON 資訊
    local api_json_url="https://open-vsx.org/api/${pub}/${name}/latest"
    local json_content
    json_content=$(curl -sL "$api_json_url")
    
    # 2. 從 JSON 中用 grep 抓取正確的 download URL (不需要 jq)
    # 我們找 "download":"https://..." 這一段
    local dl_url
    dl_url=$(echo "$json_content" | grep -oP '"download":"\K[^"]+')
    
    if [ -z "$dl_url" ]; then
        err "Could not find download URL in API response for $id" "${log_file}" >&2
        return 1
    fi

    # 3. 執行下載
    mkdir -p "$CACHE"
    local out="$CACHE/${id_lower}-latest.vsix"
    
    info "Downloading latest VSIX from: $dl_url" "${log_file}" >&2
    if curl -fL "$dl_url" -o "$out" >> "${log_file}" 2>&1; then
        if unzip -t "$out" >/dev/null 2>&1; then
            echo "$out"
            return 0
        fi
    fi
    return 1
}

# 不再呼叫 `code --list-extensions`；直接檢查共用 extensions 資料夾是否已存在
ext_is_installed(){ # $1=publisher.extension
  local id="$1"
  shopt -s nullglob nocaseglob
  local matches=( "$EXT_DIR/${id}-"* )
  shopt -u nocaseglob
  [[ ${#matches[@]} -gt 0 ]]
}

code_cli(){
  ELECTRON_ENABLE_LOGGING=0 /usr/bin/code \
    --extensions-dir "$EXT_DIR" \
    --user-data-dir "$CLI_USERDATA" \
    "$@"
}

install_one_ext() {
    local id="${1}"
    local log_file="${2:-}"
    local VSCODE_EXT_RETRY=3

    # Step 1. Check if already installed
    if ext_is_installed "$id"; then
        info "Extension '$id' is already installed. Skipping." "${log_file}"
        return 0
    fi

    # Step 2. Attempt Online Marketplace Installation
    if ! ext_exists_in_marketplace "$id" "${log_file}"; then
        warn "Extension '$id' not found in Marketplace. Skipping to VSIX check." "${log_file}"
    else
        local try
        for (( try=1; try<=VSCODE_EXT_RETRY; try++ )); do
            info "Installing $id (Online attempt $try/$VSCODE_EXT_RETRY)..." "${log_file}"
            
            # 關鍵修正 3：移除 tee -a，改用 >> 重導向以保持終端乾淨
            code_cli --install-extension "$id" --force >> "${log_file}" 2>&1
            
            if [ $? -eq 0 ]; then
                ok "Successfully installed '$id' via Marketplace." "${log_file}"
                return 0
            fi
            
            warn "Online attempt $try failed for '$id'. Retrying..." "${log_file}"
            sleep 1
        done
    fi

    # Step 3. Fallback to VSIX Installation
    for (( try=1; try<=VSCODE_EXT_RETRY; try++ )); do
        info "Falling back to VSIX for '$id' (Attempt $try/$VSCODE_EXT_RETRY)..." "${log_file}"
        
        local vsix
        # 關鍵修正 4：確保子 shell 的錯誤輸出不會噴到終端
        if vsix=$(download_vsix_from_ovsx "$id" "$log_file" 2>>"${log_file}"); then
            
            # 關鍵修正 5：使用變數時確保移除 tee
            code_cli --install-extension "$vsix" --force >> "${log_file}" 2>&1
            
            if [ $? -eq 0 ]; then
                ok "Successfully installed '$id' via VSIX package." "${log_file}"
                [ -f "$vsix" ] && rm -f "$vsix" # 安裝完後清理
                return 0
            fi
        fi
        
        warn "VSIX attempt $try failed for '$id'." "${log_file}"
        sleep 1
    done

    # Step 4. Final failure report
    err "Installation failed for '$id' after all attempts." "${log_file}"
    return 0
}

read_ext_ids_from_file(){
  local f="$1"
  mapfile -t ids < <(grep -vE '^\s*#' "$f" | sed '/^\s*$/d' | tr -d '\r')
  printf '%s\n' "${ids[@]}"
}

#==================================================
# Function used in 06_install_mypdf.sh
#==================================================
ensure_group() {
  local grp="${1}"
  local log_file="${2:-}"
  if getent group "${grp}" >/dev/null 2>&1; then
    ok "Group already exists: ${grp}" "${log_file}"
  else
    fail "Group does not exist: ${grp}" "${log_file}"
  fi
}

ensure_dir() {
  local d="${1}" # directory
  local p="${2}" # permission
  local owner="${3}"
  local group="${4}"
  local log_file="${5:-}"
  
  mkdir -p "${d}"
  chown "${owner}:${group}" "${d}"
  chmod "${p}" "${d}"
#   ok "Verified directory ${d}: Owner=${owner}:${group}, Perm=${p}" "${log_file}"
}

#==================================================
# Function used in 07_install_uv.sh
#==================================================
download_one() {
    local pyver="${1}"
    local pkg="${2}"
    local count_info="${3}"
    info "  - [py${pyver}] ${count_info} Fetching: ${pkg}" "${LOG_FILE_07}"
    
    "${UV_CMD}" run --python "${pyver}" -m pip download \
        --exists-action i --only-binary=:all: -d "${WHEELHOUSE}" "${pkg}" >> "${LOG_FILE_07}" 2>&1 || {
            echo "[py${pyver}] ${pkg}" >> "${SKIP_LOG}"
            warn "    >> ${pkg} skipped (Check log)" "${LOG_FILE_07}"
            return 0
        }
    ok "    >> ${pkg} downloaded." "${LOG_FILE_07}"
}

