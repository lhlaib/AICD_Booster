#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:   Campus Linux Environment Automation (CLEA)
# File Name: 00_create_setup.sh
# Description: Automatically create setup files based on config.sh
# Organization: NYCU-IEE-SI2 Lab
#
# Author:    Lin-Hung Lai
# Editor:    Bang-Yuan Xiao
# Released:  2026.01.26
# Platform:  Rocky Linux 8.x
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set -Eeuo pipefail

#==================================================
# Configuration & Functions
#==================================================
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../functions.sh"

must_root
enable_sudo_keep_alive # Sudo keep-alive

# log file for this script
LOG_FILE_00="${LOG_DIR}/00_create_setup.log"
if [[ -f "${LOG_FILE_00}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_00}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_00}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_00}"

# header
header "00_create_setup.sh" "Automatically create setup files from template" "${LOG_FILE_00}"

#==================================================
# Step 1. Preparation for MyPDF
#==================================================
step "Step 1. Preparation for MyPDF " "${LOG_FILE_00}"

# Deal with split MyPDF tar files
if [[ "${MYPDF_INSTALL^^}" == Y* ]]; then
    info "Feature Enabled: MYPDF_INSTALL is 'Y'. Dealing with the split MyPDF tar files" "${LOG_FILE_00}"
    
    # Check three split compressed files placed in the directory: rocky_package/template/tool/
    REQUIRED_PARTS=(
        "${TEMPLATE_DIR}/tool/mypdf.tar.xz.part_00"
        "${TEMPLATE_DIR}/tool/mypdf.tar.xz.part_01"
        "${TEMPLATE_DIR}/tool/mypdf.tar.xz.part_02"
    )

    MISSING_PARTS=0
    for part in "${REQUIRED_PARTS[@]}"; do
        if [[ ! -f "$part" ]]; then
            err "Missing required asset: $part" "${LOG_FILE_00}"
            MISSING_PARTS=$((MISSING_PARTS + 1))
        fi
    done

    if [[ $MISSING_PARTS -gt 0 ]]; then
        fail "Installation halted: $MISSING_PARTS missing parts detected. Please check your repository integrity." "${LOG_FILE_00}"
    fi

    # Merge the all split files to the complete compressed file and extract it
    task "Reassembling and Extracting MyPDF Assets" "${LOG_FILE_00}"
    if cat "${TEMPLATE_DIR}/tool"/mypdf.tar.xz.part_* > "${TEMPLATE_DIR}/tool/mypdf.tar.xz" 2>> "${LOG_FILE_00}"; then
        tar -xJf "${TEMPLATE_DIR}/tool/mypdf.tar.xz" -C "${TEMPLATE_DIR}/tool" >> "${LOG_FILE_00}" 2>&1
        ok "MyPDF files successfully extracted." "${LOG_FILE_00}"
    else
        fail "File reassembly failed." "${LOG_FILE_00}"
    fi
else 
    # Skip this step if you do not want to install MyPDF
    warn "Feature Disabled: MYPDF_INSTALL is set to 'N'." "${LOG_FILE_00}"
    note "Skipping MyPDF Watermark Service installation." "${LOG_FILE_00}"
fi

#==================================================
# Step 2. Generate setup from template 
#==================================================
step "Step 2. Start creating setup from template" "${LOG_FILE_00}"

#----------------------------------------
# Task 1. Remove the old setup
#----------------------------------------
task "Task 1. Removing the old setup"        "${LOG_FILE_00}"
if [[ -d ${SETUP_DIR} ]]; then
    rm -rf ${SETUP_DIR}
    ok "The existed directory: ${SETUP_DIR} has been removed!" "${LOG_FILE_00}"
else
    info "The directory: ${SETUP_DIR} does not exist" "${LOG_FILE_00}"
fi

#----------------------------------------
# Task 2. Create tool
#----------------------------------------
task "Task 2. Start creating setup/tool from template/tool"        "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/tool           ${SETUP_DIR}/tool           "${LOG_FILE_00}" 1

#----------------------------------------
# Task 3. basic
#----------------------------------------
task "Task 3. Start creating setup/basic from template/basic"       "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/basic       ${SETUP_DIR}/basic       "${LOG_FILE_00}" 0

#----------------------------------------
# Task 4. rsyslog.d
#----------------------------------------
task "Task 4. Start creating setup/rsyslog.d from template/rsyslog.d"   "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/rsyslog.d   ${SETUP_DIR}/rsyslog.d   "${LOG_FILE_00}" 0

#----------------------------------------
# Task 5. profile.d
#----------------------------------------
task "Task 5. Start creating setup/profile.d from template/profile.d"   "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/profile.d   ${SETUP_DIR}/profile.d   "${LOG_FILE_00}" 0

#----------------------------------------
# Task 6. sudoers.d
#----------------------------------------
task "Task 6. Start creating setup/sudoers.d from template/sudoers.d"   "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/sudoers.d   ${SETUP_DIR}/sudoers.d   "${LOG_FILE_00}" 0

#----------------------------------------
# Task 7. modulefiles
#----------------------------------------
task "Task 7. Start creating setup/modulefiles from template/modulefiles" "${LOG_FILE_00}"
create_setup ${TEMPLATE_DIR}/modulefiles ${SETUP_DIR}/modulefiles "${LOG_FILE_00}" 2

#==================================================
# Step 3. Execution Summary
#==================================================
step "Step 3. Check the Summary information" "${LOG_FILE_00}"

# Count actual results in the setup directory
TOTAL_DIRS=$(find "${SETUP_DIR}" -type d | wc -l)
TOTAL_FILES=$(find "${SETUP_DIR}" -type f | wc -l)
TOTAL_LINKS=$(find "${SETUP_DIR}" -type l | wc -l)

{
    echo -e "" 
    echo -e "======================================================================" 
    echo -e "✅  Setup Generation Summary"                                          
    echo -e "======================================================================" 
    echo -e "  [Source]      Template Dir : ${TEMPLATE_DIR}"                         
    echo -e "  [Target]      Setup Dir    : ${SETUP_DIR}"                            
    echo -e "----------------------------------------------------------------------"
    echo -e "  • Directories created      : ${TOTAL_DIRS}"                           
    echo -e "  • Templates rendered (File): ${TOTAL_FILES}"                          
    echo -e "  • Symbolic links mapped    : ${TOTAL_LINKS}"                          
    echo -e "----------------------------------------------------------------------" 
    echo -e "  Setup log saved to: ${LOG_FILE_00}"           
    echo -e "  You can now proceed with the service installation scripts."           
    echo -e "======================================================================" 
} | tee -a "${LOG_FILE_00}"

finish "00_create_setup.sh" "${LOG_FILE_00}"
exit 0
