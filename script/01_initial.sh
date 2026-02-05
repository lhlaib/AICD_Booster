#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    01_initial.sh
# Description:  Basic System Initialization & Environment Setup
# Organization: NYCU-IEE-SI2 Lab
#
# Author:       Lin-Hung Lai
# Editor:       Bang-Yuan Xiao
# Released:     2026.01.26
# Platform:     Rocky Linux 8.x
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set -Eeuo pipefail

#==================================================
# Configuration & Functions
#==================================================
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../functions.sh"

must_root
enable_sudo_keep_alive 

# OS version detection
OS_VER=$(rpm -E %{rhel})
REPO_EXT=$([[ "${OS_VER}" == "8" ]] && echo "powertools" || echo "crb")

# application root 
BYE_ROOT="${TOOL_ROOT}/bye"
FORCE_LOGOUT_ROOT="${TOOL_ROOT}/force-logout"
TASK_MANAGER_ROOT="${TOOL_ROOT}/task-manager"

# Desktop entries path
DESKTOP_SKEL_DIR="/etc/skel/Desktop"
DESKTOP_SKEL_FL="${DESKTOP_SKEL_DIR}/force-logout.desktop"
DESKTOP_SKEL_TM="${DESKTOP_SKEL_DIR}/task-manager.desktop"
DESKTOP_SYS_DIR="/usr/share/applications"
DESKTOP_SYS_FL="${DESKTOP_SYS_DIR}/force-logout.desktop"
DESKTOP_SYS_TM="${DESKTOP_SYS_DIR}/task-manager.desktop"

