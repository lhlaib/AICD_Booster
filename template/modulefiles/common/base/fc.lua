-- =============================================================================
-- ICLAB base/all : Cell-Based + Full-Custom EDA toolsets (single-line listing)
-- =============================================================================

-- ===== Header metadata =====
local PROVIDER       = "Dr. Lin-Hung Lai"
local MODULE_VERSION = "v1.0.1"
local MODULE_DATE    = "2025-09-13"
local PLATFORM       = "Rocky Linux 8.10 (NYCU ICLAB)"

-- ===== 前置（如由別處載入可移除） =====
depends_on("site")
depends_on("license/all")

-- ===== 色彩 / 粗體（只有 tool/version 會上色＋加粗） =====
local function supports_color()
  local t  = (os.getenv("TERM") or "")
  local on = (os.getenv("LMOD_COLORIZE") or os.getenv("LMOD_COLOR") or "yes"):lower()
  return (t ~= "dumb" and on ~= "no")
end

local function colorize(txt, code)
  if not supports_color() then return txt end
  return string.format("\27[%sm%s\27[0m", code, txt)
end

local function bold(txt)
  if not supports_color() then return txt end
  return string.format("\27[1m%s\27[0m", txt)
end

-- Vendor 色碼與排序（Synopsys=藍、Cadence=黃、Others=紫）
local VENDOR = {
  synopsys = {code="1;33", rank=1},
  cadence  = {code="1;33", rank=2},
  other    = {code="1;33", rank=3},
}

-- ===== 工具資料（集中管理） =====
-- group: 功能分類；domain: "cb" | "fc"
local TOOLS = {
  -- ----- Full-Custom -----
  laker          = {vendor="cadence",    version="2024.12-2",    group="Layout",      domain="fc"},
  virtuoso       = {vendor="cadence",  version="23.10.140",  group="Layout",      domain="fc"},
  hspice         = {vendor="synopsys", version="2025.06-1",  group="Sim",              domain="fc"},
  spectre        = {vendor="cadence",  version="23.10.802",  group="Sim",              domain="fc"},
  -- finesim        = {vendor="synopsys", version="2025.06-1",    group="Sim",              domain="fc"},
  primesim       = {vendor="synopsys", version="2025.06-1",    group="Sim",              domain="fc"},
  customsim      = {vendor="synopsys", version="2025.06-1",    group="Sim",              domain="fc"},
  --["star-rcxt"]  = {vendor="synopsys", version="2025.06",  group="Pex",    domain="fc"},
  liberate       = {vendor="cadence",  version="23.16.074",     group="Lib", domain="fc"},
  --customcompiler = {vendor="synopsys", version="2025.06-2",    group="Comp",      domain="fc"},
  --customexplorer = {vendor="synopsys", version="2025.06-2",    group="Comp",      domain="fc"},
  pegasus        = {vendor="cadence",  version="21.20.000",     group="Signoff",               domain="cb"},
  --icv            = {vendor="synopsys",    version="2025.06-1",  group="Signoff",               domain="cb"},
  calibre        = {vendor="other",    version="2025.3_28.17",     group="Signoff", domain="fc"},

  -- ----- Cell-Based -----
  --vcs            = {vendor="synopsys", version="2025.06",    group="Sim",              domain="cb"},
  xrun           = {vendor="cadence",  version="24.09.006",  group="Sim",              domain="cb"},
  --dc             = {vendor="synopsys", version="2025.06",    group="Syn",              domain="cb"},
  --fc             = {vendor="synopsys", version="2025.06",    group="Syn",              domain="cb"},
  --tmax           = {vendor="synopsys",  version="2025.06",   group="Syn",              domain="cb"},
  genus          = {vendor="cadence",  version="21.18.000",  group="Syn",              domain="cb"},
  stratus        = {vendor="cadence",  version="24.02.003",  group="Syn",              domain="cb"},
  --verdi          = {vendor="synopsys",  version="2025.06",    group="Debug",              domain="cb"},
  verisium       = {vendor="cadence",  version="24.09.002",  group="Debug",              domain="cb"},
  vmanager       = {vendor="cadence",  version="24.03.004",  group="Debug",              domain="cb"},
  --icc            = {vendor="synopsys", version="2025.06",    group="P&R",                     domain="cb"},
  --icc2           = {vendor="synopsys", version="2025.06",    group="P&R",                     domain="cb"},
  --icc3d          = {vendor="synopsys", version="2025.06",    group="P&R",                     domain="cb"},
  innovus        = {vendor="cadence",  version="DDI_23.34.000",  group="P&R",                     domain="cb"},
  --formality      = {vendor="synopsys",  version="2025.06",group="Formal",                  domain="cb"},
  --spyglass       = {vendor="synopsys",  version="2025.06",group="Formal",                  domain="cb"},
  jasper         = {vendor="cadence",  version="2024.03p002",group="Formal",                  domain="cb"},
  --primetime      = {vendor="synopsys", version="2025.06",  group="Signoff",                 domain="cb"},
  tempus         = {vendor="cadence", version="23.14.000",  group="Signoff",                 domain="cb"},
  quantus        = {vendor="cadence",  version="23.11.000",     group="Signoff",                 domain="cb"},
  virtuoso       = {vendor="cadence",  version="23.10.140",  group="Layout",      domain="fc"},


}

