help([[lstc license bundle]])
whatis("lstc license bundle")
-- 逐一追加（不覆蓋），Lmod 會自動去重
local items = {"1717@lstc","5280@lstc","26585@lstc"}
for _,v in ipairs(items) do
  append_path("LM_LICENSE_FILE", v, ":")
end

local function colored(txt, code)
  -- 若不想要顏色（TERM=dumb 或 LMOD_COLORIZE=no），就回傳純文字
  local t = (os.getenv("TERM") or "")
  local lc = (os.getenv("LMOD_COLORIZE") or "yes"):lower()
  if t == "dumb" or lc == "no" then return txt end
  return string.format("\27[%sm%s\27[0m", code, txt)
end

if (mode() == "load") then
  local bar = string.rep("=", 72)
  local yellow_license = colored("license/lstc", "1;32")  -- 33 = yellow
  LmodMessage(bar)
  LmodMessage("[MOD] Loaded license: " .. yellow_license)
  LmodMessage("Provider : ".. colored("Lin-Hung Lai", "1;33") .. " @ " .. colored("v1.0.1", "33") .. " - " .. colored("12 Sep 2025", "33"))  -- 36=cyan, 35=purple
  LmodMessage("Platform : ".. colored("Rocky Linux 8.10", "33"))
  LmodMessage(bar)
end
