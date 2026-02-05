#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    05_install_vscode.sh
# Description:  Visual Studio Code Installer with Shared Extensions
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

# Local parameters
VSCODE_ROOT="${TOOL_ROOT}/vscode"
EXT_DIR="${VSCODE_ROOT}/extensions"
DEFAULTS_DIR="${VSCODE_ROOT}/defaults"
CLI_USERDATA="${VSCODE_ROOT}/userdata-cli"
CACHE="${VSCODE_ROOT}/cache"        

CODE_LAB_BIN="${VSCODE_ROOT}/bin/code-lab"
EXT_LIST_FILE="${SETUP_DIR}/tool/vscode/extensions.txt"
DESKTOP_SYS="/usr/share/applications/code-lab.desktop"
DESKTOP_SKEL="/etc/skel/Desktop/code-lab.desktop"

VSCODE_MOD_DIR="${MODULE_ROOT}/other/vscode"
VSCODE_MOD_VER="$(date +%Y.%m.%d)"

# Default extensions list
DEFAULT_EXT_IDS=(
  ebicochineal.select-highlight-cochineal-color
  ms-python.python
  ms-python.vscode-pylance
  mshr-h.VerilogHDL
  foxundermoon.shell-format
  timonwong.shellcheck
  ms-vscode.cpptools
  twxs.cmake
  ms-vscode.makefile-tools
  ms-vscode.hexeditor
  yzhang.markdown-all-in-one
  bierner.markdown-mermaid
  naumovs.color-highlight
  editorconfig.editorconfig
  redhat.vscode-yaml
  tamasfe.even-better-toml
  formulahendry.code-runner
  christian-kohler.path-intellisense
)

