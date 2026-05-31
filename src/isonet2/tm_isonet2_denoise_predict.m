function tm_isonet2_denoise_predict(p, isonet2, dep, par)
%% tm_isonet2_denoise_predict
% Run IsoNet2 denoising with a pre-trained network.
%
% WW 02-2026


%% Initialize
disp([p.name,'Preparing tomograms for IsoNet2 Denoising Prediction!!!1!']);


% Check directories
isonet2_dir = [p.root_dir,isonet2.isonet2_dir];
training_dir = [isonet2_dir,isonet2.denoise_training_subdir];
predict_dir = [isonet2_dir,isonet2.denoise_predict_subdir];
if ~exist(predict_dir,'dir')
    mkdir(predict_dir);
end

% Find latest model
model_dir = dir([training_dir,'*.pt']);
[~,model_idx] = sort([model_dir.datenum]);
model_name = [training_dir,model_dir(model_idx(end)).name];

% Parse star name
input_star_name = [isonet2_dir,isonet2.star_filename];

% Read input star
input_star = stopgap_star_read(input_star_name);
proc_tomo_num = [input_star.rlnIndex];      % Parse tomo_num
    
% Check for subset_list
if sg_check_param(isonet2,'subset_list')
    % Read subset list
    subset_list = dlmread([p.root_dir,isonet2.predict_subset_list]);
    
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
    predict_star_filename = [isonet2_dir,'denoise_predict_',num2str(par.task_id),'.star'];
    
    % Parse temporary output folder
    output_dir = [predict_dir,'temp_',num2str(par.task_id),'/'];
    if ~exist(output_dir,'dir')
        mkdir(output_dir);
    end
    
else
    % Parse output star name
    predict_star_filename = [isonet2_dir,'denoise_predict.star'];
    
    % Copy output dir
    output_dir = predict_dir;
end

% Parse indices
[~,proc_idx,~] = intersect([input_star.rlnIndex],proc_tomo_num);

% Write star
stopgap_star_write(input_star(proc_idx),predict_star_filename,'isonet2',[],4);
    

%% Run prediction

% Initialize prediction runscript
if ~isempty(par)
    script_name = [isonet2_dir,'run_denoise_predict.sh_',num2str(par.task_id)];
    log_name = [isonet2_dir,'denoise_predict.log_',num2str(par.task_id)];
else
    script_name = [isonet2_dir,'run_denoise_predict.sh'];
    log_name = [isonet2_dir,'denoise_predict.log'];
end

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Running IsoNet2 Denoise Prediction #####"','\n\n\n']);

% Write script
fprintf(script,[dep.isonet2,' predict ',predict_star_filename]);
fprintf(script,[' --model ',model_name]);
fprintf(script,[' --gpuID ',regexprep(num2str(isonet2.gpuID),'\s+',',')]);
fprintf(script,[' --output_dir ',output_dir]);

% Append log output
fprintf(script,[' > ',log_name]);

% Close script
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet2 denoise prediction...']);
system(script_name);


%% Compile results
% NOTE: This is still required for non-parallel jobs in case of subset
% processing. 


% Concatenate parallel star files
if ~isempty(par)
    
    % Write completed com
    system(['touch ',par.comm_dir,'tomoman_isonet2_denoise_predict_',num2str(par.task_id)]);
    
    % Run process or wait
    if par.task_id == 1
        % Wait for parallel jobs
        disp([par.name,'Waiting for all tasks to finish...']);
        tm_wait_for_them(par.comm_dir,'tomoman_isonet2_denoise_predict',par.n_tasks,5);
        
        % Assemble star files
        disp([par.name,'All parallel star files written!!! Assembling full star file...']);
        tm_isonet2_update_star(input_star,[isonet2_dir,'denoise_predict'],input_star_name,true,size(job_array,1)); 
        
        % Move parallel outputs
        for i = 1:par.n_tasks
            system(['mv ',predict_dir,'temp_',num2str(i),'/* ',predict_dir]);
            system(['rmdir ',predict_dir,'temp_',num2str(i),'/']);
        end
        
        % Write completion file
        system(['touch ',par.comm_dir,'tomoman_isonet2_denoise_predict_star']);
    else
        % Wait for sorting to finish
        disp([p.name,'Waiting for full star files...']);
        tm_wait_for_it(par.comm_dir,'tomoman_isonet2_denoise_predict_star',5);  
    end
    
   
else
    % Update star file
    tm_isonet2_update_star(input_star,predict_star_filename,input_star_name,false,1);
end 









