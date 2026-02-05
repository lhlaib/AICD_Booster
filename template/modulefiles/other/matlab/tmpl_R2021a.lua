-- =====
-- Module : mathworks / matlab / 2021a
-- Generated for Rocky Linux 8 (Lmod)
-- Author: Lin-Hung Lai (template)
-- =====

-- =======================================================
-- Tool / Module Identifiers
-- =======================================================
local version     = "R2021a"
local tool        = "matlab"
local module_name = "matlab"
local vendor      = "mathworks"
local MODULE      = string.upper(module_name)

-- =======================================================
-- Define common variables
-- =======================================================
-- 安裝根目錄（依實際安裝路徑調整）
-- 典型 GUI 安裝預設在 /usr/local/MATLAB/R2021a
local cad_root  = "/RAID2/tool"         -- 你也可以用 /RAID2/cad
local root      = cad_root .. "/" .. tool .. "/" .. version

-- 二進位與常見庫路徑
local bins = {
  "bin",
}
-- MATLAB 一般不必加 LD_LIBRARY_PATH；若你有外部呼叫 mex,
-- 少數情況需要讓動態載入器能找到 glnxa64 內的庫時，可啟用下列兩行
local libs = {
  -- "bin/glnxa64",
  -- "sys/os/glnxa64",
}

-- 手冊（Doc Hub 在 GUI 內，這裡只是提供 MANPATH）
local manuals = {
  "help",
}

-- =======================================================
-- Module file header
-- =======================================================
help([[ ]] .. MODULE .. [[ ]] .. version .. [[ (]] .. string.upper(vendor) .. [[)]])
whatis("Vendor       : " .. string.upper(vendor))
whatis("Module       : " .. MODULE)
whatis("Tool path    : " .. tool)
whatis("Version      : " .. version)
whatis("===========================")
whatis("Original author: Lin-Hung Lai")
whatis("Date: " .. os.date("%d %b %Y"))
whatis("===========================")

-- ========= Dependencies =========
-- 依你的站台習慣調整
-- depends_on("license/all")
-- depends_on("site")

-- ========= PATH =========
for _,p in ipairs(bins) do
  local full = pathJoin(root, p)
  if (isDir(full)) then
    prepend_path("PATH", full)
  end
end

-- ========= Libraries (通常不需要) =========
for _,p in ipairs(libs) do
  local full = pathJoin(root, p)
  if (isDir(full)) then
    prepend_path("LD_LIBRARY_PATH", full)
    prepend_path("SHLIB_PATH",      full)
  end
end

-- ========= MANPATH =========
for _,p in ipairs(manuals) do
  local full = pathJoin(root, p)
  if (isDir(full)) then
    prepend_path("MANPATH", full)
  end
end

-- ========= Environment Variables =========
setenv("MATLAB_ROOT", root)
setenv("MW_HOME",     root)         -- 有些工具用這個
-- 將快取放到 /tmp（避免家目錄配額被吃）
setenv("MCR_CACHE_ROOT", "/tmp")

-- ===== 授權設定 =====
-- 二擇一：
-- 1) 指向 license server（常見）
--    例： setenv("LM_LICENSE_FILE", "27000@your-license-host")
--    或   setenv("MLM_LICENSE_FILE", "27000@your-license-host")
-- 2) 指向 license 檔（network.lic 的完整路徑）
--    例： setenv("MLM_LICENSE_FILE", "/usr/local/MATLAB/network.lic")

-- 預留空值，交由使用者或上層 module 設定：
pushenv("MLM_LICENSE_FILE",            os.getenv("MLM_LICENSE_FILE") or "")
pushenv("LM_LICENSE_FILE",             os.getenv("LM_LICENSE_FILE") or "")

-- 視需求可固定預設：
-- setenv("MLM_LICENSE_FILE", "27000@licenseserver")

-- ========= Aliases（可選） =========
-- set_alias("matlab-nogui", "matlab -nodesktop -nosplash")

-- ========= Load Message =========
local map = {
  synopsys = "1;35",  -- 粗體紫
  cadence  = "1;33",  -- 粗體黃
  mentor   = "1;34",  -- 粗體藍
  mathworks= "1;31",  -- 粗體紅
}
local function colored(txt, code)
  local t = (os.getenv("TERM") or "")
  local lc = (os.getenv("LMOD_COLORIZE") or "yes"):lower()
  if t == "dumb" or lc == "no" then return txt end
  return string.format("\27[%sm%s\27[0m", code, txt)
end
local code = map[string.lower(vendor)] or "1;32"
local module_name_colored = colored(module_name, code)
local version_colored     = colored(version, code)

if (mode() == "load") then
  local bar = string.rep("=", 72)
  LmodMessage(bar)
  LmodMessage(string.format("[MOD] Loaded %s tool: %s/%s", vendor, module_name_colored, version_colored))
  LmodMessage("Provider : ".. colored("Lin-Hung Lai", "33") .. " @ " .. colored("v1.0.1", "33") .. " - " .. colored("12 Sep 2025", "33")) -- 36=cyan, 35=purple
   LmodMessage("Platform : ".. colored("Rocky Linux 8.10", "33")) 
  -- LmodMessage("MATLAB root : " .. colored(root, "33"))
  -- LmodMessage("License     : use MLM_LICENSE_FILE or LM_LICENSE_FILE (server or .lic)")
  LmodMessage(bar)
end

