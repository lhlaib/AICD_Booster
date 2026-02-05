#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    06_install_mypdf.sh
# Description:  MyPDF Watermark PDF Service Installer
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

# --- Local Parameters ---
MYPDF_ROOT="${TOOL_ROOT}/mypdf"
ADMIN_DIR="${DOC_ROOT}/admin"
DOCS_DIR="${ADMIN_DIR}/docs"
TECH_DOC="${DOCS_DIR}/${DOC_CASE}/Tech_Doc"
MYPDF_BIN="${MYPDF_ROOT}/mypdf"
MYPDF_ICON="${MYPDF_ROOT}/_internal/icons/mypdf.png"

# --- Paths ---
DESKTOP_SYS="/usr/share/applications/mypdf.desktop"
DESKTOP_SKEL_DIR="/etc/skel/Desktop"
DESKTOP_SKEL="${DESKTOP_SKEL_DIR}/mypdf.desktop"
NFS_TARGET="${ADMIN_DIR}/mypdf"
VARLIB_LINK="/var/lib/mypdf"
CONFIG_PATH="${NFS_TARGET}/config.json"

# --- Permissions & Ownership ---
ADMIN_GROUP="${ADMIN}"
PERM_ADMIN=771
PERM_DOCS=771
PERM_CASE=771
PERM_TECHDOC=775
PERM_VAR_ADMIN=771
PERM_VAR_MYPDF=771
PERM_DESKTOP_SYS=644
PERM_DESKTOP_SKEL=755
PERM_CONFIG=770

