function tm_isonet2_make_mask(p, isonet2, dep, par)
%% tm_isonet2_make_mask
% Run IsoNet2 to make masks before refine training.
%
% WW 02-2026


%% Initialize
disp([p.name,'Making masks using IsoNet2!!!1!']);


% Check directories
isonet2_dir = [p.root_dir,isonet2.isonet2_dir];
output_dir = [isonet2_dir,isonet2.mask_subdir];
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

% Parse star name
input_star_name = [isonet2_dir,isonet2.star_filename];

% Read input star
input_star = stopgap_star_read(input_star_name);
proc_tomo_num = [input_star.rlnIndex];      % Parse tomo_num
    
% Check for subset_list
if sg_check_param(isonet2,'subset_list')
    % Read subset list
    subset_list = dlmread([p.root_dir,isonet2.subset_list]);
    
    % Parse tomo_num to be processed
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
    n_tomos = size(subset_list,1);
        
else
    n_tomos = numel(input_star);
end


% Split for parallel processing
if ~isempty(par)
    
    % Calculate job array
    job_array = tm_job_array(n_tomos,par.n_tasks);

    % Check number of jobs
    if par.task_id > size(job_array,1)         % Return empty arrays if too many tasks for jobs
        disp([p.name,'No tomograms assigned to this task...']);
        return        
    else
        % Parse tomograms
        proc_tomo_num = proc_tomo_num(job_array(par.task_id,2):job_array(par.task_id,3));
    end
    
    % Parse output star name
    mask_star_filename = [isonet2_dir,'make_mask_',num2str(par.task_id),'.star'];
    
else
    % Parse output star name
    mask_star_filename = [isonet2_dir,'make_mask.star'];
end

% Parse indices
[~,proc_idx,~] = intersect([input_star.rlnIndex],proc_tomo_num);

% Write star
stopgap_star_write(input_star(proc_idx),mask_star_filename,'isonet2',[],4);
    

%% Run make_mask

% Initialize make_mask runscript
if ~isempty(par)
    script_name = [isonet2_dir,'run_make_mask.sh_',num2str(par.task_id)];
    log_name = [isonet2_dir,'make_mask.log_',num2str(par.task_id)];
else
    script_name = [isonet2_dir,'run_make_mask.sh'];
    log_name = [isonet2_dir,'make_mask.log'];
end

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Running IsoNet2 make_mask #####"','\n\n\n']);

% Write script
fprintf(script,[dep.isonet2,' make_mask ',mask_star_filename]);
fprintf(script,[' --output_dir ',output_dir]);
fprintf(script,[' --density_percentage ',isonet2.density_percentage]);
fprintf(script,[' --std_percentage ',isonet2.std_percentage]);
fprintf(script,[' --patch_size ',isonet2.patch_size]);
fprintf(script,[' --z_crop ',isonet2.z_crop]);
fprintf(script,' --input_column rlnDenoisedTomoName');

% Append log output
fprintf(script,[' > ',log_name]);

% Close script
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet2 make_mask...']);
system(script_name);


%% Compile results
% NOTE: This is still required for non-parallel jobs in case of subset
% processing. 


% Concatenate parallel star files
if ~isempty(par)
    
    % Write completed com
    system(['touch ',par.comm_dir,'tomoman_isonet2_make_mask_',num2str(par.task_id)]);
    
    % Run process or wait
    if par.task_id == 1
        % Wait for parallel jobs
        disp([par.name,'Waiting for all tasks to finish...']);
        tm_wait_for_them(par.comm_dir,'tomoman_isonet2_make_mask',par.n_tasks,5);
        
        % Assemble star files
        disp([par.name,'All parallel star files written!!! Assembling full star file...']);
        tm_isonet2_update_star(input_star,[isonet2_dir,'make_mask'],input_star_name,true,size(job_array,1)); 
        
        % Write completion file
        system(['touch ',par.comm_dir,'tomoman_isonet2_make_mask_star']);
    else
        % Wait for sorting to finish
        disp([p.name,'Waiting for full star files...']);
        tm_wait_for_it(par.comm_dir,'tomoman_isonet2_make_mask_star',5);  
    end
    
   
else
    % Update star file
    tm_isonet2_update_star(input_star,mask_star_filename,input_star_name,false,1);
end 









