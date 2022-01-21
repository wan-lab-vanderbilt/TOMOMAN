#!/usr/bin/env bash
## fourier_crop_stack.sh
# A script for binning a .mrc image stack by Fourier cropping. 
#
# WW 01-2018

# Bash parameters
set -e              # Crash on error
set -o nounset      # Crash on unset variables

# Source MCR
matlabRoot="/fs/pool/pool-apps-rz/MATLAB_2015b"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/runtime/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/bin/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/sys/os/glnxa64/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}":$matlabRoot/sys/opengl/lib/glnxa64/"

# Parse input arguments
args=("$@")
stack_name=${args[0]}
new_name=${args[1]}
binning=${args[2]}

# Make MCR directory
#curr_dir=$(pwd)
#name=$(basename ${stack_name})
mcr_dir="${stack_name}_mrc/"
rm -rf ${mcr_dir}
mkdir ${mcr_dir}
export MCR_CACHE_ROOT=${mcr_dir}

# Fourier crop stack
fcrop='/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/github/fcrop_stack/fourier_crop_stack'
eval "${fcrop} ${stack_name} ${new_name} ${binning}"

# Cleanup
rm -rf ${mcr_dir}
