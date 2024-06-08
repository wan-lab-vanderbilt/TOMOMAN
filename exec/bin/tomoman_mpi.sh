#!/usr/bin/env bash
## tomoman_mpi.sh
# A script for running TOMOMAN in parallel locally using MPI.
#
# WW 07-2022

# Source libraries


# Bash parameters
set -e              # Crash on error
set -o nounset      # Crash on unset variables

# Parse input arguments
args=("$@")
root_dir=${args[0]}
paramfilename=${args[1]}
n_nodes=${args[2]}
cpus_per_task=${args[3]}
gpu_per_node=${args[4]}
gpu_per_task=${args[5]}
gpu_list=${args[6]}

# Parse environmental parameters
n_tasks=$OMPI_COMM_WORLD_SIZE
n_tasks_per_node=$OMPI_COMM_WORLD_LOCAL_SIZE 
node_id=$(( $OMPI_COMM_WORLD_NODE_RANK / $OMPI_COMM_WORLD_LOCAL_SIZE ))
local_id=$OMPI_COMM_WORLD_LOCAL_RANK 
task_id=$OMPI_COMM_WORLD_RANK 
node_name=$HOSTNAME


# Source MCR
source $TOMOMANHOME/lib/tomoman_config.sh 

# Write some output
echo "Running TOMOMAN on $node_name, as MPI node $node_id "


# Go to root directory
cd $root_dir


# Set MCR directory
source $TOMOMANHOME/lib/tomoman_prepare_mcr.sh 





# Run TOMOMAN
$TOMOMANHOME/lib/tomoman_parallel root_dir ${root_dir} paramfilename ${paramfilename} n_nodes ${n_nodes} node_id ${node_id} n_tasks ${n_tasks} local_id ${local_id} task_id ${task_id} n_tasks_per_node ${n_tasks_per_node} cpus_per_task ${cpus_per_task} gpu_per_node ${gpu_per_node} gpu_per_task ${gpu_per_task} gpu_list ${gpu_list}




