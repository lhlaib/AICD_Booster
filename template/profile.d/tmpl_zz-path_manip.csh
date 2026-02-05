# /etc/profile.d/zz-path_manip.csh

# 判斷是否為 root 或一般使用者來決定路徑順序
if ( $uid == 0 ) then
    # root 將自定義路徑放在前面
    # 注意：csh 的 path 變數是以空格分隔的陣列
    set path = ( ${BIN_ROOT} $path )
else
    # 一般使用者將自定義路徑放在最後面
    set path = ( $path ${BIN_ROOT} )
endif
