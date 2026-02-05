#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project: Campus Linux Environment Automation (CLEA)
# File Name: config.sh
# Description: Installation settings
# Organization: NYCU-IEE-SI2 Lab
#
# Author:    Lin-Hung Lai
# Editor:    Bang-Yuan Xiao
# Released:  2026.01.26
# Platform:  Rocky Linux 8.x
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set -Eeuo pipefail

#==================================================
# Script-related parameters (Do not modified)
#==================================================
export PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEMPLATE_DIR="${PKG_ROOT}/template"
export SCRIPT_DIR="${PKG_ROOT}/script"
export SETUP_DIR="${PKG_ROOT}/setup"
export LOG_DIR="${PKG_ROOT}/log"

#==================================================
# Global parameters
#==================================================
export ADMIN="rocky"
export DEPLOY_ROOT="/RAID2"
export CAD_ROOT="${DEPLOY_ROOT}/cad"
export BIN_ROOT="${DEPLOY_ROOT}/bin"
export MODULE_ROOT="${DEPLOY_ROOT}/modulefiles"
export TOOL_ROOT="${DEPLOY_ROOT}/tool"
export DOC_ROOT="${DEPLOY_ROOT}/WaterProof_PDF"
export COURSE_ROOT="${DEPLOY_ROOT}/COURSE"
export MANAGER_ROOT="${DEPLOY_ROOT}/MANAGER"

#==================================================
# Parameters used in 01_initial.sh
#==================================================
# Step 1. OS Maintenance & Repositories
export TIMEZONE="Asia/Taipei"

# Step 2. Storage & Networking (NFS)
export NFS_MOUNT="Y"
export NFS_SERVER="10.32.1.200"
export NFS_REMOTE="/"

export FTP_MOUNT="Y"
export FTP_SERVER="your_ftp_server.edu.tw"
export FTP_REMOTE="/your_ftp_server_folder/ADFP"
export FTP_LOCAL="/your_mount_point_at_this_server"

# Step 3: Lab Administrative Tools Installation
export BYE_INSTALL="Y"
export FORCE_LOGOUT_INSTALL="Y"
export TASK_MANAGER_INSTALL="Y"

#==================================================
# Parameters used in 02_connection.sh
#==================================================
# Step 1. LDAP (SSSD version): sssd.conf
export SSSD_ENABLE="Y"
export SSSD_UPDATE="Y"
export SSSD_LDAP_URI="ldap://your_ldap_server.edu.tw"
export SSSD_LDAP_BASE="dc=your_ldap_server,dc=edu,dc=tw"
export SSSD_BIND_DN="uid=root,cn=users,dc=your_ldap_server,dc=edu,dc=tw"
export SSSD_BIND_PW="your_ldap_password"

# Step 2. Account Authentication
export PAMD_TYPE="SSSD"
export PAMD_ENABLE="Y"
export PAMD_UPDATE="Y"
export PAMD_DENY_COUNT=10
export PAMD_LOCK_TIME=900

# Step 3. SSH Service Configuration
export SSH_ENABLE="Y"
export SSH_UPDATE="Y"
export SSH_SPEC_PORT="22"

# Step 4. Public key for no password login (admin only)
export SSH_CREATE_KEY="N"
export SSH_OVERRIDE_KEY="N"

export SSH_ENABLE_KEY="N"
export SSH_UPDATE_KEY="Y"
export SSH_PUBLIC_KEY=""

# Step 5. Remote Desktop (XRDP + Xfce): xrdp.ini & sesman.ini
export RDP_ENABLE="Y"
export XRDP_UPDATE="Y"
export XRDP_PORT="3389"
export XRDP_LS_TITLE="NYCU ADFP Cloud 3.0 Remote Access"
export SESMAN_UPDATE="Y"
export SESMAN_ALLOW_ROOT="false"
export SESMAN_MAX_RETRY="3"
export SESMAN_USER_GROUP=""
export SESMAN_GROUP_CHECK="false"
export SESMAN_KILL_DISCONN="0"
export SESMAN_DISCONN_LIMIT="30"  
export SESMAN_IDLE_LIMIT="900"  

