## tomoman_config.sh
# Sources MATLAB MCR directories required to run TOMOMAN.
# This script is for MCR 2020b or later.
#
# WW 06-2019

# Force shell
# export MATLAB_SHELL="/bin/sh"

# Source MCR
matlabRoot="/dors/wan_lab/software/MCR_R2020b/v99"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/runtime/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/bin/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/sys/os/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/sys/opengl/lib/glnxa64/"

# Preload glibc_shim in case of RHEL7 variants
# Required for MCR 2020b
test -e /usr/bin/ldd &&  ldd --version |  grep -q "(GNU libc) 2\.17"  \
    && export LD_PRELOAD="${matlabRoot}/bin/glnxa64/glibc-2.17_shim.so"

