#!/usr/bin/env bash
## tomoman_slurm.sh
# A script for running the compiled TOMOMAN in
# parallel on a SLURM cluster. The run_tomoman.sh
# is used to generate a batch script, and this
# script parses the necessary parallelization 
# parameters from the SLURM environmental variables.
#
# WW 07-2022

# Source libraries
# source $STOPGAPHOME/lib/stopgap_config_accre.sh 

# Bash parameters
set -e              # Crash on error
set -o nounset      # Crash on unset variables

# module load MATLAB/2020b

# Parse input arguments
args=("$@")
root_dir=${args[0]}
paramfilename=${args[1]}


# Get SLURM environmental parameters
n_nodes=$SLURM_JOB_NUM_NODES
node_id=$SLURM_NODEID
n_tasks=$SLURM_NTASKS
local_id=$SLURM_LOCALID
task_id=$SLURM_ARRAY_TASK_ID
n_tasks_per_node=$SLURM_NTASKS_PER_NODE
cpus_per_task=$SLURM_CPUS_PER_TASK
gpu_per_node=$SLURM_GPUS_PER_NODE
gpu_per_task=$SLURM_GPUS_PER_TASK
node_name=$SLURMD_NODENAME

# Source MCR
source $TOMOMANHOME/lib/tomoman_config.sh 

# Write some output
echo "Running TOMOMAN on $node_name, as SLURM node $node_id "


# Go to root directory
cd $root_dir


# Set MCR directory
source $TOMOMANHOME/lib/tomoman_prepare_mcr.sh 





# Run TOMOMAN
$TOMOMANHOME/lib/tomoman_parallel root_dir ${root_dir} paramfilename ${paramfilename} n_nodes ${n_nodes} node_id ${node_id} n_tasks ${n_tasks} local_id ${local_id} task_id ${task_id} n_tasks_per_node ${n_tasks_per_node} cpus_per_task ${cpus_per_task} gpu_per_node ${gpu_per_node} gpu_per_task ${gpu_per_task}