# Step 6. Security & Firewall
export FIREWALLD_ENABLE="Y"
export FIREWALLD_UPDATE="Y"
export FIREWALLD_WHITE_IP_LIST="140.113.0.0/16 10.212.0.0/16"

# Step 7. IP Lockout Policy (Fail2ban)
export F2B_ENABLE="Y"
export F2B_UPDATE="Y"
export F2B_MAX_RETRY=10
export F2B_BAN_TIME=3600
export F2B_WHITE_IP_LIST="140.113.0.0/16 10.212.0.0/16"

#==================================================
# Parameters used in 03_update_env.sh
#==================================================
# Step 1. Time Synchronization: chrony.conf
export CHRONY_ENABLE="Y"
export CHRONY_UPDATE="Y"
export CHRONY_SERVER="your_ntp_server.edu.tw"

# Step 2. System-wide Configurations (/etc)
export ETC_UPDATE="Y"

# Step 3. System Logging (/etc/rsyslog.d)
export RSYSLOGD_ENABLE="Y"
export RSYSLOGD_UPDATE="Y"
export RSYSLOGD_OVERRIDE="Y"
export RSYSLOGD_SERVER="your_rsyslog_server.edu.tw"
export RSYSLOGD_PORT="514"

# Step 4. Global Environment Scripts (/etc/profile.d)
export PROFILED_UPDATE="Y"
export PROFILED_OVERRIDE="Y"
export MAIN_MANAGER="Bang-Yuan Xiao"
export MAIN_MANAGER_EMAIL="xuan95732@gmail.com"
export WEBSITE_URL="https://iclab.iee.nycu.edu.tw"

# Step 5. Sudoers Configuration (/etc/sudoers.d)
export SUDOERSD_UPDATE="Y"
export SUDOERSD_OVERRIDE="Y"
export SUDOERSD_GROUP_LIST=(
    "%Manager  ALL=(ALL) NOPASSWD:ALL"
)
export SUDOERSD_USER_LIST=(
    "user1 ALL=(ALL) NOPASSWD:ALL"
    "user2 ALL=(ALL) NOPASSWD:ALL"
)

# Step 6. Network Hosts File (/etc/hosts)
export HOSTS_UPDATE="Y"
export HOSTS_LIST=(
  
)

#==================================================
# Parameters used in 04_install_eda.sh
#==================================================
# Step 1. Environment Modules (Lmod)
export MODULEFILE_UPDATE="Y"
export MODULEFILE_OVERRIDE="Y"

#==================================================
# Parameters used in 05_install_vscode.sh
#==================================================
# Step 0. Pre-installation Check
export VSCODE_INSTALL="Y"

# Step 2. VS Code Extensions and Environment Setup
export VSCODE_EXT_DEFAULT="Y"
export VSCODE_EXT_LIST=(
    "ms-python.python"
    "ms-python.vscode-pylance"
)

#==================================================
# Parameters used in 06_install_mypdf.sh
#==================================================
# Step 0. Pre-installation Check
export MYPDF_INSTALL="Y"

# Step 2. Directory and Permission Setup
declare -A PROCESS_GROUP_MAP=(
  ["ADFP_PDF"]="Process-ADFP"
  ["TN16_PDF"]="Process-N16"
  ["TN7_PDF"]="Process-N7"
  ["U18_PDF"]="Process-U18"
)
export DOC_CASE="DOC_2025_1109_PCKI_2330_ic34"
export PERM_PROCESS_DIR="770" 

# Step 4. Application Deployment
export MYPDF_LICENSE="L1-eyJraW5kIjoiZmlsZSIsInByb2R1Y3QiOiJQREZXTVBSTyIsIm1hY2hpbmUiOiIqIiwiaXNzdWVkIjoxNzYzMDExNDMyLCJleHAiOjE3OTQ1NDc0MzIsInBlcnBldHVhbCI6ZmFsc2UsIm1heF91c2VycyI6bnVsbH0"

#==================================================
# Parameters used in 07_install_uv.sh
#==================================================
# Step 0. Pre-installation Check
export UV_INSTALL="Y"
export UV_PERI_GROUP="ADFP-V3"

# Step 4. Pre-seed Python Versions and Wheels
export ENABLE_HEAVY="N"
