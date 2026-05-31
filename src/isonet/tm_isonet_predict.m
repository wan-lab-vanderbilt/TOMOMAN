function tm_isonet_predict(tomolist, p, isonet, dep, par)
%% tm_isonet_predict
% A function for taking a tomolist IsoNet parameters to run IsoNet
% prediction. 
%
% WW 06-2025


%% Initialize
disp([p.name,'Preparing inputs for IsoNet Prediction!!!1!']);


% Check for subset_list
if sg_check_param(isonet,'subset_list')
    subset_list = dlmread([p.root_dir,isonet.subset_list]);
else
    subset_list = [];
end

% Parse directories
isonet_dir = [p.root_dir,isonet.isonet_dir];
results_dir = [p.root_dir,isonet.result_dir];
output_dir = [p.root_dir,isonet.output_dir];

% Parse star names
tomo_star_name = [p.root_dir,isonet.isonet_dir,isonet.star_filename];
model_name = [p.root_dir,isonet.isonet_dir,isonet.result_dir,isonet.model_name];

% Parse tomograms to process
proc_tomo_num = [tomolist(~[tomolist.skip] & tm_check_if_aligned(tomolist)).tomo_num];    % Parse tomo_num for non-skipped
if ~isempty(subset_list)
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
end

% Split for parallel processing
if ~isempty(par)
    
    % Calculate job array
    job_array = tm_job_array(numel(proc_tomo_num),par.n_tasks);

    % Check number of jobs
    if par.task_id > size(job_array,1)         % Return empty arrays if too many tasks for jobs
        proc_tomo_num = [];
    end
    
    % Parse tomograms
    proc_tomo_num = proc_tomo_num(job_array(par.task_id,2):job_array(par.task_id,3));

end

% Parse indices
[~,proc_idx,~] = intersect([tomolist.tomo_num],proc_tomo_num);   % In case tomo_num doesn't match index in tomolist

% For boolean outputs
bool_string = {'false', 'true'};


%% Write bash file and preprocess for each tomogram

% Check for assigned jobs
if isempty(proc_idx)
    disp([p.name,'No tomograms assigned to this task...']);
    return
end


disp([p.name,'Preparing scripts for IsoNet prediction...']);

% Parse star file name
if isempty(par)    
    script_name = [p.root_dir,isonet.isonet_dir,'run_isonet_predict.sh'];
else
    script_name = [p.root_dir,isonet.isonet_dir,'run_isonet_predict.sh_',num2str(par.task_id)];
end

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Run IsoNet Prediction #####"','\n\n']);

% Run prediction
fprintf(script,[dep.isonet,' predict ',tomo_star_name,' ',model_name]);
fprintf(script,[' --use_deconv_tomo ',bool_string{isonet.use_deconv_tomo+1}]);
fprintf(script,[' --output_dir ',output_dir]);
if sg_check_param(isonet,'cube_size')
    fprintf(script,[' --cube_size ',num2str(isonet.cube_size)]);
end
if sg_check_param(isonet,'crop_size')
    fprintf(script,[' --crop_size ',num2str(isonet.crop_size)]);       
end
if ~isempty(subset_list)
    fprintf(script,[' --tomo_idx ',char(strjoin(string(proc_tomo_num), ','))]);
end
if sg_check_param(isonet,'gpuID')
    fprintf(script,[' --gpuID ',char(strjoin(string(isonet.gpuID), ','))]);
end
fprintf(script,'\n\n');           




% Close file
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet prediction...']);
system(script_name);



end


