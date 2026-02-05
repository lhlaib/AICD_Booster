#!/usr/bin/env bash
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Project:      Campus Linux Environment Automation (CLEA)
# File Name:    07_install_uv.sh
# Description:  Multi-user shared UV installation with offline wheelhouse
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

# --- Package Lists ---
COMMON_WHEELS_REQS=(
    numpy pandas
    # numpy scipy pandas pyarrow xarray dask distributed numba llvmlite numexpr
    # h5py tables fastparquet fsspec zstandard lz4 brotli
    # python-dateutil pytz tzdata matplotlib seaborn plotly bokeh altair 
    # holoviews hvplot panel datashader pillow imageio scikit-image tifffile
    # opencv-python-headless opencv-contrib-python-headless scikit-learn 
    # statsmodels sympy patsy joblib cloudpickle dill pymc arviz ortools 
    # pulp mip cvxpy osqp ecos scs z3-solver python-sat PyMaxflow deap 
    # pygad pymoo jupyterlab notebook jupyterlab_server jupyter_server
    # ipykernel ipywidgets nbconvert nbformat jupyter_client jupyter_console
    # matplotlib-inline qtconsole flask fastapi starlette uvicorn[standard] 
    # gunicorn requests httpx aiohttp websockets pydantic pydantic-settings 
    # python-dotenv beautifulsoup4 lxml html5lib scrapy pypdf PyPDF2 
    # pdfminer.six python-docx python-pptx openpyxl xlsxwriter sqlalchemy 
    # orjson ujson pyyaml py7zr networkx shapely trimesh black isort 
    # flake8 mypy cython pybind11 maturin pytest pytest-cov nbqa pre-commit
    # tqdm rich colorama loguru typer click regex tenacity nltk spacy 
    # transformers sentencepiece accelerate albumentations imgaug simpleitk
    # numdifftools cocotb cocotb-bus pyvcd vcdvcd pyverilog hdlConvertor 
    # hwt veriloggen amaranth-yosys amaranth pyeda py-aiger pyserial 
    # pyvisa pyvisa-py pyftdi biopython anndata scanpy fire attrs pexpect 
    # psutil humanfriendly humanize PySide6 PyQt5 wxPython dearpygui pyglet 
    # kivy pyqtgraph dash streamlit pyinstaller wheel twine build cffi 
    # setuptools-rust hatch flit
)

OPTIONAL_HEAVY_WHEELS=(
    torch torchvision torchaudio vtk pyvista pyvistaqt 
    spacy-models-en_core_web_sm
)

PY_VERSIONS=("3.10" "3.11" "3.12")
DNF_EXTRA_PKGS=("curl" "tar" "xz" "gcc" "make" "sqlite-devel")

# --- Derived Paths ---
UV_ROOT="${TOOL_ROOT}/uv"
UV_VERSION_DIR="${UV_ROOT}/versions"
UV_BIN_CURRENT="${UV_ROOT}/current/bin"
UV_CACHE="${UV_ROOT}/cache"
UV_PY_HOME="${UV_ROOT}/python"
WHEELHOUSE="${UV_ROOT}/wheelhouse"
UV_MOD_DIR="${MODULE_ROOT}/other/uv"

