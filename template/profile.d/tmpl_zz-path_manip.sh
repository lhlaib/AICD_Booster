# /etc/profile.d/zz-path_manip.sh

# 判斷是否為 root 或一般使用者來決定路徑順序
if [ "$EUID" = "0" ]; then
    # root 將自定義路徑放在前面
    pathmunge ${BIN_ROOT}
else
    # 一般使用者將自定義路徑放在後面，避免蓋掉系統標準指令
    pathmunge ${BIN_ROOT} after
fi
