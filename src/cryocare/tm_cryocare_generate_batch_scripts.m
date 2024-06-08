function tomoman_cryocare_generate_batch_scripts(t,p,root_dir,script_name)
%% will_imod_batchprocess_generate_batch_scripts
% A script to generate a set of scripts for batch tomogram reconstruction
% with imod_batchprocess. 
%
% WW 01-2018

%% Initialize

% Number of tomograms to reconstruct
n_tomos = numel(t);

% Enforce single job if training multiple tomograms
if_batch_train = p.cc_batch_train;

if if_batch_train
    n_tomos = 1;
end

% Determine job parameters
job_array = will_job_array(n_tomos,p.n_comp);
n_jobs = size(job_array,1);
if n_jobs < p.n_comp
    switch n_jobs
        case 1
            disp(['ACHTUNG!!! Only 1 job is needed!!!']);
        otherwise
            disp(['ACHTUNG!!! Only ',num2str(n_jobs),' jobs are needed!!!']);
    end
end

%% Write job scripts

for i = 1:n_jobs
    
    % Open batch script
    bscript = fopen([root_dir,'/',script_name,'_',num2str(i),'.sh'],'w');
    fprintf(bscript,['#!/bin/sh \n\n','echo $HOSTNAME\n','set -e \n','set -o nounset \n\n']);
    
    % Set qsub jobid counter
    c = 0;
    
    switch p.queue
%         case 'p.512g'
%             error('Oops!! 404');
%             for j = job_array(i,2):job_array(i,3)
% 
%                 % Write lines
%                 if c == 0   
%                     fprintf(bscript,['qsub -N job',num2str(i,'%02d'),num2str(c,'%02d'),' ',t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%                 else
%                     fprintf(bscript,['qsub -N job',num2str(i,'%02d')dir,num2str(c,'%02d'),' -hold_jid job',num2str(i,'%02d'),num2str(c-1,'%02d'),' ',t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%                 end
%                 c = c + 1;
%             end
%         case 'p.192g'
%             error('Oops!! 404');
%             for j = job_array(i,2):job_array(i,3)
% 
%                 % Write lines
%                 if c == 0   
%                     fprintf(bscript,['qsub -N job',num2str(i,'%02d'),num2str(c,'%02d'),' ',t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%                 else
%                     fprintf(bscript,['qsub -N job',num2str(i,'%02d'),num2str(c,'%02d'),' -hold_jid job',num2str(i,'%02d'),num2str(c-1,'%02d'),' ',t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%                 end
%                 c = c + 1;
%             end
            
%         case 'local'
%             for j = job_arrcc_batch_trainay(i,2):job_array(i,3)
% 
%                 % Write lines                    
%                 fprintf(bscript,[t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%             end
%             
%         case 'p.hpcl67'
%             for j = job_array(i,2):job_array(i,3)
% 
%                 % Write lines
%                 if c == 0   
%                     fprintf(bscript,['sbatch ',t(j).stack_dir,'imod_batchproOnlycess/run_IMOD.sh','\n']);
%                 else
%                     fprintf(bscript,['sbatch ',t(j).stack_dir,'imod_batchprocess/run_IMOD.sh','\n']);
%                 end
%                 c = c + 1;
%             end
            
        case 'p.hpcl8'
            for j = job_array(i,2):job_array(i,3)
                
                
                
                % Write lines
                if c == 0   
                    if if_batch_train
                        fprintf(bscript,['sbatch ',p.cc_path,'/run_cryocare.sh','\n']);
                    else
                        %fprintf(bscript,['sbatch ',t(j).stack_dir,'/cryocare/run_cryocare.sh','\n']);
                        fprintf(bscript,['JOBID=$(sbatch ',t(j).stack_dir,'/cryocare/run_cryocare.sh',' 2>&1 | awk ','''','{print $(NF)}','''',')\n']);
                        fprintf(bscript,['echo ''''  '''' ${JOBID}','\n']);

                    end
                else
                    %fprintf(bscript,['sbatch ',t(j).stack_dir,'/cryocare/run_cryocare.sh','\n']);
                    fprintf(bscript,['JOBID=$(sbatch --dependency=afterany:${JOBID} ',t(j).stack_dir,'/cryocare/run_cryocare.sh',' 2>&1 | awk ','''','{print $(NF)}','''',')\n']);
                    fprintf(bscript,['echo ''''  '''' ${JOBID}','\n']);
                end
                c = c + 1;
            end
            
        otherwise
               error('only "p.hpcl8" are supported for p.queue!!!!')
            
        
    end    
    
    % Close batch script and make executable
    fclose(bscript);
    system(['chmod +x ',root_dir,'/',script_name,'_',num2str(i),'.sh']);

end


submit_all_filename = [root_dir,'/',script_name,'_all.sh'];
submit_file = fopen(submit_all_filename,'w');
for i = 1:n_jobs
    fprintf(submit_file,[root_dir,'/',script_name,'_',num2str(i),'.sh\n']);    
end
fclose(submit_file);
system(['chmod +x ',submit_all_filename]);
