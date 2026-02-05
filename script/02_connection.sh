#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    02_connection.sh
# Description:  Connection and Authentication Setting (LDAP, SSH, XRDP)
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

# log file for this script
LOG_FILE_02="${LOG_DIR}/02_connection.log"
if [[ -f "${LOG_FILE_02}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_02}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_02}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_02}"

# header
header "02_connection.sh" "Connection and Authentication Setting (LDAP, SSH, XRDP)" "${LOG_FILE_02}"

#==================================================
# Step 1. LDAP (SSSD version)
#==================================================
step "Step 1. Configuring LDAP Authentication (SSSD)" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. Install Dependencies
#----------------------------------------
task "Task 1. Installing LDAP & Auth Packages" "${LOG_FILE_02}"
dnf_install "sssd"              "${LOG_FILE_02}"
dnf_install "sssd-ldap"         "${LOG_FILE_02}"
dnf_install "sssd-tools"        "${LOG_FILE_02}"
dnf_install "authselect"        "${LOG_FILE_02}"
dnf_install "oddjob-mkhomedir"  "${LOG_FILE_02}"

#----------------------------------------
# Task 2. Configuration File Deployment
#----------------------------------------
task "Task 2. Deploying SSSD Configuration" "${LOG_FILE_02}"

if [[ "${SSSD_UPDATE^^}" == Y* ]]; then
    SRC_SSSD="${SETUP_DIR}/basic/sssd.conf"
    if [[ -f "${SRC_SSSD}" ]]; then
        info "Start updating /etc/sssd/sssd.conf" "${LOG_FILE_02}"
        install -m 600 -o root -g root "${SRC_SSSD}" /etc/sssd/sssd.conf >> "${LOG_FILE_02}" 2>&1
        ok "SSSD configuration deployed to /etc/sssd/sssd.conf." "${LOG_FILE_02}"
    else
        warn "Source sssd.conf not found at ${SETUP_DIR}/basic/." "${LOG_FILE_02}"
    fi
else 
    info "SSSD_UPDATE is 'N'. Keeping existing configuration." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Service Activation
#----------------------------------------
task "Task 3. Managing SSSD and Oddjob Services" "${LOG_FILE_02}"

if [[ "${SSSD_ENABLE^^}" == Y* ]]; then
    info "Enforcing SSSD and Oddjob service state..." "${LOG_FILE_02}"
        
    systemctl enable oddjobd.service >> "${LOG_FILE_02}" 2>&1
    systemctl restart oddjobd.service >> "${LOG_FILE_02}" 2>&1

    systemctl enable sssd >> "${LOG_FILE_02}" 2>&1
    systemctl restart sssd >> "${LOG_FILE_02}" 2>&1

    # Final health check by restarting SSSD
    if systemctl is-active --quiet sssd && systemctl is-active --quiet oddjobd; then
        ok "SSSD and Oddjob services are active and synchronized." "${LOG_FILE_02}"
        info "SSSD Domains: $(sssdctl domain-list 2>/dev/null | xargs)" "${LOG_FILE_02}"
    else
        fail "SSSD or Oddjob failed to start. Check /var/log/sssd/ or journalctl." "${LOG_FILE_02}"
    fi
else
    info "SSSD_ENABLE is 'N'. Shutting down LDAP-related services..." "${LOG_FILE_02}"
    
    # Stop and disable SSSD
    systemctl stop sssd >> "${LOG_FILE_02}" 2>&1
    systemctl disable sssd >> "${LOG_FILE_02}" 2>&1
    
    # Stop and disable oddjobd (no longer needed without LDAP)
    systemctl stop oddjobd.service >> "${LOG_FILE_02}" 2>&1
    systemctl disable oddjobd.service >> "${LOG_FILE_02}" 2>&1
    
    ok "SSSD and Oddjob services have been successfully disabled." "${LOG_FILE_02}"
fi

#==================================================
# Step 2. Account Authentication
#==================================================
step "Step 2. Configuring Account Lockout Policy" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. Create a profile
#----------------------------------------
task "task 1. Authentication Profile Detection" "${LOG_FILE_02}"

CUSTOM_SSSD_AUTH_PATH="/etc/authselect/custom/custom_sssd-auth"
CUSTOM_MINI_AUTH_PATH="/etc/authselect/custom/custom_minimal-auth"

# Create Custom SSSD Profile if it doesn't exist
if [[ ! -d "${CUSTOM_SSSD_AUTH_PATH}" ]]; then
    info "Creating custom SSSD profile..." "${LOG_FILE_02}"
    authselect create-profile custom_sssd-auth -b sssd >> "${LOG_FILE_02}" 2>&1
else
    info "Custom SSSD profile already exists. Skipping creation." "${LOG_FILE_02}"
fi

# Create Custom Minimal Profile if it doesn't exist
if [[ ! -d "${CUSTOM_MINI_AUTH_PATH}" ]]; then
    info "Creating custom Minimal profile..." "${LOG_FILE_02}"
    authselect create-profile custom_minimal-auth -b minimal >> "${LOG_FILE_02}" 2>&1
else
    info "Custom Minimal profile already exists. Skipping creation." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 2. Configuration Deployment
#----------------------------------------
task "Task 2. Deploying PAM configuration" "${LOG_FILE_02}"

if [[ "${PAMD_UPDATE^^}" == Y* ]]; then
    info "Start updating /etc/authselect/custom/" "${LOG_FILE_02}"

    # Determine Source and Target based on PAMD_TYPE
    if [[ "${PAMD_TYPE^^}" == SSSD ]]; then
        SRC_SYS="${SETUP_DIR}/basic/sssd_system-auth"
        SRC_PWD="${SETUP_DIR}/basic/sssd_password-auth"
        TGT_PATH="${CUSTOM_SSSD_AUTH_PATH}"
    else
        SRC_SYS="${SETUP_DIR}/basic/minimal_system-auth"
        SRC_PWD="${SETUP_DIR}/basic/minimal_password-auth"
        TGT_PATH="${CUSTOM_MINI_AUTH_PATH}"
    fi

    # Deploy system-auth
    if [[ -f "${SRC_SYS}" ]]; then
        info "Deploying system-auth to ${TGT_PATH}..." "${LOG_FILE_02}"
        install -m 644 -o root -g root "${SRC_SYS}" "${TGT_PATH}/system-auth" >> "${LOG_FILE_02}" 2>&1
    else
        warn "Source system-auth template not found: ${SRC_SYS}" "${LOG_FILE_02}"
    fi

    # Deploy password-auth 
    if [[ -f "${SRC_PWD}" ]]; then
        info "Deploying password-auth to ${TGT_PATH}..." "${LOG_FILE_02}"
        install -m 644 -o root -g root "${SRC_PWD}" "${TGT_PATH}/password-auth" >> "${LOG_FILE_02}" 2>&1
    else
        warn "Source password-auth template not found: ${SRC_PWD}" "${LOG_FILE_02}"
    fi
    ok "PAM deployment for ${PAMD_TYPE} completed successfully." "${LOG_FILE_02}"
else
    info "PAMD_UPDATE is 'N'. Keeping existing templates." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Activating Authentication Profile
#----------------------------------------
task "Task 3. Activating Authentication Profile" "${LOG_FILE_02}"

# Determine the target profile path based on the chosen authentication type: SSSD or MINIMAL
if [[ "${PAMD_TYPE^^}" == SSSD ]]; then
    TARGET_PROFILE="custom/custom_sssd-auth"
    # SSSD requires mkhomedir to automate home directory creation for network users
    FEATURES="with-mkhomedir"
    info "SSSD type selected. Preparing profile: ${TARGET_PROFILE} with mkhomedir." "${LOG_FILE_02}"
else
    TARGET_PROFILE="custom/custom_minimal-auth"
    # Minimal mode uses local accounts; mkhomedir is redundant as useradd handles directories
    FEATURES=""
    info "Minimal type selected. Preparing profile: ${TARGET_PROFILE} (Local only)." "${LOG_FILE_02}"
fi

# Add Account Lockout (Faillock) feature if enabled in config
if [[ "${PAMD_ENABLE^^}" == Y* ]]; then
    FEATURES="${FEATURES} with-faillock"
    ok   "Account Lockout (Faillock) is ENABLED. Adding 'with-faillock' feature." "${LOG_FILE_02}"
else
    info "Account Lockout (Faillock) is DISABLED. Proceeding without faillock module." "${LOG_FILE_02}"
fi

# Execute the atomic profile activation
info "Executing: authselect select ${TARGET_PROFILE} ${FEATURES} --force" "${LOG_FILE_02}"

if authselect select ${TARGET_PROFILE} ${FEATURES} --force >> "${LOG_FILE_02}" 2>&1; then
    # Post-activation cleanup: Reset faillock tallies to ensure a clean baseline
    info "Resetting faillock records to prevent accidental lockouts during deployment..." "${LOG_FILE_02}"
    faillock --reset >> "${LOG_FILE_02}" 2>&1
    
    ok "Authentication profile '${TARGET_PROFILE}' activated successfully." "${LOG_FILE_02}"
    
    # Final Verification: Check if the current profile matches our target
    CURRENT=$(authselect current | grep "Profile ID" | awk '{print $3}')
    info "Current Active Profile: ${CURRENT}" "${LOG_FILE_02}"
else
    fail "Authselect failed to apply the profile. Review ${LOG_FILE_02} for PAM stack errors." "${LOG_FILE_02}"
fi

#==================================================
# Step 3. SSH Service Configuration
#==================================================
step "Step 3. Configuring SSH Server" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. Service Installation
#----------------------------------------
task "Task 1. Installing OpenSSH" "${LOG_FILE_02}"
dnf_install "openssh-server" "${LOG_FILE_02}"

#----------------------------------------
# Task 2. Configuration Deployment
#----------------------------------------
task "Task 2. Deploying SSH Configuration" "${LOG_FILE_02}"

if [[ "${SSH_UPDATE^^}" == Y* ]]; then
    SRC_SSHD="${SETUP_DIR}/basic/sshd_config"
    if [[ -f "${SRC_SSHD}" ]]; then
        info "Deploying custom sshd_config..." "${LOG_FILE_02}"
        install -m 600 -o root -g root "${SRC_SSHD}" /etc/ssh/sshd_config >> "${LOG_FILE_02}" 2>&1

        # Update SELinux Authentication Port list
        if [[ -n "${SSH_SPEC_PORT}" ]] && [[ "${SSH_SPEC_PORT}" != "22" ]]; then
            info "Ensuring SELinux allows SSH on port ${SSH_SPEC_PORT}..." "${LOG_FILE_02}"
            semanage port -a -t ssh_port_t -p tcp "${SSH_SPEC_PORT}" >> "${LOG_FILE_02}" 2>&1 || \
            semanage port -m -t ssh_port_t -p tcp "${SSH_SPEC_PORT}" >> "${LOG_FILE_02}" 2>&1
        fi
        ok "SSH configuration file deployed." "${LOG_FILE_02}"
    else
        warn "Source sshd_config not found. Keeping current config." "${LOG_FILE_02}"
    fi
else 
    info "SSH_UPDATE is 'N'. Keeping existing configuration." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Service Activation
#----------------------------------------
task "Task 3. Managing SSH Service Activation" "${LOG_FILE_02}"

if [[ "${SSH_ENABLE^^}" == Y* ]]; then
    if /usr/sbin/sshd -t >> "${LOG_FILE_02}" 2>&1; then
        systemctl restart sshd >> "${LOG_FILE_02}" 2>&1
        systemctl enable sshd >> "${LOG_FILE_02}" 2>&1
        
        if systemctl is-active --quiet sshd; then
            ok "SSH service is active and synchronized." "${LOG_FILE_02}"
            info "Active SSH Ports: $(ss -tunlp | grep sshd | awk '{print $5}' | cut -d':' -f2 | xargs)" "${LOG_FILE_02}"
        else
            err "SSH service failed to start. Check /var/log/secure." "${LOG_FILE_02}"
        fi
    else
        err "SSH syntax error! Service NOT restarted to prevent lockout." "${LOG_FILE_02}"
    fi
else
    warn "SSH_ENABLE is 'N'. Stopping service..." "${LOG_FILE_02}"
    systemctl stop sshd >> "${LOG_FILE_02}" 2>&1
    systemctl disable sshd >> "${LOG_FILE_02}" 2>&1
    ok "SSH service has been deactivated." "${LOG_FILE_02}"
fi

#==================================================
# Step 4. Public key for no password login (admin only)
#==================================================
step "Step 4. Deploying Admin Public Key" "${LOG_FILE_02}"

#----------------------------------------
# Task 1: Generate the public key
#----------------------------------------
task "Task 1. Generating the public key" "${LOG_FILE_02}"

# Define the SSH directory path correctly
# Avoiding '~' ensures it targets the correct user even when run as root
if [ "${ADMIN}" == "root" ]; then
    ADMIN_SSH_DIR="/root/.ssh"
else
    ADMIN_SSH_DIR="/home/${ADMIN}/.ssh"
fi

SSH_KEY_FILE="${ADMIN_SSH_DIR}/id_ed25519"

if [[ ${SSH_CREATE_KEY} == Y* ]]; then
    # Check if the key already exists
    if [[ -f "${SSH_KEY_FILE}" ]]; then
        if [[ ${SSH_OVERRIDE_KEY} == Y* ]]; then
            # Override mode: backup the current key and generate a new one
            warn "Override detected! Backing up existing SSH key for user: ${ADMIN}..." "${LOG_FILE_02}"
            
            timestamp=$(date +%Y%m%d_%H%M%S)
            mv "${SSH_KEY_FILE}" "${SSH_KEY_FILE}.bak_${timestamp}"
            mv "${SSH_KEY_FILE}.pub" "${SSH_KEY_FILE}.pub.bak_${timestamp}"
            
            info "Generating a brand new SSH key as requested..." "${LOG_FILE_02}"
            ssh-keygen -t ed25519 -f "${SSH_KEY_FILE}" -N "" -C "${ADMIN}@$(hostname)" > /dev/null 2>&1
            ok "New SSH key generated. Old key saved as backup." "${LOG_FILE_02}"
        else
            # Normal mode: prevent accidental overwrites
            info "SSH key already exists. Use 'SSH_OVERRIDE_KEY=Y' to force a new one." "${LOG_FILE_02}"
        fi
    else
        # New environment: Create directory and generate key
        info "No existing SSH key found for ${ADMIN}. Generating a new one..." "${LOG_FILE_02}"
        mkdir -p "${ADMIN_SSH_DIR}" && chmod 700 "${ADMIN_SSH_DIR}"
        
        if ssh-keygen -t ed25519 -f "${SSH_KEY_FILE}" -N "" -C "${ADMIN}@$(hostname)" > /dev/null 2>&1; then
            ok "Successfully generated the SSH public key." "${LOG_FILE_02}"
        else
            fail "Failed to generate SSH key. Check system permissions." "${LOG_FILE_02}"
        fi
    fi

    # CRITICAL: Transfer ownership back to the admin user
    # Since the script runs as root, keys are owned by root by default
    if [[ -d "${ADMIN_SSH_DIR}" ]]; then
        chown -R "${ADMIN}:${ADMIN}" "${ADMIN_SSH_DIR}"
        chmod 600 "${SSH_KEY_FILE}"
        chmod 644 "${SSH_KEY_FILE}.pub"
        info "Ownership and permissions for ${ADMIN_SSH_DIR} have been updated." "${LOG_FILE_02}"
    fi
else
    info "SSH_CREATE_KEY is 'N'. Skipping task." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 2: Public key in authorized_keys
#----------------------------------------
task "Task 2. Dealing with the specific public key" "${LOG_FILE_02}"
AUTH_KEYS_FILE="${ADMIN_SSH_DIR}/authorized_keys"

if [[ "${SSH_ENABLE_KEY^^}" == Y* ]]; then  
    # --- Mode: ENABLED ---
    # Ensure .ssh directory exists with correct permissions (700)
    install -d -m 700 -o "${ADMIN}" -g "${ADMIN}" "${ADMIN_SSH_DIR}"

    if [[ "${SSH_UPDATE_KEY^^}" == Y* ]]; then
        # Overwrite Mode: Only the new key will exist
        info "SSH_UPDATE_KEY is 'Y'. Overwriting authorized_keys..." "${LOG_FILE_02}"
        echo "${SSH_PUBLIC_KEY}" > "${AUTH_KEYS_FILE}"
        ok "Unique public key deployed (Overwrite mode)." "${LOG_FILE_02}"
    else
        # Append Mode: Keep existing keys, add new one if missing
        info "SSH_UPDATE_KEY is 'N'. Using Append Mode..." "${LOG_FILE_02}"
        [[ ! -f "${AUTH_KEYS_FILE}" ]] && touch "${AUTH_KEYS_FILE}"
        
        if ! grep -qxF "${SSH_PUBLIC_KEY}" "${AUTH_KEYS_FILE}"; then
            echo "${SSH_PUBLIC_KEY}" >> "${AUTH_KEYS_FILE}"
            ok "Public key appended to authorized_keys." "${LOG_FILE_02}"
        else
            info "Public key already exists for ${ADMIN}. Skipping append." "${LOG_FILE_02}"
        fi
    fi

    # Ensure correct file permissions (600) and ownership
    chmod 600 "${AUTH_KEYS_FILE}"
    chown "${ADMIN}:${ADMIN}" "${AUTH_KEYS_FILE}"
    
else 
    # --- Mode: DISABLED ---
    # Truly disable by removing the access file
    if [[ -f "${AUTH_KEYS_FILE}" ]]; then
        warn "SSH_ENABLE_KEY is 'N'. Removing authorized_keys to disable key-based login..." "${LOG_FILE_02}"
        rm -f "${AUTH_KEYS_FILE}" >> "${LOG_FILE_02}" 2>&1
        ok "authorized_keys removed. Key-based login for ${ADMIN} is now DISABLED." "${LOG_FILE_02}"
    else
        info "SSH_ENABLE_KEY is 'N'. Key-based login is already inactive." "${LOG_FILE_02}"
    fi
fi

#==================================================
# Step 5. Remote Desktop (XRDP + Xfce)
#==================================================
step "Step 5. Remote Desktop Environment" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. GUI Package Installation
#----------------------------------------
task "Task 1. Installing XRDP and Xfce" "${LOG_FILE_02}"
info "Installing Xfce Desktop environment (Check log for progress)..." "${LOG_FILE_02}"
dnf_install "xrdp" "${LOG_FILE_02}"
dnf_install "xorgxrdp" "${LOG_FILE_02}"
dnf_install "xrdp-selinux" "${LOG_FILE_02}"

if dnf -y groupinstall "Xfce" >> "${LOG_FILE_02}" 2>&1; then
    ok "Xfce Desktop environment installed." "${LOG_FILE_02}"
else
    warn "GUI installation reported issues. Check ${LOG_FILE_02}." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 2. XRDP Config Deployment
#----------------------------------------
task "Task 2. Deploying XRDP & Session Configs" "${LOG_FILE_02}"

# Deploy xrdp.ini
if [[ "${XRDP_UPDATE^^}" == Y* ]]; then
    SRC_XRDP_INI="${SETUP_DIR}/basic/xrdp.ini"
    if [[ -f "${SRC_XRDP_INI}" ]]; then
        install -m 644 -o root -g root "${SRC_XRDP_INI}" /etc/xrdp/xrdp.ini >> "${LOG_FILE_02}" 2>&1
        ok "xrdp.ini deployed successfully." "${LOG_FILE_02}"
    else
        warn "XRDP_UPDATE is Y, but source file not found: ${SRC_XRDP_INI}" "${LOG_FILE_02}"
    fi
else
    info "XRDP_UPDATE is N. Skipping xrdp.ini deployment." "${LOG_FILE_02}"
fi

# Deploy sesman.ini
if [[ "${SESMAN_UPDATE^^}" == Y* ]]; then
    SRC_SESMAN_INI="${SETUP_DIR}/basic/sesman.ini"
    if [[ -f "${SRC_SESMAN_INI}" ]]; then
        info "Updating sesman.ini..." "${LOG_FILE_02}"
        install -m 644 -o root -g root "${SRC_SESMAN_INI}" /etc/xrdp/sesman.ini >> "${LOG_FILE_02}" 2>&1
        ok "sesman.ini deployed successfully." "${LOG_FILE_02}"
    else
        warn "SESMAN_UPDATE is Y, but source file not found: ${SRC_SESMAN_INI}" "${LOG_FILE_02}"
    fi
else
    info "SESMAN_UPDATE is N. Skipping sesman.ini deployment." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Window Manager Setup
#----------------------------------------
task "Task 3. Configuring Xfce Session" "${LOG_FILE_02}"

# Ensure remote desktop via Xfce
cat >/etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
if command -v startxfce4 >/dev/null 2>&1; then
  exec startxfce4
fi
exec /bin/sh /etc/X11/Xsession
EOF
chmod 755 /etc/xrdp/startwm.sh >> "${LOG_FILE_02}" 2>&1

# Set Xfce as default for Xinit
if ! grep -q 'exec startxfce4' /etc/X11/xinit/Xclients 2>/dev/null; then
    mkdir -p /etc/X11/xinit/
    sed -i '1i exec startxfce4' /etc/X11/xinit/Xclients >> "${LOG_FILE_02}" 2>&1 || echo 'exec startxfce4' > /etc/X11/xinit/Xclients
fi
ok "Session manager set to Xfce." "${LOG_FILE_02}"

#--------------------------------------------------
# Task 4. Service Activation Control (RDP_ENABLE)
#--------------------------------------------------
task "Task 4. Managing XRDP Service Activation" "${LOG_FILE_02}"

if [[ "${RDP_ENABLE^^}" == Y* ]]; then
    info "Enabling and enforcing XRDP service state..." "${LOG_FILE_02}"
    
    if [[ -n "${XRDP_PORT}" ]]; then
        semanage port -a -t vnc_port_t -p tcp "${XRDP_PORT}" >> "${LOG_FILE_02}" 2>&1  || \
        semanage port -m -t vnc_port_t -p tcp "${XRDP_PORT}" >> "${LOG_FILE_02}" 2>&1
    else
        err "xrdp port is not defined!" "${LOG_FILE_02}"
    fi

    # Use restart instead of start to ensure any Task 2/3 changes are loaded
    # Enable service to start on boot and start it now
    systemctl restart xrdp >> "${LOG_FILE_02}" 2>&1
    systemctl enable xrdp >> "${LOG_FILE_02}" 2>&1
    
    # Use restart instead of start to ensure any Task 2/3 changes are loaded
    if systemctl is-active --quiet xrdp; then
        ok "XRDP service is active and running." "${LOG_FILE_02}"
        info "XRDP Status: $(ss -tunlp | grep xrdp | awk '{print $5}' | head -n 1)" "${LOG_FILE_02}"
    else
        err "XRDP failed to start. Check /var/log/xrdp.log or systemctl status xrdp." "${LOG_FILE_02}"
    fi
else
    warn "RDP_ENABLE is 'N'. Disabling XRDP service..." "${LOG_FILE_02}"
    systemctl stop xrdp >> "${LOG_FILE_02}" 2>&1
    systemctl disable xrdp >> "${LOG_FILE_02}" 2>&1
    ok "XRDP service has been stopped and disabled." "${LOG_FILE_02}"
fi

#==================================================
# Step 6. Security & Firewall
#==================================================
step "Step 6. Security & Firewall Settings" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. Service Installation
#----------------------------------------
task "Task 1. Installing Firewalld" "${LOG_FILE_02}"
dnf_install "firewalld" "${LOG_FILE_02}"
    
#----------------------------------------
# Task 2. Configuration Deployment (public.xml)
#----------------------------------------
task "Task 2. Deploying Firewall Configuration" "${LOG_FILE_02}"

if [[ "${FIREWALLD_UPDATE^^}" == Y* ]]; then
    SRC_FW="${SETUP_DIR}/basic/public.xml"
    if [[ -f "${SRC_FW}" ]]; then
        info "Update public.xml..." "${LOG_FILE_02}"
        install -m 640 -o root -g root "${SRC_FW}" /etc/firewalld/zones/public.xml >> "${LOG_FILE_02}" 2>&1
        ok "Custom firewall zone configuration deployed." "${LOG_FILE_02}"
    else
        warn "Source public.xml template not found. Using current system rules." "${LOG_FILE_02}"
    fi
else
    info "FIREWALLD_UPDATE is 'N'. Skipping configuration deployment." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Service Activation & Reload
#----------------------------------------
task "Task 3. Managing Firewalld Service Activation" "${LOG_FILE_02}"

if [[ "${FIREWALLD_ENABLE^^}" == Y* ]]; then
    info "Enabling and enforcing firewall state..." "${LOG_FILE_02}"

    # Force system to restart firewalld to fetch the latest settings
    systemctl restart firewalld >> "${LOG_FILE_02}" 2>&1
    systemctl enable firewalld >> "${LOG_FILE_02}" 2>&1
    
    if systemctl is-active --quiet firewalld; then
        ok "Firewalld is active and synchronized with public.xml." "${LOG_FILE_02}"
        info "Active Ports: $(firewall-cmd --list-ports)" "${LOG_FILE_02}"
    else
        err "Firewalld failed to start. Check XML syntax in /etc/firewalld/zones/public.xml." "${LOG_FILE_02}"
    fi
else
    warn "FIREWALLD_ENABLE is 'N'. Stopping and disabling service..." "${LOG_FILE_02}"
    systemctl stop firewalld >> "${LOG_FILE_02}" 2>&1
    systemctl disable firewalld >> "${LOG_FILE_02}" 2>&1
    ok "Firewall service has been deactivated." "${LOG_FILE_02}"
fi

#==================================================
# Step 7. IP Lockout Policy (Fail2ban)
#==================================================
step "Step 7. Configuring Fail2ban IP Protection" "${LOG_FILE_02}"

#----------------------------------------
# Task 1. Service Installation
#----------------------------------------
task "Task 1. Installing Fail2ban" "${LOG_FILE_02}"
dnf_install "fail2ban" "${LOG_FILE_02}"

#----------------------------------------
# Task 2. Configuration
#----------------------------------------
task "Task 2. Deploying Fail2ban Configurations" "${LOG_FILE_02}"

if [[ "${F2B_UPDATE^^}" == Y* ]]; then
    # Ensure the rendered jail.local template is used
    SRC_F2B="${SETUP_DIR}/basic/jail.local"
    
    if [[ -f "${SRC_F2B}" ]]; then
        info "Deploying custom jail.local..." "${LOG_FILE_02}"
        install -m 644 -o root -g root "${SRC_F2B}" /etc/fail2ban/jail.local >> "${LOG_FILE_02}" 2>&1
        ok "Main configuration (jail.local) deployed." "${LOG_FILE_02}"
    else
        warn "Source jail.local not found at ${SRC_F2B}. Using defaults." "${LOG_FILE_02}"
    fi
else 
    info "F2B_UPDATE is 'N'. Keeping existing jail configuration." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 3. Custom Filter Creation
#----------------------------------------
task "Task 3. Creating Custom XRDP Filter" "${LOG_FILE_02}"

if [[ "${F2B_ENABLE^^}" == Y* ]]; then
    # Since xrdp-sesman filters are not built-in, we generate it here
    info "Creating custom Fail2ban filter: xrdp-sesman" "${LOG_FILE_02}"
    
    # Use cat to ensure the filter file is always up-to-date
    cat > /etc/fail2ban/filter.d/xrdp-sesman.conf <<EOF
[Definition]
failregex = ^.*sshd:auth\]: (.*) failed for user (.*) from <HOST>.*$
            ^.*login failed for user (.*) on display (.*) from <HOST>.*$
ignoreregex =
EOF

    if [[ -f "/etc/fail2ban/filter.d/xrdp-sesman.conf" ]]; then
        ok "XRDP filter created at /etc/fail2ban/filter.d/xrdp-sesman.conf." "${LOG_FILE_02}"
    else
        err "Failed to create XRDP filter file." "${LOG_FILE_02}"
    fi
else
    info "F2B_ENABLE is 'N'. Skipping filter creation." "${LOG_FILE_02}"
fi

#----------------------------------------
# Task 4. Service Activation Control
#----------------------------------------
task "Task 4. Managing Fail2ban Service Activation" "${LOG_FILE_02}"

if [[ "${F2B_ENABLE^^}" == Y* ]]; then
    info "F2B_ENABLE is 'Y'. Enforcing Fail2ban service state..." "${LOG_FILE_02}"
    
    # Restart and enable to update the latest settings
    systemctl restart fail2ban >> "${LOG_FILE_02}" 2>&1
    systemctl enable fail2ban >> "${LOG_FILE_02}" 2>&1
    
    # Check whether the service is activated successfully
    if systemctl is-active --quiet fail2ban; then
        ok "Fail2ban service is active and protecting configured ports." "${LOG_FILE_02}"
        info "Active Jails: $(fail2ban-client status | grep 'Jail list' | cut -d':' -f2)" "${LOG_FILE_02}"
    else
        err "Fail2ban failed to start. Possible syntax error in jail.local." "${LOG_FILE_02}"
    fi
else
    warn "F2B_ENABLE is 'N'. Deactivating Fail2ban service..." "${LOG_FILE_02}"
    systemctl stop fail2ban >> "${LOG_FILE_02}" 2>&1
    systemctl disable fail2ban >> "${LOG_FILE_02}" 2>&1
    ok "Fail2ban service has been stopped and disabled." "${LOG_FILE_02}"
fi

#==================================================
# Step 8. Exection Summary
#==================================================
step "Step 8. Check the Summary information" "${LOG_FILE_02}"

# Authentication mode & related service
AUTH_MODE=$(authselect current | grep "Profile ID" | awk '{print $3}' || echo "Unknown")
[[ -z "${AUTH_MODE}" ]] && AUTH_MODE="None (System Default)"

# SSH & XRDP port
ACTIVE_SSH=$(ss -tunlp | grep sshd | awk '{print $5}' | cut -d':' -f2 | sort -u | xargs || echo "Disabled")
ACTIVE_RDP=$(ss -tunlp | grep xrdp | awk '{print $5}' | cut -d':' -f2 | sort -u | xargs || echo "Disabled")

# Fail2ban (Jails)
ACTIVE_JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d':' -f2 | sed 's/\t//g' || echo "None")

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  Connection & Auth Setup Complete: 02_connection.sh"
    echo -e "======================================================================"
    echo -e "  [Authentication & Profiles]"
    echo -e "    • Active Profile  : ${AUTH_MODE}"
    echo -e "    • LDAP (SSSD)     : $(systemctl is-active --quiet sssd && echo "Running" || echo "Inactive")"
    echo -e "    • Home Dir Auto   : $(authselect current | grep -q "with-mkhomedir" && echo "Enabled" || echo "Disabled")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Remote Access Services]"
    echo -e "    • SSH Service     : Port(s) [ ${ACTIVE_SSH} ]"
    echo -e "    • XRDP Service    : Port(s) [ ${ACTIVE_RDP} ]"
    echo -e "    • Admin SSH Key   : $([[ -f "${AUTH_KEYS_FILE}" ]] && echo "Deployed" || echo "Not Found")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Security & Protection]"
    echo -e "    • Firewall State  : $(systemctl is-active --quiet firewalld && echo "Active" || echo "Inactive")"
    echo -e "    • Fail2ban Jails  : ${ACTIVE_JAILS}"
    echo -e "    • Account Lockout : $(authselect current | grep -q "with-faillock" && echo "Enabled" || echo "Disabled")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  log saved to: ${LOG_FILE_02}"
    echo -e "  Next Recommended: 03_update_env.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_02}"

finish "02_connection.sh" "${LOG_FILE_02}"
exit 0
