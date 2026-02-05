#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:   Campus Linux Environment Automation (CLEA)
# File Name: rocky_runset.sh
# Description: Main scripts for Installation
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
# source global variables & paths defined in config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# source global functions defined in functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/functions.sh"

# User requires sudo permissions
must_root
enable_sudo_keep_alive # Sudo keep-alive

#==================================================
# Step 0. Create setup from template
#==================================================
sudo bash "${SCRIPT_DIR}/00_create_setup.sh" 

#==================================================
# Step 1. System (NFS & Common Tool)
#==================================================
sudo bash "${SCRIPT_DIR}/01_initial.sh"  

#==================================================
# Step 2. Connection (Authentication & Remote Desktop)
#==================================================
sudo bash "${SCRIPT_DIR}/02_connection.sh"

#==================================================
# Step 3. Update Environment
#==================================================
sudo bash "${SCRIPT_DIR}/03_update_env.sh"

#==================================================
# Step 4. EDA Tool
#==================================================
sudo bash "${SCRIPT_DIR}/04_install_eda.sh"

#==================================================
# Step 5. Visual Studio Code (Optional)
#==================================================
sudo bash "${SCRIPT_DIR}/05_install_vscode.sh"

#==================================================
# Step 6. mypdf (Optional)
#==================================================
sudo bash "${SCRIPT_DIR}/06_install_mypdf.sh"

#==================================================
# Step 7. UV
#==================================================
sudo bash "${SCRIPT_DIR}/07_install_uv.sh"

exit 0
