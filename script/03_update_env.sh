#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    03_update_env.sh
# Description:  System Environment Update (Chrony, /etc, logging, profile.d)
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

# Log file initialization
LOG_FILE_03="${LOG_DIR}/03_update_env.log"
if [[ -f "${LOG_FILE_03}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_03}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_03}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_03}"

# header
header "03_update_env.sh" "System Environment Update (Chrony, /etc, logging, profile.d)" "${LOG_FILE_03}"

#==================================================
# Step 1. Time Synchronization (Chrony)
#==================================================
step "Step 1. Configuring Time Synchronization (Chrony)" "${LOG_FILE_03}"

#----------------------------------------
# Task 1. Installation
#----------------------------------------
task "Task 1. Installing Chrony" "${LOG_FILE_03}"
dnf_install "chrony" "${LOG_FILE_03}"

#----------------------------------------
# Task 2. Configuration Deployment
#----------------------------------------
task "Task 2. Deploying Chrony Configuration" "${LOG_FILE_03}"
if [[ "${CHRONY_UPDATE}" == Y* ]]; then
    SRC_CHRONY="${SETUP_DIR}/basic/chrony.conf"
    if [[ -f "${SRC_CHRONY}" ]]; then
        install -m 644 -o root -g root "${SRC_CHRONY}" /etc/chrony.conf >> "${LOG_FILE_03}" 2>&1
        ok "Custom chrony.conf deployed." "${LOG_FILE_03}"
    else
        warn "Source chrony.conf not found. Using system default." "${LOG_FILE_03}"
    fi
else
    info "CHRONY_UPDATE is 'N'. Skipping deployment." "${LOG_FILE_03}"
fi

#----------------------------------------
# Task 3. Service Activation
#----------------------------------------
task "Task 3. Managing Chrony Service Activation" "${LOG_FILE_03}"

if [[ "${CHRONY_ENABLE^^}" == Y* ]]; then
    info "Enforcing Chrony service state and time synchronization..." "${LOG_FILE_03}"
    
    systemctl enable chronyd >> "${LOG_FILE_03}" 2>&1
    systemctl restart chronyd >> "${LOG_FILE_03}" 2>&1
    
    if systemctl is-active --quiet chronyd; then
        timeout 5 chronyc -a makestep >> "${LOG_FILE_03}" 2>&1 || warn "Immediate sync timed out. Check physical firewall UDP 123." "${LOG_FILE_03}"
        
        # Check reachability
        REACH=$(chronyc sources | grep '^\^' | awk '{sum+=$4} END {print sum}')
        if [[ "$REACH" -eq 0 ]]; then
            warn "Chrony is RUNNING but all sources are UNREACHABLE (Reach=0)." "${LOG_FILE_03}"
            warn "Please open UDP Port 123 on your physical firewall." "${LOG_FILE_03}"
        else
            ok "Chrony service is active and communicating with NTP sources." "${LOG_FILE_03}"
        fi
    else
        err "Chrony failed to start. System time may drift!" "${LOG_FILE_03}"
    fi
else
    warn "CHRONY_ENABLE is 'N'. Disabling time synchronization..." "${LOG_FILE_03}"
    systemctl stop chronyd >> "${LOG_FILE_03}" 2>&1
    systemctl disable chronyd >> "${LOG_FILE_03}" 2>&1
    ok "Chrony service has been deactivated." "${LOG_FILE_03}"
fi

#==================================================
# Step 2. System-wide Configurations (/etc)
#==================================================
step "Step 2. Deploying Global Configuration Files" "${LOG_FILE_03}"

if [[ "${ETC_UPDATE^^}" == Y* ]]; then
    task "Task 1. Updating core configuration files" "${LOG_FILE_03}"
    for rcfile in bashrc profile inputrc motd; do
        SRC_RC="${SETUP_DIR}/basic/${rcfile}"
        if [[ -f "${SRC_RC}" ]]; then
            if install -m 644 -o root -g root "${SRC_RC}" "/etc/${rcfile}" >> "${LOG_FILE_03}" 2>&1; then
                ok "Applied custom ${rcfile} to /etc/${rcfile}." "${LOG_FILE_03}"
            else
                err "Failed to apply ${rcfile}." "${LOG_FILE_03}"
            fi
        else
            warn "Source file ${rcfile} missing. Skipping." "${LOG_FILE_03}"
        fi
    done
else
    info "ETC_UPDATE is 'N'. System-wide files preserved." "${LOG_FILE_03}"
fi

#==================================================
# Step 3. System Logging (rsyslog.d)
#==================================================
step "Step 3. Configuring Rsyslog Service" "${LOG_FILE_03}"

#----------------------------------------
# Task 1. Service Installation
#----------------------------------------
task "Task 1. Installing Rsyslog" "${LOG_FILE_03}"
dnf_install "rsyslog" "${LOG_FILE_03}"

#----------------------------------------
# Task 2. Configuration Syncing
#----------------------------------------
task "Task 2. Synchronizing Configurations" "${LOG_FILE_03}"

if [[ "${RSYSLOGD_UPDATE}" == Y* ]]; then
    SRC_RSYSLOG="${SETUP_DIR}/rsyslog.d"
    if [[ -d "${SRC_RSYSLOG}" ]]; then
        info "Synchronizing rsyslog.d custom configurations..." "${LOG_FILE_03}"
        sync_with_policy "${SRC_RSYSLOG}" "/etc/rsyslog.d" "${RSYSLOGD_OVERRIDE}" "D755,F644" "${LOG_FILE_03}"
        chown -R root:root /etc/rsyslog.d/* >> "${LOG_FILE_03}" 2>&1
        ok "Rsyslog configurations deployed to /etc/rsyslog.d/." "${LOG_FILE_03}"
    else
        warn "Source directory ${SRC_RSYSLOG} not found." "${LOG_FILE_03}"
    fi
else 
    info "RSYSLOGD_UPDATE is 'N'. Keeping existing configuration." "${LOG_FILE_03}"
fi

#----------------------------------------
# Task 3. Service Activation & Enforcement
#----------------------------------------
task "Task 3. Managing Rsyslog Service Activation" "${LOG_FILE_03}"

if [[ "${RSYSLOGD_ENABLE^^}" == Y* ]]; then
    info "Enforcing Rsyslog service state..." "${LOG_FILE_03}"
    
    systemctl enable rsyslog >> "${LOG_FILE_03}" 2>&1
    systemctl restart rsyslog >> "${LOG_FILE_03}" 2>&1
    
    if systemctl is-active --quiet rsyslog; then
        ok "Rsyslog service is active and recording logs." "${LOG_FILE_03}"
    else
        err "Rsyslog failed to start. Check 'journalctl -u rsyslog' for syntax errors." "${LOG_FILE_03}"
    fi
else
    warn "RSYSLOGD_ENABLE is 'N'. Stopping logging service..." "${LOG_FILE_03}"
    systemctl stop rsyslog >> "${LOG_FILE_03}" 2>&1
    systemctl disable rsyslog >> "${LOG_FILE_03}" 2>&1
    ok "Rsyslog service has been deactivated." "${LOG_FILE_02}"
fi

#==================================================
# Step 4. Global Environment Scripts (profile.d)
#==================================================
step "Step 4. Synchronizing Profile Scripts" "${LOG_FILE_03}"

if [[ "${PROFILED_UPDATE}" == "Y" ]]; then
    task "Task 1. Deploying scripts to profile.d" "${LOG_FILE_03}"
    if [[ -d "${SETUP_DIR}/profile.d" ]]; then
        sync_with_policy "${SETUP_DIR}/profile.d" "/etc/profile.d" "${PROFILED_OVERRIDE}" "D755,F644" "${LOG_FILE_03}"
        chown -R root:root /etc/profile.d/* >> "${LOG_FILE_03}" 2>&1
        ok "Profile scripts synchronized (Policy: ${PROFILED_OVERRIDE})." "${LOG_FILE_03}"
    else
        warn "Source profile.d missing." "${LOG_FILE_03}"
    fi
else
    info "PROFILED_UPDATE is 'N'. profile.d preserved." "${LOG_FILE_03}"
fi

#==================================================
# Step 5. Sudoers Configuration (sudoers.d)
#==================================================
step "Step 5: Synchronizing Sudoers Privileges" "${LOG_FILE_03}"

if [[ "${SUDOERSD_UPDATE}" == "Y" ]]; then
    if [[ -d "${SETUP_DIR}/sudoers.d" ]]; then
        task "Task 1. Deploying scripts to sudoers.d" "${LOG_FILE_03}"
        sync_with_policy "${SETUP_DIR}/sudoers.d" "/etc/sudoers.d" "${SUDOERSD_OVERRIDE}" "D750,F440" "${LOG_FILE_03}"
        chown -R root:root /etc/sudoers.d/* >> "${LOG_FILE_03}" 2>&1

        # CRITICAL: Validate sudoers syntax
        if visudo -cf /etc/sudoers >> "${LOG_FILE_03}" 2>&1; then
            ok "Sudoers rules synchronized and validated." "${LOG_FILE_03}"
        else
            err "Sudoers syntax error detected! Check /etc/sudoers.d contents immediately." "${LOG_FILE_03}"
        fi
    else
        warn "Source sudoers.d missing." "${LOG_FILE_03}"
    fi
else
    info "SUDOERSD_UPDATE is 'N'. Sudoers preserved." "${LOG_FILE_03}"
fi

#==================================================
# Step 6. Network Hosts File (/etc/hosts)
#==================================================
step "Step 6. Updating Network Hosts" "${LOG_FILE_03}"

if [[ "${HOSTS_UPDATE}" == "Y" ]]; then
    task "Task 1. Deploying and cleaning custom /etc/hosts" "${LOG_FILE_03}"
    SRC_HOSTS="${SETUP_DIR}/basic/hosts"
    
    if [[ -f "${SRC_HOSTS}" ]]; then
        # Create a temporary clean version without Windows CR characters (^M)
        # tr -d '\r' removes the Carriage Return, leaving only Line Feed (\n)
        if tr -d '\r' < "${SRC_HOSTS}" > /tmp/hosts.tmp 2>> "${LOG_FILE_03}"; then
            # Install the cleaned file to /etc/hosts
            if install -m 644 -o root -g root /tmp/hosts.tmp /etc/hosts >> "${LOG_FILE_03}" 2>&1; then
                rm -f /tmp/hosts.tmp
                ok "Network hosts file updated and Windows line endings (^M) removed." "${LOG_FILE_03}"
            else
                err "Failed to install cleaned hosts file to /etc/hosts." "${LOG_FILE_03}"
            fi
        else
            err "Failed to clean source hosts file at ${SRC_HOSTS}." "${LOG_FILE_03}"
        fi
    else 
        warn "Source hosts file missing at ${SRC_HOSTS}." "${LOG_FILE_03}"
    fi 
else
    info "HOSTS_UPDATE is 'N'. Keeping current hosts file." "${LOG_FILE_03}"
fi

#==================================================
# Step 7. Execution Summary
#==================================================
step "Step 7. Check the Summary information" "${LOG_FILE_03}"

# 1. Detect Chrony status
if systemctl is-active --quiet chronyd; then
    CHRONY_STATUS="Active / $(chronyc tracking | grep 'Stratum' | awk '{print "Stratum "$3}')"
else
    CHRONY_STATUS="Inactive"
fi

# Count the synchronized files
PROFILED_COUNT=$(ls -1 ${SETUP_DIR}/profile.d/*.sh 2>/dev/null | wc -l)
SUDOERS_COUNT=$(ls -1 ${SETUP_DIR}/sudoers.d/ 2>/dev/null | grep -v "README" | wc -l)

# Time shift
TIME_OFFSET=$(chronyc tracking | grep "Last offset" | awk '{print $4 " " $5}')

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  Environment Update Complete: 03_update_env.sh"
    echo -e "======================================================================"
    echo -e "  [Time Synchronization]"
    echo -e "    • Chrony Status   : ${CHRONY_STATUS}"
    echo -e "    • Time Offset     : ${TIME_OFFSET:-N/A}"
    echo -e "    • Current Time    : $(date)"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Global Configuration (/etc)]"
    echo -e "    • profile.d       : ${PROFILED_COUNT} scripts deployed (.sh & .csh)"
    echo -e "    • sudoers.d       : ${SUDOERS_COUNT} rules active"
    echo -e "    • hosts file      : $([[ "${HOSTS_UPDATE}" == "Y" ]] && echo "Updated (CRLF Cleaned)" || echo "Preserved")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Logging System]"
    echo -e "    • Rsyslog State   : $(systemctl is-active --quiet rsyslog && echo "Running" || echo "Inactive")"
    echo -e "    • rsyslog.d Sync  : $([[ "${RSYSLOGD_UPDATE}" == "Y" ]] && echo "Successful" || echo "Skipped")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  log saved to: ${LOG_FILE_03}"
    echo -e "  Next Recommended: 04_install_eda.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_03}"

finish "03_update_env.sh" "${LOG_FILE_03}"
exit 0