# Log file initialization
LOG_FILE_07="${LOG_DIR}/07_install_uv.log"
if [[ -f "${LOG_FILE_07}" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_LOG="${LOG_FILE_07}.${TIMESTAMP}.bak"
    mv "${LOG_FILE_07}" "${BACKUP_LOG}"
fi
: > "${LOG_FILE_07}"

# header
header "07_install_uv.sh" "Multi-user shared UV installation with offline wheelhouse" "${LOG_FILE_07}"

#==================================================
# Step 0. Pre-installation Check
#==================================================
step "Step 0. Pre-installation Check" "${LOG_FILE_07}"

if [[ "${UV_INSTALL^^}" == Y* ]]; then
    info "Feature Enabled: UV_INSTALL is 'Y'." "${LOG_FILE_07}"
    info "Initiating UV installation sequence..." "${LOG_FILE_07}"
else
    warn "Feature Disabled: UV_INSTALL is set to '${UV_INSTALL:-N}'." "${LOG_FILE_07}"
    note "To enable, edit your 'config.sh' and set: UV_INSTALL=\"Y\"" "${LOG_FILE_07}"
    
    finish "07_install_uv.sh" "${LOG_FILE_07}"
    exit 0
fi

#==================================================
# Step 1. Environment Initialization & OS Packages
#==================================================
step "Step 1. Environment Initialization & OS Packages" "${LOG_FILE_07}"

#----------------------------------------
# Task 1. Set Permissions and Create Directories
#----------------------------------------
task "Task 1. Set Permissions and Create Directories" "${LOG_FILE_07}"
UMASK_SAVE=$(umask)
umask 0002

info "Initializing system directories at ${UV_ROOT}..." "${LOG_FILE_07}"
if install -d -m 2775 \
    "${UV_VERSION_DIR}" \
    "${UV_BIN_CURRENT%/bin}" \
    "${UV_CACHE}" \
    "${UV_PY_HOME}" \
    "${WHEELHOUSE}" \
    "${UV_MOD_DIR}" >> "${LOG_FILE_07}" 2>&1; then

    chown -R root:${UV_PERI_GROUP} "${UV_CACHE}"
    ok "Shared directories initialized with 2775 permissions." "${LOG_FILE_07}"
else
    fail "Directory creation failed. Check RAID2 storage status." "${LOG_FILE_07}"
fi

#----------------------------------------
# Task 2. Checking Lmod installation
#----------------------------------------
task "Task 2. Checking Lmod Installation" "${LOG_FILE_07}"    
dnf_install "epel-release" "${LOG_FILE_07}"
dnf_install "Lmod" "${LOG_FILE_07}"

#----------------------------------------
# Task 3. Installing additional packages
#----------------------------------------
task "Task 3. Installing Essential OS Kits" "${LOG_FILE_07}"
for pkg in "${DNF_EXTRA_PKGS[@]}"; do
    dnf_install "${pkg}" "${LOG_FILE_07}"
done
ok "Essential OS kits check completed." "${LOG_FILE_07}"

#==================================================
# Step 2. Download and Install uv
#==================================================
step "Step 2. Download and Install uv" "${LOG_FILE_07}"

#----------------------------------------
# Task 1. Prepare Temporary Environment
#----------------------------------------
task "Task 1. Prepare Temporary Workspace" "${LOG_FILE_07}"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT
ok "Workspace ready: ${TMP_HOME}" "${LOG_FILE_07}"

#----------------------------------------
# Task 2. Download and Execute Official Installer
#----------------------------------------
task "Task 2. Execute Official UV Installer" "${LOG_FILE_07}"
info "Running installer via curl (Check log for details)..." "${LOG_FILE_07}"
if bash -lc "export HOME='${TMP_HOME}'; curl -LsSf https://astral.sh/uv/install.sh | sh" >> "${LOG_FILE_07}" 2>&1; then
    ok "UV installer executed successfully." "${LOG_FILE_07}"
else
    fail "UV binary installation failed." "${LOG_FILE_07}"
fi

#----------------------------------------
# Task 3. Verify and Extract Version
#----------------------------------------
task "Task 3. Verify Binary & Extract Version" "${LOG_FILE_07}"
UV_BIN_SRC="${TMP_HOME}/.local/bin/uv"
if [[ -x "${UV_BIN_SRC}" ]]; then
    UV_VER="$("${UV_BIN_SRC}" --version | awk '{print $2}')"
    ok "Detected UV version: ${UV_VER}" "${LOG_FILE_07}"
else
    fail "UV binary not found in temporary workspace." "${LOG_FILE_07}"
fi

#----------------------------------------
# Task 4. Deploy to Shared Storage
#----------------------------------------
task "Task 4. Deploy UV to Shared Path" "${LOG_FILE_07}"
UV_DEST_DIR="${UV_VERSION_DIR}/uv-${UV_VER}/bin"
install -d -m 2775 "${UV_DEST_DIR}" >> "${LOG_FILE_07}"
install -m 0755 "${UV_BIN_SRC}" "${UV_DEST_DIR}/uv.real" >> "${LOG_FILE_07}" 2>&1

# Create a wrapper for uv
cat > "${UV_DEST_DIR}/uv" << 'EOF'
#!/usr/bin/env bash
# uv wrapper: set umask 0002 for commands that create files
# applies to: uv venv, uv pip *

case "$1" in
  venv|pip)
    umask 0002
    ;;
esac

# execute real uv binary in the same directory
exec "$(dirname "$0")/uv.real" "$@"
EOF

chmod 755 ${UV_DEST_DIR}/uv

ok "UV binary deployed to ${UV_DEST_DIR}." "${LOG_FILE_07}"

#----------------------------------------
# Task 5. Update Symbolic Link
#----------------------------------------
task "Task 5. Update Version Symlink" "${LOG_FILE_07}"
if ln -sfn "${UV_VERSION_DIR}/uv-${UV_VER}" "${UV_ROOT}/current" >> "${LOG_FILE_07}" 2>&1; then
    ok "Symlink updated: ${UV_ROOT}/current -> uv-${UV_VER}" "${LOG_FILE_07}"
else
    err "Failed to update version symlink." "${LOG_FILE_07}"
fi

#==================================================
# Step 3. Create uv modulefiles
#==================================================
step "Step 3. Create UV Modulefiles" "${LOG_FILE_07}"

#----------------------------------------
# Task 1. Generate Lmod Configuration
#----------------------------------------
task "Task 1. Generate Version-Specific Modulefile" "${LOG_FILE_07}"

UV_MOD_FILE="${UV_MOD_DIR}/${UV_VER}.lua"

cat > "${UV_MOD_FILE}" <<EOF
help([[uv: ultra-fast Python package & environment manager (Astral)]])
whatis("Name: uv")
whatis("Version: ${UV_VER}")
whatis("Category: Python, packaging")
whatis("Description: Fast Python package & environment manager by Astral")

local uv_root = "${UV_VERSION_DIR}/uv-${UV_VER}"
local uv_bin  = pathJoin(uv_root, "bin")

prepend_path("PATH", uv_bin)

setenv("UV_CACHE_DIR", "${UV_CACHE}")
setenv("UV_PYTHON_INSTALL_DIR", "${UV_PY_HOME}")
setenv("UV_WHEELHOUSE", "${WHEELHOUSE}")
setenv("UV_LINK_MODE", "copy")

set_alias("uv-off-install", 'uv pip install --no-index --find-links=${WHEELHOUSE}')

local function colored(txt, code)
  -- 若不想要顏色（TERM=dumb 或 LMOD_COLORIZE=no），就回傳純文字
  local t = (os.getenv("TERM") or "")
  local lc = (os.getenv("LMOD_COLORIZE") or "yes"):lower()
  if t == "dumb" or lc == "no" then return txt end
  return string.format("\27[%sm%s\27[0m", code, txt)
end
if (mode() == "load") then
  local bar = string.rep("=", 72)
  LmodMessage(bar)
  local yellow_license = colored("uv/${UV_VER}", "1;32")  -- 33 = yellow
  LmodMessage("[MOD] Loaded python venv: " .. yellow_license)
  LmodMessage("Provider : ".. colored("Lin-Hung Lai", "33") .. " @ " .. colored("v1.0.1", "33") .. " - " .. colored("12 Sep 2025", "33"))  -- 36=cyan, 35=purple
  LmodMessage("Platform : ".. colored("Rocky Linux 8.10", "33"))
  LmodMessage(bar)
end

EOF

ensure_symlink "${UV_MOD_DIR}/default" "${UV_MOD_FILE}" "${LOG_FILE_07}"

if [[ -f "${UV_MOD_FILE}" ]]; then
    ok "Modulefile uv/${UV_VER} created successfully." "${LOG_FILE_07}"
else
    err "Failed to create modulefile." "${LOG_FILE_07}"
fi

#==================================================
# Step 4. Pre-seed Python Versions and Wheels
#==================================================
step "Step 4. Pre-seed Python Versions and Wheels" "${LOG_FILE_07}"

#----------------------------------------
# Task 1. Configure Seeding Environment
#----------------------------------------
task "Task 1. Configure Seeding Environment" "${LOG_FILE_07}"

export UV_CACHE_DIR="${UV_CACHE}"
export UV_PYTHON_INSTALL_DIR="${UV_PY_HOME}"
export UV_LINK_MODE="copy"
UV_CMD="${UV_DEST_DIR}/uv"

ok "Seeding environment variables exported." "${LOG_FILE_07}"

#----------------------------------------
# Task 2. Install Shared CPython Versions
#----------------------------------------
task "Task 2. Install Shared CPython Versions" "${LOG_FILE_07}"

for ver in "${PY_VERSIONS[@]}"; do
    info "Fetching Python ${ver} for offline use..." "${LOG_FILE_07}"
    if "${UV_CMD}" python install "${ver}" >> "${LOG_FILE_07}" 2>&1; then
        ok "Python ${ver} is ready." "${LOG_FILE_07}"
    else
        err "Failed to install Python ${ver}." "${LOG_FILE_07}"
    fi
done

#----------------------------------------
# Task 3. Download Wheels to Shared Wheelhouse
#----------------------------------------
task "Task 3. Download Wheels (Resilient Mode)" "${LOG_FILE_07}"

SKIP_LOG="${WHEELHOUSE}/_skipped_$(date +%Y%m%d_%H%M%S).log"
touch "${SKIP_LOG}"

TOTAL_WHEELS=${#COMMON_WHEELS_REQS[@]}

for ver in "${PY_VERSIONS[@]}"; do
    info "Processing Python ${ver}" "${LOG_FILE_07}"
    idx=0
    for pkg in "${COMMON_WHEELS_REQS[@]}"; do
        idx=$((idx + 1))
        download_one "${ver}" "${pkg}" "[${idx}/${TOTAL_WHEELS}]"
    done

    if [[ "${ENABLE_HEAVY:-N}" == "Y" ]]; then
        info ">>> Processing heavy packages for ${ver}..." "${LOG_FILE_07}"
        for pkg in "${OPTIONAL_HEAVY_WHEELS[@]}"; do
            download_one "${ver}" "${pkg}" "[Heavy]"
        done
    fi
done

#----------------------------------------
# Task 4. Verification and Summary
#----------------------------------------
task "Task 4. Seeding Summary" "${LOG_FILE_07}"

if [[ -s "${SKIP_LOG}" ]]; then
    warn "Some packages were skipped. Details: ${SKIP_LOG}" "${LOG_FILE_07}"
else
    ok "All packages mirrored to ${WHEELHOUSE}." "${LOG_FILE_07}"
    rm -f "${SKIP_LOG}"
fi

#==================================================
# Step 5. Execution Summary
#==================================================
step "Step 5. Check the Summary information" "${LOG_FILE_07}"

# Detect UV binary files
UV_FINAL_VER="$("${UV_BIN_SRC}" --version | awk '{print $2}' || echo "Unknown")"

# Count Python version
INSTALLED_PY_COUNT=$(ls -d ${UV_PY_HOME}/cpython-* 2>/dev/null | wc -l)
PY_VERSIONS_LIST=$(ls -d ${UV_PY_HOME}/cpython-* 2>/dev/null | sed 's/.*cpython-//; s/-linux.*//' | xargs)

# Count Wheelhouse
WHEEL_COUNT=$(ls -1 "${WHEELHOUSE}"/*.whl 2>/dev/null | wc -l || echo "0")
WHEEL_SIZE=$(du -sh "${WHEELHOUSE}" 2>/dev/null | awk '{print $1}')

# Check Modulefile
MOD_STATUS=$([[ -f "${UV_MOD_DIR}/${UV_VER}.lua" ]] && echo "Generated" || echo "Failed")

{
    echo -e ""
    echo -e "======================================================================"
    echo -e "✅  UV Shared Environment Setup Complete: 07_install_uv.sh"
    echo -e "======================================================================"
    echo -e "  [UV Binary & Module]"
    echo -e "    • UV Version      : ${UV_FINAL_VER}"
    echo -e "    • Current         : ${UV_ROOT}/current"
    echo -e "    • Lmod Module     : uv/${UV_VER} (${MOD_STATUS})"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Python & Package Repository]"
    echo -e "    • Shared Py Home  : ${UV_PY_HOME}"
    echo -e "    • Py Versions     : ${INSTALLED_PY_COUNT} versions installed"
    echo -e "    • Detailed Ver    : ${PY_VERSIONS_LIST}"
    echo -e "    • Wheelhouse      : ${WHEEL_COUNT} packages cached"
    echo -e "    • Cache Disk Usage: ${WHEEL_SIZE}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  [Multi-user Optimization]"
    echo -e "    • Cache Strategy  : Shared (Mode: Copy)"
    echo -e "    • Offline Alias   : 'uv-off-install' is ready"
    echo -e "    • Permissions     : 2775 (SGID) enforced on ${UV_ROOT}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  Installation log saved to: ${LOG_FILE_07}"
    echo -e "  Users can now use 'module load uv' to access the Python ecosystem."
    echo -e "======================================================================"
    echo -e ""
} | tee -a "${LOG_FILE_07}"

finish "07_install_uv.sh" "${LOG_FILE_07}"
exit 0
