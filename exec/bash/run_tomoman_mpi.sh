#! /usr/bin/env bash
set -e              # Crash on error
set -o nounset      # Crash on unset variables

## run_tomoman.sh
# A script for running TOMOMAN in parallel on a SLURM cluster.
#
# WW 07-2022


##### RUN OPTIONS #####
n_nodes=1                    # Number of nodes
n_tasks=2
n_tasks_per_node=2
cpus_per_task=5
gpu_per_node=2
gpu_per_task=1
gpu_list='2,3'              # IDs of GPUs to use. Set to "none" to use all GPUs. 


##### DIRECTORIES #####
root_dir='/hd1/wwan/2022_embo-course/hiv_subset/tomo/'    # Main TOMOMAN directory
paramfilename='tomoman_novactf.param'          # Relative path to TOMOMAN parameter file. 





################################################################################################################################################################
##### TOMOMAN
################################################################################################################################################################


# Path to MATLAB executables
tomoman="${TOMOMANHOME}/bin/tomoman_mpi.sh"


# Remove previous submission script
rm -f submit_tomoman



echo "Preparing to run TOMOMAN on MPI..."

# Set tasks
mpi_n_task="-np ${n_tasks}"
mpi_cpus_per_task="--map-by slot:PE=${cpus_per_task}" 
mpi_n_tasks_per_node="--map-by ppr:${n_tasks_per_node}:node"


# Run using MPI
mpirun $mpi_n_task $mpi_cpus_per_task $mpi_n_tasks_per_node --bind-to none $TOMOMANHOME/bin/tomoman_mpi.sh ${root_dir} ${paramfilename} $n_nodes $cpus_per_task $gpu_per_node $gpu_per_task $gpu_list #2> ${root_dir}/error_tomoman 1> ${root_dir}/log_tomoman &

exit