# Log file initialization
LOG_FILE_01="${LOG_DIR}/01_initial.log"
if [[ -f "${LOG_FILE_01}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_01}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_01}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_01}"

header "01_initial.sh" "Basic System Initialization & Environment Setup" "${LOG_FILE_01}"

#==================================================
# Step 1. OS Maintenance & Repositories
#==================================================
step "Step 1. OS Maintenance & Repositories" "${LOG_FILE_01}"

#----------------------------------------
# Task 1. Package Synchronization
#----------------------------------------
task "Task 1. Package Synchronization" "${LOG_FILE_01}"
info "Refreshing DNF cache and updating system (Check log for details)..." "${LOG_FILE_01}"

# Perform a full system update to ensure security patches are current
if dnf -y update >> "${LOG_FILE_01}" 2>&1; then
    ok "System packages synchronized successfully." "${LOG_FILE_01}"
else
    warn "System update encountered issues. Attempting cache clean and retry..." "${LOG_FILE_01}"
    dnf clean all -y >> "${LOG_FILE_01}" 2>&1
    dnf -y makecache >> "${LOG_FILE_01}" 2>&1
    dnf -y update >> "${LOG_FILE_01}" 2>&1 && ok "System update retry successful." "${LOG_FILE_01}"
fi

#----------------------------------------
# Task 2. Repository Activation
#----------------------------------------
task "Task 2. Repository Activation" "${LOG_FILE_01}"

# Ensure basic repo tools exist
dnf_install "epel-release" "${LOG_FILE_01}"
dnf_install "dnf-plugins-core" "${LOG_FILE_01}"

# Activate the repository
info "Enabling extended repository: ${REPO_EXT}..." "${LOG_FILE_01}"
if dnf config-manager --set-enabled "${REPO_EXT}" >> "${LOG_FILE_01}" 2>&1; then
    ok "Repository '${REPO_EXT}' enabled for Rocky ${OS_VER}." "${LOG_FILE_01}"
else
    err "Failed to enable '${REPO_EXT}'. Some tools may be unavailable." "${LOG_FILE_01}"
fi

#----------------------------------------
# Task 3. Core Utilities Installation
#----------------------------------------
task "Task 3. Core Utilities Installation" "${LOG_FILE_01}"

# Essential CLI tools installation
info "Installing essential CLI tools..." "${LOG_FILE_01}"

CORE_TOOLS=(
    tcsh vim lsof tree htop iftop curl wget bind-utils 
    net-tools which unzip tar bzip2 xz git evince nmap-ncat
    policycoreutils-python-utils
)

for pkg in "${CORE_TOOLS[@]}"; do
    dnf_install "${pkg}" "${LOG_FILE_01}"
done

#----------------------------------------
# Task 4. Time Zone Configuration
#----------------------------------------
task "Task 4. Time Zone Configuration" "${LOG_FILE_01}"

# Skip this step if time zone has been updated
CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')

if [[ "${CURRENT_TZ}" == "${TIMEZONE}" ]]; then
    info "Time zone is already set to ${TIMEZONE}. Skipping." "${LOG_FILE_01}"
else
    if timedatectl set-timezone "${TIMEZONE}" >> "${LOG_FILE_01}" 2>&1; then
        ok "Time zone set to ${TIMEZONE}. Current: $(date)" "${LOG_FILE_01}"
    else
        err "Failed to set time zone to ${TIMEZONE}." "${LOG_FILE_01}"
    fi
fi

#==================================================
# Step 2. Storage & Networking (NFS)
#==================================================
step "Step 2. Storage & Networking" "${LOG_FILE_01}"

#----------------------------------------
# Task 1. NFS & Autofs Services
#----------------------------------------
task "Task 1. NFS & Autofs Services" "${LOG_FILE_01}"

# Install necessary NFS client packages
dnf_install "nfs-utils" "${LOG_FILE_01}"
dnf_install "autofs"    "${LOG_FILE_01}"
dnf_install "quota"     "${LOG_FILE_01}"
dnf_install "quota-nls" "${LOG_FILE_01}"

# Enable and start required services
systemctl enable --now rpcbind >> "${LOG_FILE_01}" 2>&1
systemctl enable --now autofs >> "${LOG_FILE_01}" 2>&1
ok "NFS and Autofs services are active." "${LOG_FILE_01}"

#----------------------------------------
# Task 2. Local FS-Cache Setup
#----------------------------------------
task "Task 2. Local FS-Cache Setup" "${LOG_FILE_01}"

# FS-Cache improves NFS performance by caching files on the local disk
dnf_install "cachefilesd" "${LOG_FILE_01}"
systemctl enable --now cachefilesd >> "${LOG_FILE_01}" 2>&1
ok "Cachefilesd (local NFS caching) enabled." "${LOG_FILE_01}"

#----------------------------------------
# Task 3. NFS Mount Operations
#----------------------------------------
task "Task 3. NFS Mount Operations" "${LOG_FILE_01}"

# DEPLOY_ROOT Mount
if [[ "${NFS_MOUNT}" == "Y" ]]; then
    if [[ -n "${NFS_SERVER}" && -n "${NFS_REMOTE}" && -n "${DEPLOY_ROOT}" ]]; then
        # Mount the specified mountpoint and create the directory if all variables are valid
        info "Initiating NFS mount for DEPLOY_ROOT..." "${LOG_FILE_01}"
        nfs_mount "${NFS_SERVER}" "${NFS_REMOTE}" "${DEPLOY_ROOT}" "${LOG_FILE_01}"
    else
        # Mount failed if any variable is invalid
        fail "Invalid variables for NFS server. Check your config.sh." "${LOG_FILE_01}"
    fi
else
    # Create the local directory for installation
    info "NFS_MOUNT is 'N'. Ensuring local directory exists: ${DEPLOY_ROOT}" "${LOG_FILE_01}"
    mkdir -p "${DEPLOY_ROOT}" >> "${LOG_FILE_01}" 2>&1
    ok "Local path ready: ${DEPLOY_ROOT}" "${LOG_FILE_01}"
fi

# --- FTP_LOCAL Mount ---
if [[ "${FTP_MOUNT}" == "Y" ]]; then
    if [[ -n "${FTP_SERVER}" && -n "${FTP_REMOTE}" && -n "${FTP_LOCAL}" ]]; then
        # Mount the specified mountpoint and create the directory if all variables are valid
        info "Initiating NFS mount for FTP_LOCAL..." "${LOG_FILE_01}"
        nfs_mount "${FTP_SERVER}" "${FTP_REMOTE}" "${FTP_LOCAL}" "${LOG_FILE_01}"
    else
        # Mount failed if any variable is invalid
        fail "Invalid NFS variables for FTP server. Check your config.sh." "${LOG_FILE_01}"
    fi
else 
    # Create the local directory for FTP upload
    info "FTP_MOUNT is 'N'. Ensuring local directory exists: ${FTP_LOCAL}" "${LOG_FILE_01}"
    mkdir -p "${FTP_LOCAL}" >> "${LOG_FILE_01}" 2>&1
    ok "Local path ready: ${FTP_LOCAL}" "${LOG_FILE_01}"
fi

#==================================================
# Step 3. Lab Administrative Tools
#==================================================
step "Step 3. Lab Administrative Tools" "${LOG_FILE_01}"

#----------------------------------------
# Task 1. Bye (Admin Helper)
#----------------------------------------
task "Task 1. Install 'bye' Tool" "${LOG_FILE_01}"
if [[ "${BYE_INSTALL}" == "Y" ]]; then
    SRC_BYE="${SETUP_DIR}/tool/bye/bye"
    if [[ -f "${SRC_BYE}" ]]; then
        info "Start installing the tool: bye" "${LOG_FILE_01}"

        # Main script installation for bye
        mkdir -p "${BYE_ROOT}" "${BIN_ROOT}" >> "${LOG_FILE_01}" 2>&1
        install -m 755 "${SRC_BYE}" "${BYE_ROOT}/bye" >> "${LOG_FILE_01}" 2>&1

        # Create the linked bin
        ensure_symlink "${BIN_ROOT}/bye" "${BYE_ROOT}/bye" "${LOG_FILE_01}"

        ok "Tool 'bye' installed successfully." "${LOG_FILE_01}"
    else
        # Skip if the main script do not exist
        warn "Source binary for 'bye' not found. Skipping." "${LOG_FILE_01}"
    fi
else
    # Skip if the manager do not want to install this tool
    info "BYE_INSTALL is 'N'. Skipping." "${LOG_FILE_01}"
fi

#----------------------------------------
# Task 2. Force-Logout (User Utility)
#----------------------------------------
task "Task 2. Install 'force-logout' Utility" "${LOG_FILE_01}"
if [[ "${FORCE_LOGOUT_INSTALL}" == "Y" ]]; then
    SRC_FL="${SETUP_DIR}/tool/force-logout/force-logout"
    if [[ -f "${SRC_FL}" ]]; then
        info "Start installing the tool: force-logout" "${LOG_FILE_01}"

        # Main script installation for force-logout
        mkdir -p "${FORCE_LOGOUT_ROOT}" "${BIN_ROOT}" >> "${LOG_FILE_01}" 2>&1
        install -m 755 "${SRC_FL}" "${FORCE_LOGOUT_ROOT}/force-logout" >> "${LOG_FILE_01}" 2>&1
        install -m 755 "${SRC_FL}.png" "${FORCE_LOGOUT_ROOT}/force-logout.png" >> "${LOG_FILE_01}" 2>&1
        
        # Create the linked bin
        ensure_symlink "${BIN_ROOT}/force-logout" "${FORCE_LOGOUT_ROOT}/force-logout" "${LOG_FILE_01}"
        ensure_symlink "${BIN_ROOT}/fl" "${FORCE_LOGOUT_ROOT}/force-logout" "${LOG_FILE_01}"
        
        # Create the desktop shortcut for remote desktop
        write_desktop_file "${DESKTOP_SKEL_FL}" "Force Logout" "Logout all sessions" \
            "${FORCE_LOGOUT_ROOT}/force-logout --now" "${FORCE_LOGOUT_ROOT}/force-logout.png" \
            "System;" "false" "" "${LOG_FILE_01}"
        
        chmod 755 "${DESKTOP_SKEL_FL}" >> "${LOG_FILE_01}" 2>&1

        # Enforce tool shortcuts on each user's desktop at login to ensure consistent environment access
        write_desktop_init_file_bash "force-logout" "${LOG_FILE_01}"
        write_desktop_init_file_tcsh "force-logout" "${LOG_FILE_01}"

        # Create the desktop menu for remote desktop
        write_desktop_file "${DESKTOP_SYS_FL}" "Force Logout" "Logout all sessions" \
            "${FORCE_LOGOUT_ROOT}/force-logout --now" "${FORCE_LOGOUT_ROOT}/force-logout.png" \
            "System;" "false" "" "${LOG_FILE_01}"

        ok "Force-logout utility and desktop icons deployed." "${LOG_FILE_01}"
    else
        # Skip if the main script do not exist
        warn "Force-logout binary missing. Skipping." "${LOG_FILE_01}"
    fi
else
    # Skip if the manager do not want to install this tool
    info "FORCE_LOGOUT_INSTALL is 'N'. Skipping." "${LOG_FILE_01}"
fi

#----------------------------------------
# Task 3. Task Manager
#----------------------------------------
task "Task 3. Install 'task-manager' Utility" "${LOG_FILE_01}"
if [[ "${TASK_MANAGER_INSTALL}" == "Y" ]]; then
    SRC_TM="${SETUP_DIR}/tool/task-manager/task-manager"
    if [[ -f "${SRC_TM}" ]]; then
        info "Start installing the tool: task-manager" "${LOG_FILE_01}"

        # Main script installation for task-manager
        mkdir -p "${TASK_MANAGER_ROOT}" "${BIN_ROOT}" >> "${LOG_FILE_01}" 2>&1
        install -m 755 "${SRC_TM}" "${TASK_MANAGER_ROOT}/task-manager" >> "${LOG_FILE_01}" 2>&1
        install -m 755 "${SRC_TM}.png" "${TASK_MANAGER_ROOT}/task-manager.png" >> "${LOG_FILE_01}" 2>&1
        
        # Create the linked bin
        ensure_symlink "${BIN_ROOT}/task-manager" "${TASK_MANAGER_ROOT}/task-manager" "${LOG_FILE_01}"
        ensure_symlink "${BIN_ROOT}/tm" "${TASK_MANAGER_ROOT}/task-manager" "${LOG_FILE_01}"
        
        # Create the desktop shortcut for remote desktop
        write_desktop_file "${DESKTOP_SKEL_TM}" "Task Manager" "Manage running tasks" \
            "${TASK_MANAGER_ROOT}/task-manager" "${TASK_MANAGER_ROOT}/task-manager.png" \
            "System;" "true" "" "${LOG_FILE_01}"

        chmod 755 "${DESKTOP_SKEL_TM}" >> "${LOG_FILE_01}" 2>&1

        # Enforce tool shortcuts on each user's desktop at login to ensure consistent environment access
        write_desktop_init_file_bash "task-manager" "${LOG_FILE_01}"
        write_desktop_init_file_tcsh "task-manager" "${LOG_FILE_01}"

        # Create the desktop menu for remote desktop
        write_desktop_file "${DESKTOP_SYS_TM}" "Task Manager" "Manage running tasks" \
            "${TASK_MANAGER_ROOT}/task-manager" "${TASK_MANAGER_ROOT}/task-manager.png" \
            "System;" "true" "" "${LOG_FILE_01}"

        ok "Task Manager utility deployed." "${LOG_FILE_01}"
    else
        # Skip if the main script do not exist
        warn "Task Manager binary missing. Skipping." "${LOG_FILE_01}"
    fi
else
    # Skip if the manager do not want to install this tool
    info "TASK_MANAGER_INSTALL is 'N'. Skipping." "${LOG_FILE_01}"
fi

#==================================================
# Step 4. Execution Summary
#==================================================
step "Step 4. Check the Summary information" "${LOG_FILE_01}"

# Count actual results
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")

MOUNT_STATUS=$([[ -d "${DEPLOY_ROOT}" ]] && df -h "${DEPLOY_ROOT}" | grep -q "${NFS_SERVER}" && echo "Mounted (NFS)" || echo "Local Directory")

INSTALLED_TOOLS=0
[[ "${BYE_INSTALL}" == "Y" ]] && INSTALLED_TOOLS=$((INSTALLED_TOOLS + 1)) || true
[[ "${FORCE_LOGOUT_INSTALL}" == "Y" ]] && INSTALLED_TOOLS=$((INSTALLED_TOOLS + 1)) || true
[[ "${TASK_MANAGER_INSTALL}" == "Y" ]] && INSTALLED_TOOLS=$((INSTALLED_TOOLS + 1)) || true

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  Initialization Complete: 01_initial.sh"
    echo -e "======================================================================"
    echo -e "  [System Info]"
    echo -e "    • OS Release      : Rocky Linux ${OS_VER}"
    echo -e "    • Repository      : ${REPO_EXT} (Enabled)"
    echo -e "    • Time Zone       : ${CURRENT_TZ}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Storage & Network]"
    echo -e "    • DEPLOY_ROOT     : ${DEPLOY_ROOT}"
    echo -e "    • Mount Status    : ${MOUNT_STATUS}"
    echo -e "    • FS-Cache        : Active (cachefilesd)"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Administrative Tools]"
    echo -e "    • Tools Installed : ${INSTALLED_TOOLS} (bye, force-logout, task-manager)"
    echo -e "    • Desktop Skel    : ${DESKTOP_SKEL_DIR} (Localized)"
    echo -e "----------------------------------------------------------------------"
    echo -e "  log saved to: ${LOG_FILE_01}"
    echo -e "  Next Recommended: 02_connection.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_01}"

finish "01_initial.sh" "${LOG_FILE_01}"
exit 0
