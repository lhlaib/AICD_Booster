# EDA Modulefiles Path Configuration
if ( ! $?MODULEPATH ) then
    setenv MODULEPATH ""
endif

setenv MODULEPATH "${MODULE_ROOT}/other:${MODULEPATH}"
setenv MODULEPATH "${MODULE_ROOT}/mentor:${MODULEPATH}"
setenv MODULEPATH "${MODULE_ROOT}/synopsys:${MODULEPATH}"
setenv MODULEPATH "${MODULE_ROOT}/cadence:${MODULEPATH}"
setenv MODULEPATH "${MODULE_ROOT}/common:${MODULEPATH}"

