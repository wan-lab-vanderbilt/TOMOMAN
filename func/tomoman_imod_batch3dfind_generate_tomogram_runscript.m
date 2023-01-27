function tomoman_imod_batch3dfind_generate_tomogram_runscript(t,p)
%% will_novactf_generate_tomogram_runscript
% A function to generate a 'runscript' for running novaCTF on a tilt-stack.
% When run, the runscript first runs parallel processing of tilt-stacks via
% MPI; when the MPI job is completed, it finishes the tomogram by running
% novaCTF. The tomogram is then binned via Fourier cropping and the 
% intermediate files are deleted. 
%
% WW 01-2018

%% Initialize

%% Check for refined center (__FUTURE__: implement xaxis tilt based on motl)
% 
% if isfield(p,'mean_z')
%     tomo_idx = p.mean_z(1,:) == t.tomo_num; % Find tomogram index
%     mean_z = round(p.mean_z(2,tomo_idx));   % Parse mean Z value
%     cen_name = [t.stack_dir,'/imod_batch3dfind/refined_cen.txt'];
%     dlmwrite(cen_name,mean_z);
%     new_cen = ['DefocusShiftFile ',cen_name];
% else
%     new_cen = [];
% end
%     


%% Generate run script

% Open run script
rscript = fopen([t.stack_dir,'/imod_batch3dfind/run_IMOD.sh'],'w');


% Write initial lines for submission on either local or hpcl700x (p.512g)
% 
% EDIT SK 27112019
switch p.queue
    case 'p.512g'
        error('Oops!! 404');
%         fprintf(rscript,['#! /usr/bin/env bash\n\n',...
%             '#$ -pe openmpi 40\n',...            % Number of cores
%             '#$ -l h_vmem=128G\n',...            % Memory limit
%             '#$ -l h_rt=604800\n',...              % Wall time
%             '#$ -q ',p.queue,'\n',...                       %  queue
%             '#$ -e ',t.stack_dir,'/novactf/error_novactf\n',...       % Error file
%             '#$ -o ',t.stack_dir,'/novactf/log_novactf\n',...         % Log file
%             '#$ -S /bin/bash\n',...                      % Submission environment
%             'source ~/.bashrc\n\n',]);                      % Get proper envionment; i.e. modules

    case 'p.192g'
        error('Oops!! 404');
%         fprintf(rscript,['#! /usr/bin/env bash\n\n',...
%             '#$ -pe openmpi 16\n',...            % Number of cores
%             '#$ -l h_vmem=128G\n',...            % Memory limit
%             '#$ -l h_rt=604800\n',...              % Wall time
%             '#$ -q ',p.queue,'\n',...                       %  queue
%             '#$ -e ',t.stack_dir,'/novactf/error_novactf\n',...       % Error file
%             '#$ -o ',t.stack_dir,'/novactf/log_novactf\n',...         % Log file
%             '#$ -S /bin/bash\n',...                      % Submission environment
%             'source ~/.bashrc\n\n',]);                      % Get proper envionment; i.e. modules        
    case 'local'
        fprintf(rscript,['#!/usr/bin/env bash \n\n','echo $HOSTNAME\n','set -e \n','set -o nounset \n\n']);
            
    case 'p.hpcl67'
        fprintf(rscript,['#!/bin/bash -l\n',...
            '# Standard output and error:\n',...
            '#SBATCH -e ' ,t.stack_dir,'/novactf/error_novactf\n',...
            '#SBATCH -o ' ,t.stack_dir,'/novactf/log_novactf\n',...
            '# Initial working directory:\n',...
            '#SBATCH -D ./\n',...
            '# Job Name:\n',...
            '#SBATCH -J AreTomo\n',...
            '# Queue (Partition):\n',...
            '#SBATCH --partition=p.hpcl67 \n',...
            '# Number of nodes and MPI tasks per node:\n',...
            '#SBATCH --nodes=1\n',...
            '#SBATCH --ntasks=40\n',...
            '#SBATCH --ntasks-per-node=40\n',...
            '#SBATCH --cpus-per-task=1\n',...            %'#SBATCH --gres=gpu:2\n',...
            '#\n',...
            '#SBATCH --mail-type=none\n',...
            '#SBATCH --mem 510000\n',...
            '#\n',...
            '# Wall clock limit:\n',...
            '#SBATCH --time=168:00:00\n',...
            'echo "setting up environment"\n',...
            'module purge\n',...
            'module load intel/18.0.5\n',...
            'module load impi/2018.4\n',...
            '#load module for your application\n',...
            'module load FOURIER3D/06-10-20\n',...
            'module load IMOD/4.10.49\n',...
            'export IMOD_PROCESSORS=40\n']);                      % Get proper envionment; i.e. modules
        
    otherwise
            error('only "local" or "p.hpcl67" are supported queques for p.queue!!!!')
        
    
end


% Run parallel scripts
fprintf(rscript,['# Process stacks','\n']);
fprintf(rscript,[t.stack_dir,'imod_batch3dfind/stack_process.sh\n\n']);

% Close file and make executable
fclose(rscript);
system(['chmod +x ',t.stack_dir,'/imod_batch3dfind/run_IMOD.sh']);

                 


