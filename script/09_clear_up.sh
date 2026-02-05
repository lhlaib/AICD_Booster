#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:   Campus Linux Environment Automation (CLEA)
# File Name: 09_clear_up.sh
# Description: Clear up setup and log
# Organization: NYCU-IEE-SI2 Lab
#
# Author:    Lin-Hung Lai
# Editor:    Bang-Yuan Xiao
# Released:  2026.01.08
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

#==================================================
# Task 1. Remove Setup Materials
#==================================================
task "Task 1. Removing Setup Directory"
if [[ -d "${SETUP_DIR}" ]]; then
    info "Deleting setup directory: ${SETUP_DIR}"
    rm -rf "${SETUP_DIR}"
    ok "Setup materials cleared."
else 
    info "Setup directory already empty or not found. Skipping."
fi

#==================================================
# Task 2. Clear Deployment Logs
#==================================================
task "Task 2. Clearing Deployment Logs"
# Using ls to check if the directory is not empty
if [ "$(ls -A "${LOG_DIR}" 2>/dev/null)" ]; then
    info "Cleaning log directory: ${LOG_DIR}"
    
    # We remove contents but keep the directory for future runs
    rm -rf "${LOG_DIR}"/*
    
    ok "All logs have been cleared."
else 
    info "Log directory is already clean."
fi

#==================================================
# Task 3. Remove MyPDF in template/tool
#==================================================
task "Task 3. Remove old MyPDF" 

if [[ -d "${TEMPLATE_DIR}/tool/mypdf" ]]; then
    info "Found existing MyPDF directory at ${TEMPLATE_DIR}/tool/mypdf." 
    
    if rm -rf "${TEMPLATE_DIR}/tool/mypdf"; then
        ok "Successfully removed old MyPDF directory."
    else
        err "Failed to remove MyPDF directory. Please check permissions." 
    fi
else 
    note "No MyPDF directory found in template/tool. Skipping." 
fi

exit 0