# Log file initialization
LOG_FILE_06="${LOG_DIR}/06_install_mypdf.log"
if [[ -f "${LOG_FILE_06}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_06}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_06}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_06}"

# header
header "06_install_mypdf.sh" "MyPDF Watermark PDF Service Installer" "${LOG_FILE_06}"

#==================================================
# Step 0. Pre-installation Check
#==================================================
step "Step 0. Pre-installation Check" "${LOG_FILE_06}"

if [[ "${MYPDF_INSTALL^^}" == Y* ]]; then
    info "Feature Enabled: MYPDF_INSTALL is 'Y'." "${LOG_FILE_06}"
    info "Initiating MyPDF installation sequence..." "${LOG_FILE_06}"
else
    warn "Feature Disabled: MYPDF_INSTALL is set to '${MYPDF_INSTALL:-NA}'." "${LOG_FILE_06}"
    info "To enable, edit your 'config.sh' and set: MYPDF_INSTALL=\"Y\"" "${LOG_FILE_06}"
    
    finish "06_install_mypdf.sh" "${LOG_FILE_06}"
    exit 0
fi

#==================================================
# Step 1. Group Infrastructure Verification
#==================================================
step "Step 1. Verifying System Groups" "${LOG_FILE_06}"

#----------------------------------------
# Task 1. Verify Admin Group
#----------------------------------------
task "Task 1. Verifying Administrative Group: ${ADMIN_GROUP}" "${LOG_FILE_06}"

if ensure_group "${ADMIN_GROUP}" "${LOG_FILE_06}"; then
    ok "Administrative group '${ADMIN_GROUP}' verified." "${LOG_FILE_06}"
else
    err "Failed to verify administrative group: ${ADMIN_GROUP}" "${LOG_FILE_06}"
fi

#----------------------------------------
# Task 2. Process-Specific Groups
#----------------------------------------
task "Task 2. Initializing Process-Specific Groups" "${LOG_FILE_06}"

for subdir in "${!PROCESS_GROUP_MAP[@]}"; do
    target_group="${PROCESS_GROUP_MAP[${subdir}]}"
    if ensure_group "${target_group}" "${LOG_FILE_06}"; then
        ok "Group '${target_group}' ready for ${subdir}." "${LOG_FILE_06}"
    else
        warn "Could not initialize group '${target_group}' for ${subdir}." "${LOG_FILE_06}"
    fi
done

#==================================================
# Step 2. Directory and Permission Setup
#==================================================
step "Step 2. Initializing Directory Hierarchy" "${LOG_FILE_06}"

#----------------------------------------
# Task 1. Core Path Setup
#----------------------------------------
task "Task 1. Establishing Core Hierarchy" "${LOG_FILE_06}"
mkdir -p "${DOC_ROOT}" >> "${LOG_FILE_06}" 2>&1

ensure_dir "${ADMIN_DIR}"           "${PERM_ADMIN}"    root  "${ADMIN_GROUP}"  "${LOG_FILE_06}"
ensure_dir "${DOCS_DIR}"            "${PERM_DOCS}"     root  "${ADMIN_GROUP}"  "${LOG_FILE_06}"
ensure_dir "${DOCS_DIR}/${DOC_CASE}" "${PERM_CASE}"     root  "${ADMIN_GROUP}" "${LOG_FILE_06}"
ensure_dir "${TECH_DOC}"             "${PERM_TECHDOC}"  root  "${ADMIN_GROUP}" "${LOG_FILE_06}"
ok "Core documentation paths established." "${LOG_FILE_06}"

#----------------------------------------
# Task 2. Mapping Process-Specific Permissions
#----------------------------------------
task "Task 2. Mapping Process Group Permissions" "${LOG_FILE_06}"
for subdir in "${!PROCESS_GROUP_MAP[@]}"; do
    local_path="${TECH_DOC}/${subdir}"
    group="${PROCESS_GROUP_MAP[${subdir}]}"

    mkdir -p "${local_path}" >> "${LOG_FILE_06}" 2>&1
    
    if chown -R rocky:"${group}" "${local_path}" >> "${LOG_FILE_06}" 2>&1; then
        if [[ -n "${PERM_PROCESS_DIR}" ]]; then
            chmod -R "${PERM_PROCESS_DIR}" "${local_path}" >> "${LOG_FILE_06}" 2>&1
        fi
        ok "Mapped: ${subdir} -> Group: ${group}" "${LOG_FILE_06}"
    else
        err "Failed to update ownership for: ${local_path}" "${LOG_FILE_06}"
    fi
done

#==================================================
# Step 3. Data Centralization & NFS Linking
#==================================================
step "Step 3. NFS Centralization & Symlinking" "${LOG_FILE_06}"

#----------------------------------------
# Task 1. Admin Path Security
#----------------------------------------
task "Task 1. Securing Administrative Base Path" "${LOG_FILE_06}"
if chown root:"${ADMIN_GROUP}" "${ADMIN_DIR}" >> "${LOG_FILE_06}" 2>&1; then
    chmod "${PERM_VAR_ADMIN}" "${ADMIN_DIR}" >> "${LOG_FILE_06}" 2>&1
    ok "Administrative directory secured: ${ADMIN_DIR}" "${LOG_FILE_06}"
else
    err "Failed to secure ${ADMIN_DIR}" "${LOG_FILE_06}"
fi

#----------------------------------------
# Task 2. NFS Storage Verification
#----------------------------------------
task "Task 2. Verifying NFS Storage Target" "${LOG_FILE_06}"
mkdir -p "${NFS_TARGET}" >> "${LOG_FILE_06}" 2>&1
chown root:"${ADMIN_GROUP}" "${NFS_TARGET}" >> "${LOG_FILE_06}" 2>&1
chmod "${PERM_VAR_MYPDF}" "${NFS_TARGET}" >> "${LOG_FILE_06}" 2>&1
ok "NFS target configured at ${NFS_TARGET}" "${LOG_FILE_06}"

#----------------------------------------
# Task 3. System Path Mapping
#----------------------------------------
task "Task 3. Mapping System Path to NFS" "${LOG_FILE_06}"
if ensure_symlink "${VARLIB_LINK}" "${NFS_TARGET}" "${LOG_FILE_06}"; then
    ok "Redirection established: ${VARLIB_LINK} -> ${NFS_TARGET}" "${LOG_FILE_06}"
else
    err "Failed to link ${VARLIB_LINK}" "${LOG_FILE_06}"
fi

#==================================================
# Step 4. Application Deployment
#==================================================
step "Step 4. Binary Deployment & Initialization" "${LOG_FILE_06}"

#----------------------------------------
# Task 1. Binary Deployment
#----------------------------------------
task "Task 1. Deploying MyPDF Binary" "${LOG_FILE_06}"

if [[ ! -x "${MYPDF_BIN}" ]]; then
    mkdir -p "${MYPDF_ROOT}" >> "${LOG_FILE_06}" 2>&1
    cp -rL "${SETUP_DIR}/tool/mypdf/"* "${MYPDF_ROOT}/" >> "${LOG_FILE_06}" 2>&1
    ok "Binary deployed to ${MYPDF_ROOT}" "${LOG_FILE_06}"
else
    ok "MyPDF binary already verified." "${LOG_FILE_06}"
fi

#----------------------------------------
# Task 2. Configuration Initialization
#----------------------------------------
task "Task 2. Initializing Configuration" "${LOG_FILE_06}"

SRC_CONFIG="${SETUP_DIR}/tool/mypdf/config.json"
if [[ -f "${SRC_CONFIG}" ]]; then
    cp "${SRC_CONFIG}" "${CONFIG_PATH}" >> "${LOG_FILE_06}" 2>&1
    # Binary execution for initialization
    info "Encrypting configuration..." "${LOG_FILE_06}"
    if "${MYPDF_BIN}" --config "${CONFIG_PATH}" >> "${LOG_FILE_06}" 2>&1; then
        ok "Configuration successfully initialized and encrypted." "${LOG_FILE_06}"
    else
        err "Application initialization failed. Check ${LOG_FILE_06}." "${LOG_FILE_06}"
    fi
else
    fail "Source config template missing at ${SRC_CONFIG}" "${LOG_FILE_06}"
fi

#----------------------------------------
# Task 3. Security Hardening
#----------------------------------------
task "Task 3. Enforcing Security Policies" "${LOG_FILE_06}"

chown root:"${ADMIN_GROUP}" "${CONFIG_PATH}" >> "${LOG_FILE_06}" 2>&1
chmod "${PERM_CONFIG}" "${CONFIG_PATH}" >> "${LOG_FILE_06}" 2>&1
if command -v restorecon >/dev/null 2>&1; then
    restorecon -F "${CONFIG_PATH}" >> "${LOG_FILE_06}" 2>&1
fi
ok "Security hardening complete." "${LOG_FILE_06}"

#==================================================
# Step 5. Desktop & System Integration
#==================================================
step "Step 5. System and Desktop Integration" "${LOG_FILE_06}"

#----------------------------------------
# Task 1. Global Application Menu
#----------------------------------------
task "Task 1. Generating Global Desktop Entry" "${LOG_FILE_06}"

write_desktop_file "${DESKTOP_SYS}" "MyPDF" "PDF Viewer with Watermark" \
    "${MYPDF_BIN}" "${MYPDF_ICON}" "Office;Viewer;Education;" "false" "" "${LOG_FILE_06}"
chmod "${PERM_DESKTOP_SYS}" "${DESKTOP_SYS}" >> "${LOG_FILE_06}" 2>&1
ok "Global shortcut deployed." "${LOG_FILE_06}"

#----------------------------------------
# Task 2. User Skeleton Setup
#----------------------------------------
task "Task 2. Preparing Default User Icons" "${LOG_FILE_06}"

mkdir -p "${DESKTOP_SKEL_DIR}" >> "${LOG_FILE_06}" 2>&1
write_desktop_file "${DESKTOP_SKEL}" "MyPDF" "PDF Viewer with Watermark" \
    "${MYPDF_BIN}" "${MYPDF_ICON}" "Office;Viewer;Education;" "false" "" "${LOG_FILE_06}"
chmod "${PERM_DESKTOP_SKEL}" "${DESKTOP_SKEL}" >> "${LOG_FILE_06}" 2>&1
ok "Skeleton desktop icon initialized." "${LOG_FILE_06}"

#----------------------------------------
# Task 3. Login Initialization
#----------------------------------------
task "Task 3. Configuring Login Synchronization" "${LOG_FILE_06}"

write_desktop_init_file_bash "mypdf" "${LOG_FILE_06}"
write_desktop_init_file_tcsh "mypdf" "${LOG_FILE_06}"

ok "Login-time sync helper established." "${LOG_FILE_06}"

#----------------------------------------
# Task 4. Shared Binary Link
#----------------------------------------
task "Task 4. Creating Shared Binary Symlink" "${LOG_FILE_06}"

ensure_symlink "${BIN_ROOT}/mypdf" "${MYPDF_ROOT}/mypdf" "${LOG_FILE_06}"
ok "MyPDF added to global bin path." "${LOG_FILE_06}"

#==================================================
# Step 6. Execution Summary
#==================================================
step "Step 6. Check the Summary information" "${LOG_FILE_06}"

# Count process groups
MAPPED_GROUPS=${#PROCESS_GROUP_MAP[@]}

# Check the key path permission
check_perm() { stat -c "%a" "$1" 2>/dev/null || echo "N/A"; }
CUR_ADMIN_PERM=$(check_perm "${ADMIN_DIR}")
CUR_CONFIG_PERM=$(check_perm "${CONFIG_PATH}")

# Check the link to NFS
SYMLINK_STATUS=$([[ -L "${VARLIB_LINK}" ]] && echo "Linked -> $(readlink "${VARLIB_LINK}")" || echo "Broken/Missing")

# Check the config
CONFIG_STATUS=$([[ -f "${CONFIG_PATH}" ]] && echo "Initialized" || echo "Missing")

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  MyPDF Service Installation Complete: 06_install_mypdf.sh"
    echo -e "======================================================================"
    echo -e "  [Security & Group Infrastructure]"
    echo -e "    • Admin Group     : ${ADMIN_GROUP} (Owner of documentation)"
    echo -e "    • Process Groups  : ${MAPPED_GROUPS} groups mapped to Tech_Doc"
    echo -e "    • Config Security : ${CUR_CONFIG_PERM} (Target: ${PERM_CONFIG})"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Storage & Data Mapping]"
    echo -e "    • NFS Redirection : ${SYMLINK_STATUS}"
    echo -e "    • Tech_Doc Path   : ${TECH_DOC}"
    echo -e "    • Config State    : ${CONFIG_STATUS} (Encrypted via MyPDF-CLI)"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [System Integration]"
    echo -e "    • Global Bin      : $([[ -L "${BIN_ROOT}/mypdf" ]] && echo "OK" || echo "Failed")"
    echo -e "    • Desktop Icon    : ${DESKTOP_SYS}"
    echo -e "    • Skeleton Path   : ${DESKTOP_SKEL}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  log saved to: ${LOG_FILE_06}"
    echo -e "  Next Recommended: 07_install_uv.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_06}"

finish "06_install_mypdf.sh" "${LOG_FILE_06}"
exit 0