-- 左側功能順序
local CB_ORDER = {
  "Sim","Syn","P&R","Debug","Formal","Signoff"
}
local FC_ORDER = {
  "Layout","Sim","Pex",
  "Lib","Comp",
  "Signoff"
}

-- ===== 實際載入（依 tool/version） =====
local function safe_dep(name)
  local m = TOOLS[name]; if not m then return end
  if m.version and #m.version>0 then
    depends_on(name.."/"..m.version)   -- 依 version 載入
  else
    depends_on(name)
  end
end
for t,_ in pairs(TOOLS) do safe_dep(t) end

-- ===== 工具 token 與排序（單行輸出，無任何寬度/換行邏輯） =====
local function vendor_rank(vname)
  local v = VENDOR[vname or "other"] or VENDOR.other
  return v.rank
end

local function tool_token(name)
  local m = TOOLS[name]; if not m then return "", 999 end
  local v    = m.vendor or "other"
  local ver  = m.version or "?"
  local code = (VENDOR[v] and VENDOR[v].code) or VENDOR.other.code
  -- local tv   = bold(colorize(string.format("%s/%s", name, ver), code)) -- 粗體＋上色
  local tv   = bold(string.format("%s", name), code) -- 粗體＋上色
  return tv, vendor_rank(v), name
end

local function line_for(groupName, domain)
  local arr = {}
  for name, m in pairs(TOOLS) do
    if m.domain==domain and m.group==groupName then
      local txt, rank, raw = tool_token(name)
      table.insert(arr, {txt=txt, rank=rank, raw=raw})
    end
  end
  table.sort(arr, function(a,b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.raw:lower() < b.raw:lower()
  end)
  local out = {}
  for _,x in ipairs(arr) do table.insert(out, x.txt) end
  return "• "..groupName..": "..table.concat(out, ", ") 
end


-- ===== 輸出（純單行羅列；終端若寬度不足，交由終端自然換行） =====
local function print_header()
  local bar = string.rep("=", 72)
  LmodMessage("")
  LmodMessage(bar)
  LmodMessage(bold("[MOD] Loaded EDA Environment: base/all"))
  LmodMessage("Provider : ".. colorize(PROVIDER, "1;33") .. " @ " .. colorize(MODULE_VERSION, "33") .. " - " .. colorize(MODULE_DATE, "33"))  -- 36=cyan, 35=purple
  -- LmodMessage("Version  : "..MODULE_VERSION)
  -- LmodMessage("Date     : "..MODULE_DATE)
  LmodMessage("Platform : ".. colorize(PLATFORM, "33"))
  LmodMessage(bar)
end

local function section(title, order, domain)
  -- LmodMessage("")
  LmodMessage(bold(title))
  LmodMessage(string.rep("-", #title))
  for _, g in ipairs(order) do
    local line = line_for(g, domain)
    if line then LmodMessage(line) end
  end
end

local function footer()
  LmodMessage(bold("Quick Tips"))
  LmodMessage(bold("• module avail").."                 # 列出可用模組")
  LmodMessage(bold("• module list").."                  # 查看已載入模組")
  LmodMessage(bold("• module load <tool>/<ver>").."     # 載入指定版本的工具")
  LmodMessage("")
end

if (mode() == "load") then
  
  section("Cell-Based Toolset",  CB_ORDER, "cb")
  LmodMessage(string.rep("-", 72))
  section("Full-Custom Toolset", FC_ORDER, "fc")
  print_header()
  footer()
end

-- ===== whatis/help =====
help([[
Single-line grouped view. Format: "• Function: tool/version, tool/version, ..."
Only tool/version is bold & vendor-colored (Synopsys=Blue, Cadence=Yellow, Others=Purple).
No width checks and no wrapping logic; actual folding is left to the terminal.
All tool metadata live in TOOLS; depends_on loads the exact tool/version.
]])
whatis("ICLAB base/all — single-line grouped list; bold & colored tool/version; exact depends_on")
