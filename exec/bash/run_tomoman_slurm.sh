#! /usr/bin/env bash
set -e              # Crash on error
set -o nounset      # Crash on unset variables

## run_tomoman.sh
# A script for running TOMOMAN in parallel on a SLURM cluster.
#
# WW 07-2022


##### RUN OPTIONS #####
n_nodes=2                    # Number of nodes
n_tasks=4
n_tasks_per_node=2
cpus_per_task=12
gpu_per_node=2
gpu_per_task=2

queue='p.hpcl8'          # Queue for alignment jobs. Ignored for local jobs.
mem_limit='12G'              # Amount of memory per node (G = gigabytes). Ignored for local jobs.
wall_time='03-00:00:00'        # Maximum run time in seconds (format: [dd-hh:mm:ss], ACCRE production limit: 14 days). Ignored for local jobs.
job_name='tomoman'     # SLURM job name
#account='wan_lab'           # Account to charge


##### DIRECTORIES #####
root_dir='/fs/pool/pool-plitzko/Sagar/tutorials/yeast_pfib_ribosome/testbed/tomoman_v0.9/'    # Main TOMOMAN directory
paramfilename='params/tomoman_relion_motioncorr.param'          # Relative path to TOMOMAN parameter file. 





################################################################################################################################################################
##### TOMOMAN
################################################################################################################################################################


# Path to MATLAB executables
tomoman="${TOMOMANHOME}/bin/tomoman_slurm.sh"


# Remove previous submission script
rm -f submit_tomoman



echo "Preparing to run TOMOMAN on slurm-cluster..."
ls ${paramfilename}

# Write submission script
echo "#!/bin/bash" > submit_tomoman                                                         # Use BASH environment
echo "#SBATCH -D ${root_dir}" >> submit_tomoman                                             # Set working directory
echo "#SBATCH -e error_tomoman" >> submit_tomoman                                           # Output error file
echo "#SBATCH -o log_tomoman" >> submit_tomoman                                             # Output log file
echo "#SBATCH -J ${job_name}" >> submit_tomoman                                             # Job name
echo "#SBATCH --partition=${queue} " >> submit_tomoman                                      # Partition name
echo "#SBATCH --nodes=${n_nodes} " >> submit_tomoman                                        # Number of nodes
echo "#SBATCH --ntasks=${n_tasks}" >> submit_tomoman                                        # Number of tasks; i.e. number of TOMOMAN instances
echo "#SBATCH --ntasks-per-node=${n_tasks_per_node}" >> submit_tomoman                      # Number of tasks per node
echo "#SBATCH --cpus-per-task=${cpus_per_task}" >> submit_tomoman                           # CPUs per task, should generally be 1
echo "#SBATCH --mem-per-cpu=${mem_limit}" >> submit_tomoman                                 # Memory per CPU
echo "#SBATCH --gres=gpu:${gpu_per_node}" >> submit_tomoman 
#echo "#SBATCH --gpus-per-node=${gpu_per_node}" >> submit_tomoman                                 # GPUs per node
#echo "#SBATCH --gpus-per-task=${gpu_per_task}" >> submit_tomoman                            # GPUs per task
echo "#SBATCH --time=${wall_time}" >> submit_tomoman                                        # Max wall time
#echo "#SBATCH --account=${account}" >> submit_tomoman                                       # Account to charge
echo "srun ${tomoman} ${root_dir} ${paramfilename} ${gpu_per_node} ${gpu_per_task}" >> submit_tomoman

# Make executable
chmod +x submit_tomoman

# Submission command
submit_cmd="sbatch submit_tomoman"


# Submit job
eval "${submit_cmd}"
rm -f submit_tomoman

exit




