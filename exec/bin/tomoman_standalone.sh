#!/usr/bin/env bash
## tomoman_standalone.sh
# A wrapper script for running the standalone TOMOMAN.
#
# WW 05-2024

# Bash parameters
source $TOMOMANHOME/lib/tomoman_config.sh 

set -e              # Crash on error
set -o nounset      # Crash on unset variables

# Set MCR directory
if [ -d "/tmp/${USER}/mcr/tomoman_standalone" ]; then
    rm -rf /tmp/${USER}/mcr/tomoman_standalone
fi
mkdir -p /tmp/${USER}/mcr/tomoman_standalone

# Run parser
$TOMOMANHOME/lib/tomoman_standalone "$@"

# Cleanup MCR
rm -rf /tmp/${USER}/mcr/tomoman_standalone
