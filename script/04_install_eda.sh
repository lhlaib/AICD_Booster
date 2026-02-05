#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    04_install_eda.sh
# Description:  Installation of EDA Tool Dependencies & Lmod Config
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
LOG_FILE_04="${LOG_DIR}/04_install_eda.log"
if [[ -f "${LOG_FILE_04}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_04}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_04}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_04}"

# header
header "04_install_eda.sh" "Installation of EDA Tool Dependencies & Lmod Config" "${LOG_FILE_04}"

#==================================================
# Step 1. Environment Modules (Lmod)
#==================================================
step "Step 1. Installing and Configuring Lmod" "${LOG_FILE_04}"

#----------------------------------------
# Task 1. Lmod Installation
#----------------------------------------
task "Task 1. Installing Lmod & Lua Dependencies" "${LOG_FILE_04}"
dnf_install "Lmod" "${LOG_FILE_04}"
dnf_install "lua-filesystem" "${LOG_FILE_04}"
dnf_install "lua-posix" "${LOG_FILE_04}"

#----------------------------------------
# Task 2. Modulefiles Deployment
#----------------------------------------
task "Task 2. Deploying EDA Modulefiles" "${LOG_FILE_04}"
if [[ "${MODULEFILE_UPDATE}" == Y* ]]; then
    if [[ -d "${SETUP_DIR}/modulefiles" ]]; then
        mkdir -p "${MODULE_ROOT}" >> "${LOG_FILE_04}" 2>&1
        sync_with_policy "${SETUP_DIR}/modulefiles" "${MODULE_ROOT}" "${MODULEFILE_OVERRIDE}" "D2755,F644" "${LOG_FILE_04}"
        chown -R root:root "${MODULE_ROOT}" >> "${LOG_FILE_04}" 2>&1
        ok "Modulefiles deployed to ${MODULE_ROOT}." "${LOG_FILE_04}"
    else
        warn "Source modulefiles directory not found." "${LOG_FILE_04}"
    fi
else 
    info "MODULEFILE_UPDATE is 'N'. Existing modulefiles preserved." "${LOG_FILE_04}"
fi

#----------------------------------------
# Task 3. Global MODULEPATH Configuration
#----------------------------------------
task "Task 3. Configuring Global MODULEPATH" "${LOG_FILE_04}"

# MODULEPATH definition for bash shell
SRC_BASH_PATH="${SETUP_DIR}/profile.d/zz-eda-modulepath.sh"
if [[ -f "${SRC_BASH_PATH}" ]]; then
    install -m 644 "${SRC_BASH_PATH}" "/etc/profile.d/zz-eda-modulepath.sh" >> "${LOG_FILE_04}" 2>&1
    chown root:root "/etc/profile.d/zz-eda-modulepath.sh" >> "${LOG_FILE_04}" 2>&1
    ok "Profile for bash module path deployed to /etc/profile.d/." "${LOG_FILE_04}"
else
    warn "Source bash script missing. Skipping." "${LOG_FILE_04}"
fi

# MODULEPATH definition for tcsh/csh shell
SRC_TCSH_PATH="${SETUP_DIR}/profile.d/zz-eda-modulepath.csh"
if [[ -f "${SRC_TCSH_PATH}" ]]; then
    install -m 644 "${SRC_TCSH_PATH}" "/etc/profile.d/zz-eda-modulepath.csh" >> "${LOG_FILE_04}" 2>&1
    chown root:root "/etc/profile.d/zz-eda-modulepath.csh" >> "${LOG_FILE_04}" 2>&1
    ok "Profile for tcsh module path deployed to /etc/profile.d/." "${LOG_FILE_04}"
else
    warn "Source tcsh script missing. Skipping." "${LOG_FILE_04}"
fi

#==================================================
# Step 2. EDA Tool Dependency Kits
#==================================================
step "Step 2. Installing EDA System Libraries" "${LOG_FILE_04}"

#----------------------------------------
# Task 1. CAD Root Setup
#----------------------------------------
task "Task 1. Configuring /usr/cad Linkage" "${LOG_FILE_04}"
mkdir -p "${CAD_ROOT}" >> "${LOG_FILE_04}" 2>&1
ensure_symlink "/usr/cad" "${CAD_ROOT}" "${LOG_FILE_04}"
ok "CAD root linked: /usr/cad -> ${CAD_ROOT}" "${LOG_FILE_04}"

#----------------------------------------
# Task 2. Core Libraries (32/64-bit)
#----------------------------------------
task "Task 2. Installing Core Libraries (32/64-bit)" "${LOG_FILE_04}"
info "Installing core system libraries (50+ packages)..." "${LOG_FILE_04}"

CORE_LIBS=(
    # common dependency
    glibc.i686 libstdc++.i686 libgcc.i686 
    libstdc++ libstdc++-devel glibc-devel
    libX11 libXext libXrender libXrandr libXcursor libXfixes libXi 
    libXft libXinerama libXScrnSaver libXtst libXmu 
    xorg-x11-server-Xvfb fontconfig xorg-x11-fonts-misc 
    xorg-x11-xauth xorg-x11-utils xorg-x11-xkb-utils 
    ksh apr apr-util
    libXt libXpm libXau libxcb openmotif openmotif-devel tcl tk 
    libnsl libnsl2 
    libpng libjpeg-turbo libtiff freetype
    perl perl-Data-Dumper redhat-lsb 
    xcb-util xcb-util-wm xcb-util-keysyms xcb-util-renderutil xcb-util-cursor 
    libdb libdb-utils

    # virtuoso
    compat-openssl10 mesa-libGLU mesa-libGL motif motif-devel libnsl
    
    # innovus
    xcb-util-image libxkbcommon libxkbcommon-x11 ncurses-compat-libs libXp

    # ML / Java (provide libjvm.so)
    armadillo yaml-cpp leveldb
    jsoncpp libevent zeromq zeromq-devel
    libsodium libsodium-devel java-1.8.0-openjdk-headless 
    
    # wv
    bc 
    
    # verdi
    libpng12 

    # vcs
    time
    
    # genus
    redhat-lsb-core 
    
    # star-rc
    lm_sensors-libs
)

for pkg in "${CORE_LIBS[@]}"; do
    dnf_install "${pkg}" "${LOG_FILE_04}"
done

# Development tools are best installed as a group
info "Installing Development Tools group..." "${LOG_FILE_04}"
dnf -y groupinstall "Development Tools" >> "${LOG_FILE_04}" 2>&1 || true
ok "Development Tools installed." "${LOG_FILE_04}"

#----------------------------------------
# Task 3. Tool-Specific Requirements
#----------------------------------------
task "Task 3. Deploying Specialized Tool Dependencies" "${LOG_FILE_04}"

info "Fetching legacy kits (Virtuoso, Innovus, DC)..." "${LOG_FILE_04}"

# Legacy DB support for virtuoso (handled only if missing)
if ! rpm -q compat-db47 > /dev/null 2>&1; then
    info "Installing legacy compat-db47 via COPR..." "${LOG_FILE_04}"
    wget -P /tmp https://download.copr.fedorainfracloud.org/results/vowstar/compat-db47/epel-8-x86_64/06584667-compat-db/compat-db47-4.7.25-28.el8.x86_64.rpm >> "${LOG_FILE_04}" 2>&1 || true
    wget -P /tmp https://download.copr.fedorainfracloud.org/results/vowstar/compat-db47/epel-8-x86_64/06584667-compat-db/compat-db-headers-4.7.25-28.el8.noarch.rpm >> "${LOG_FILE_04}" 2>&1 || true
    dnf -y install /tmp/compat-db-headers-*.rpm /tmp/compat-db47-*.rpm >> "${LOG_FILE_04}" 2>&1 || true
fi

# Version compatibility symlinks
ensure_symlink "/usr/lib64/libcrypto.so"       "/usr/lib64/libcrypto.so.1.1.1k" "${LOG_FILE_04}"
ensure_symlink "/usr/lib64/libssl.so"          "/usr/lib64/libssl.so.1.1.1k"    "${LOG_FILE_04}"
ensure_symlink "/usr/lib64/libcrypto.so.1.0.0" "/usr/lib64/libcrypto.so.10"     "${LOG_FILE_04}"
ensure_symlink "/usr/lib64/libssl.so.1.0.0"    "/usr/lib64/libssl.so.10"        "${LOG_FILE_04}"

# Synopsys Design Compiler krb5-libs downgrade
CURRENT_KRB5=$(rpm -q --qf '%{VERSION}-%{RELEASE}' krb5-libs)
TARGET_KRB5="1.18.2-30.el8_10"

if [[ "${CURRENT_KRB5}" != "${TARGET_KRB5}" ]]; then
    info "Downgrading krb5-libs to ${TARGET_KRB5} for DC compatibility..." "${LOG_FILE_04}"
    dnf -y downgrade krb5-libs-${TARGET_KRB5}.x86_64 >> "${LOG_FILE_04}" 2>&1 || true
    ok   "krb5-libs downgrades successfully!"
else
    info "krb5-libs is already at version ${TARGET_KRB5}." "${LOG_FILE_04}"
fi

#==================================================
# Step 3. Execution Summary
#==================================================
step "Step 3. Check the Summary information" "${LOG_FILE_04}"

# Modulefiles count
MODULE_COUNT=$(find "${MODULE_ROOT}" -type f -name "*.lua" 2>/dev/null | wc -l)

# Check the essential EDA library
MISSING_LIBS=0
check_lib() {
    if [[ ! -e "$1" ]]; then
        MISSING_LIBS=$((MISSING_LIBS + 1))
    fi
}

check_lib "/usr/lib64/libnsl.so.1"
check_lib "/usr/lib64/libpng12.so.0"
check_lib "/usr/lib64/libcrypto.so.10"
check_lib "/usr/lib/libstdc++.so.6" # 32-bit check

# Check krb5-libs version (Design Compiler)
KRB5_VER=$(rpm -q --qf '%{VERSION}-%{RELEASE}' krb5-libs 2>/dev/null || echo "Unknown")

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  EDA Environment Setup Complete: 04_install_eda.sh"
    echo -e "======================================================================"
    echo -e "  [Environment Modules (Lmod)]"
    echo -e "    • Module Root     : ${MODULE_ROOT}"
    echo -e "    • Files Deployed  : ${MODULE_COUNT} (.lua scripts)"
    echo -e "    • MODULEPATH      : /etc/profile.d/zz-eda-modulepath.sh & zz-eda-modulepath.csh"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Library & Dependency Check]"
    echo -e "    • CAD Root Link   : $([[ -L "/usr/cad" ]] && echo "OK (/usr/cad -> ${CAD_ROOT})" || echo "FAILED")"
    echo -e "    • Critical Libs   : $([[ ${MISSING_LIBS} -eq 0 ]] && echo "All Present" || echo "Warning: ${MISSING_LIBS} missing")"
    echo -e "    • 32-bit Support  : $(rpm -q glibc.i686 >/dev/null && echo "Installed" || echo "Missing")"
    echo -e "    • krb5-libs Ver   : ${KRB5_VER}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Specialized Tool Kits]"
    echo -e "    • compat-db47     : $(rpm -q compat-db47 >/dev/null && echo "Installed" || echo "Skipped")"
    echo -e "    • OpenSSL 1.0     : $(rpm -q compat-openssl10 >/dev/null && echo "Installed" || echo "Skipped")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  log saved to: ${LOG_FILE_04}"
    echo -e "  Next Recommended: 05_install_vscode.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_04}"

finish "04_install_eda.sh" "${LOG_FILE_04}"
exit 0