# Log file initialization
LOG_FILE_05="${LOG_DIR}/05_install_vscode.log"
if [[ -f "${LOG_FILE_05}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_05}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_05}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_05}"

# header
header "05_install_vscode.sh" "Visual Studio Code Installer with Shared Extensions" "${LOG_FILE_05}"

#==================================================
# Step 0. Pre-installation Check
#==================================================
step "Step 0. Pre-installation Check" "${LOG_FILE_05}"

if [[ "${VSCODE_INSTALL^^}" == Y* ]]; then
    info "Feature Enabled: VSCODE_INSTALL is 'Y'." "${LOG_FILE_05}"
    info "Initiating VS Code installation sequence..." "${LOG_FILE_05}"
else
    warn "Feature Disabled: VSCODE_INSTALL is set to '${MYPDF_INSTALL:-NA}'." "${LOG_FILE_05}"
    info "To enable, edit your 'config.sh' and set: VSCODE_INSTALL=\"Y\"" "${LOG_FILE_05}"
    
    finish "05_install_vscode.sh" "${LOG_FILE_05}"
    exit 0
fi

#==================================================
# Step 1. VS Code Binary Installation
#==================================================
step "Step 1. Installing VS Code via Microsoft Repository" "${LOG_FILE_05}"

#----------------------------------------
# Task 1. Infrastructure Setup
#----------------------------------------
task "Task 1. Repository Preparation" "${LOG_FILE_05}"
dnf_install "epel-release" "${LOG_FILE_05}"
dnf_install "dnf-plugins-core" "${LOG_FILE_05}"

if [[ -n "${REPO_EXT}" ]]; then
    dnf config-manager --set-enabled "${REPO_EXT}" >> "${LOG_FILE_05}" 2>&1
    ok "Enabled ${REPO_EXT} repository (Rocky ${OS_VER})." "${LOG_FILE_05}"
else
    err "Repository activation failed: REPO_EXT is empty." "${LOG_FILE_05}"
fi

#----------------------------------------
# Task 2. Microsoft Repository Setup
#----------------------------------------
task "Task 2. Adding Microsoft VS Code Repository" "${LOG_FILE_05}"
rpm --import https://packages.microsoft.com/keys/microsoft.asc >> "${LOG_FILE_05}" 2>&1

cat >/etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

if [[ -f "/etc/yum.repos.d/vscode.repo" ]]; then
    ok "VS Code repository configuration created." "${LOG_FILE_05}"
else
    err "Failed to create VS Code repository file." "${LOG_FILE_05}"
fi

#----------------------------------------
# Task 3. VS Code Deployment
#----------------------------------------
task "Task 3. Deploying VS Code Package" "${LOG_FILE_05}"

info "Synchronizing metadata and installing code (Please wait)..." "${LOG_FILE_05}"
dnf -y makecache >> "${LOG_FILE_05}" 2>&1

if rpm -q code >/dev/null 2>&1; then
    note "Visual Studio Code is already installed." "${LOG_FILE_05}"
else
    info "Installing 'code' package..." "${LOG_FILE_05}"
    dnf -y makecache --disablerepo="*" --enablerepo="code" >> "${LOG_FILE_05}" 2>&1
    dnf -y install code >> "${LOG_FILE_05}" 2>&1 && ok "VS Code binary installed." "${LOG_FILE_05}"
fi

#==================================================
# Step 2. Extensions and Shared Infrastructure
#==================================================
step "Step 2. Configuring Shared Extensions" "${LOG_FILE_05}"

#----------------------------------------
# Task 1. Directory Infrastructure
#----------------------------------------
task "Task 1. Creating Shared Directories" "${LOG_FILE_05}"

mkdir -p "${EXT_DIR}" "${DEFAULTS_DIR}/User" "${CLI_USERDATA}" >> "${LOG_FILE_05}" 2>&1
chmod -R 2775 "${VSCODE_ROOT}" >> "${LOG_FILE_05}" 2>&1 # 2775 sets SGID bit to ensure new files inherit group ownership
ok "Infrastructure ready at ${VSCODE_ROOT}." "${LOG_FILE_05}"

#----------------------------------------
# Task 2. Global Default Settings
#----------------------------------------
task "Task 2. Deploying Global Default Settings" "${LOG_FILE_05}"
SRC_SETTINGS="${SETUP_DIR}/tool/vscode/settings.json"
if [[ -f "${SRC_SETTINGS}" ]]; then
    install -m 644 "${SRC_SETTINGS}" "${DEFAULTS_DIR}/User/settings.json" >> "${LOG_FILE_05}" 2>&1
    ok "Global settings.json deployed." "${LOG_FILE_05}"
else 
    warn "Source settings.json not found. Using factory defaults." "${LOG_FILE_05}"
fi 

#----------------------------------------
# Task 3. Extension List Preparation
#----------------------------------------
task "Task 3. Preparing Extension List" "${LOG_FILE_05}"

declare -a EXT_IDS
if [[ "${VSCODE_EXT_DEFAULT}" == Y* ]]; then
    EXT_IDS=("${DEFAULT_EXT_IDS[@]}")
    info "Using default lab extension list (Count: ${#EXT_IDS[@]})." "${LOG_FILE_05}"
else
    if [[ ! -f "${EXT_LIST_FILE}" ]]; then
        err "Extension list file not found: ${EXT_LIST_FILE}" "${LOG_FILE_05}"
    else
        mapfile -t EXT_IDS < <(read_ext_ids_from_file "${EXT_LIST_FILE}")
        info "Loaded extensions from ${EXT_LIST_FILE} (Count: ${#EXT_IDS[@]})." "${LOG_FILE_05}"
    fi
fi 

#----------------------------------------
# Task 4. Extension Installation
#----------------------------------------
task "Task 4. Batch Installing Extensions" "${LOG_FILE_05}"
TOTAL_EXT=${#EXT_IDS[@]}
CURRENT_EXT=0

for id in "${EXT_IDS[@]}"; do
    CURRENT_EXT=$((CURRENT_EXT + 1))
    info "  [${CURRENT_EXT}/${TOTAL_EXT}] Processing: ${id}" "${LOG_FILE_05}"
    install_one_ext "${id}" "${LOG_FILE_05}"
done

#----------------------------------------
# Task 5. Permission Finalization
#----------------------------------------
task "Task 5. Finalizing Extension Permissions" "${LOG_FILE_05}"
find "${EXT_DIR}" -type d -exec chmod 755 {} \; >> "${LOG_FILE_05}" 2>&1
find "${EXT_DIR}" -type f -exec chmod 644 {} \; >> "${LOG_FILE_05}" 2>&1
ok "Extension directory permissions standardized (755/644)." "${LOG_FILE_05}"

#==================================================
# Step 3. Creating Environment Wrapper and Helpers
#==================================================
step "Step 3. Finalizing VS Code Environment Wrappers" "${LOG_FILE_05}"

#----------------------------------------
# Task 1. Execution Wrapper Setup
#----------------------------------------
task "Task 1. Creating VS Code Launcher Wrapper" "${LOG_FILE_05}"
mkdir -p "${VSCODE_ROOT}/bin" >> "${LOG_FILE_05}" 2>&1

cat >"${CODE_LAB_BIN}" <<EOF
#!/usr/bin/env bash
# Shared VS Code Wrapper
exec /usr/bin/code --extensions-dir "${EXT_DIR}" "\$@"
EOF

chmod 0755 "${CODE_LAB_BIN}" >> "${LOG_FILE_05}" 2>&1
ensure_symlink "${BIN_ROOT}/code-lab" "${CODE_LAB_BIN}" "${LOG_FILE_05}"

if [[ -x "${CODE_LAB_BIN}" ]]; then
    ok "Execution wrapper created: ${CODE_LAB_BIN}" "${LOG_FILE_05}"
else
    err "Failed to establish ${CODE_LAB_BIN}." "${LOG_FILE_05}"
fi

#----------------------------------------
# Task 2. Profile Initialization Helper
#----------------------------------------
task "Task 2. Deploying Profile Helper" "${LOG_FILE_05}"
SRC_BASH_HELPER="${SETUP_DIR}/tool/vscode/zz-vscode-lab-defaults.sh"
if [[ -f "${SRC_BASH_HELPER}" ]]; then
    install -m 644 "${SRC_BASH_HELPER}" "/etc/profile.d/zz-vscode-lab-defaults.sh" >> "${LOG_FILE_05}" 2>&1
    chown root:root "/etc/profile.d/zz-vscode-lab-defaults.sh" >> "${LOG_FILE_05}" 2>&1
    ok "Profile helper deployed to /etc/profile.d/." "${LOG_FILE_05}"
else
    warn "Source bash helper script missing. Skipping." "${LOG_FILE_05}"
fi

SRC_TCSH_HELPER="${SETUP_DIR}/tool/vscode/zz-vscode-lab-defaults.csh"
if [[ -f "${SRC_TCSH_HELPER}" ]]; then
    install -m 644 "${SRC_TCSH_HELPER}" "/etc/profile.d/zz-vscode-lab-defaults.csh" >> "${LOG_FILE_05}" 2>&1
    chown root:root "/etc/profile.d/zz-vscode-lab-defaults.csh" >> "${LOG_FILE_05}" 2>&1
    ok "Profile tcsh helper deployed to /etc/profile.d/." "${LOG_FILE_05}"
else
    warn "Source helper script missing. Skipping." "${LOG_FILE_05}"
fi

#==================================================
# Step 4. Desktop Integration
#==================================================
step "Step 4. Desktop Environment Integration" "${LOG_FILE_05}"

SRC_DIR="${SETUP_DIR}/tool/vscode/"
install -m 755 "${SRC_DIR}/vscode-dark.png" "${VSCODE_ROOT}/vscode-dark.png" >> "${LOG_FILE_05}" 2>&1

# Create the desktop menu for remote desktop
if [[ -d /usr/share/applications ]]; then 
    write_desktop_file \
        "${DESKTOP_SYS}" \
        "Visual Studio Code (Lab)" \
        "VS Code with lab-shared extensions" \
        "${CODE_LAB_BIN}" \
        "${VSCODE_ROOT}/vscode-dark.png" \
        "Development;IDE;" \
        "false" \
        "text/plain;application/x-verilog;application/x-systemverilog;" \
        "${LOG_FILE_05}"

    ok "System desktop menu created." "${LOG_FILE_05}"
fi

# Create the desktop shortcut for remote desktop
if [[ -d /etc/skel/Desktop ]]; then 
    write_desktop_file \
        "${DESKTOP_SKEL}" \
        "Visual Studio Code (Lab)" \
        "VS Code with lab-shared extensions" \
        "${CODE_LAB_BIN}" \
        "${VSCODE_ROOT}/vscode-dark.png" \
        "Development;IDE;" \
        "false" \
        "text/plain;application/x-verilog;application/x-systemverilog;" \
        "${LOG_FILE_05}"

    write_desktop_init_file_bash "code-lab" "${LOG_FILE_05}"
    write_desktop_init_file_tcsh "code-lab" "${LOG_FILE_05}"

    ok "System desktop shortcut created." "${LOG_FILE_05}"
fi

#==================================================
# Step 5. Modulefile Generation
#==================================================
step "Step 5. Modulefile Generation" "${LOG_FILE_05}"
mkdir -p "${VSCODE_MOD_DIR}" >> "${LOG_FILE_05}" 2>&1
MOD_PATH="${VSCODE_MOD_DIR}/${VSCODE_MOD_VER}.lua"

cat >"${MOD_PATH}" <<EOF
help([[Visual Studio Code (Lab) - Shared Extensions]])
whatis("Name: code-lab")
whatis("Version: ${VSCODE_MOD_VER}")
whatis("Category: Editor, IDE")
whatis("Description: VS Code with lab-shared extensions and lab defaults")
prepend_path("PATH", "/usr/local/bin")
set_alias("code", "${CODE_LAB_BIN}")
set_alias("code-lab", "${CODE_LAB_BIN}")
setenv("VSCODE_DISABLE_TELEMETRY", "1")
setenv("ELECTRON_DISABLE_SECURITY_WARNINGS", "true")
EOF

ensure_symlink "${VSCODE_MOD_DIR}/default" "${MOD_PATH}" "${LOG_FILE_05}"
ok "Modulefile vscode/${VSCODE_MOD_VER} generated successfully." "${LOG_FILE_05}"

#==================================================
# Step 6. Execution Summary
#==================================================
step "Step 6. Check the Summary information" "${LOG_FILE_05}"

# Count installed extension
INSTALLED_EXT_COUNT=$(find "${EXT_DIR}" -maxdepth 1 -type d | grep -vC 0 "${EXT_DIR}$" | wc -l)

# Check VS Code binary file
CODE_VER=$(rpm -q code --qf '%{VERSION}' 2>/dev/null || echo "Not Found")

# Check Wrapper is valid
WRAPPER_STATUS=$([[ -x "${CODE_LAB_BIN}" ]] && echo "Active" || echo "Failed")

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  VS Code Installation Complete: 05_install_vscode.sh"
    echo -e "======================================================================"
    echo -e "  [Binary Information]"
    echo -e "    • VS Code Version : ${CODE_VER}"
    echo -e "    • Binary Source   : Microsoft Official Repository"
    echo -e "    • Launcher Path   : ${CODE_LAB_BIN}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Shared Infrastructure]"
    echo -e "    • Extensions Dir  : ${EXT_DIR}"
    echo -e "    • Extensions Count: ${INSTALLED_EXT_COUNT} installed"
    echo -e "    • Global Settings : $([[ -f "${DEFAULTS_DIR}/User/settings.json" ]] && echo "Deployed" || echo "Missing")"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Environment Integration]"
    echo -e "    • Execution Mode  : ${WRAPPER_STATUS} (via code-lab wrapper)"
    echo -e "    • Desktop Icon    : $([[ -f "${DESKTOP_SYS}" ]] && echo "Created" || echo "Skipped")"
    echo -e "    • Lmod Module     : vscode/${VSCODE_MOD_VER} (Ready)"
    echo -e "----------------------------------------------------------------------"
    echo -e "  Installation log saved to: ${LOG_FILE_05}"
    echo -e "  Next Recommended: 06_install_mypdf.sh"
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_05}"

finish "05_install_vscode.sh" "${LOG_FILE_05}"
exit 0
