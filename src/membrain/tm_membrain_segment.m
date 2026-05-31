function tm_membrain_segment(tomolist, p, membrain, dep, par)
%% tm_membrain_segment
% A function for taking a tomolist and membrain parameters to run membrain
% segmentation. 
%
% WW 06-2025


%% Initialize
disp([p.name,'Preparing inputs for Membrain Segmentation!!!1!']);


% Check for subset_list
if sg_check_param(membrain,'subset_list')
    subset_list = dlmread([p.root_dir,membrain.subset_list]);
else
    subset_list = [];
end

% Parse directories
tomo_dir = tm_check_absolute_path(p.root_dir,membrain.tomo_dir);
ckpt_path = tm_check_absolute_path(p.root_dir,membrain.ckpt_path);
output_dir = [p.root_dir,membrain.out_folder];
if ~exist(output_dir,'dir')
    system(['mkdir ',output_dir]);
end


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
n_stacks = numel(proc_idx);

% For boolean outputs
bool_string = {'false', 'true'};


%% Write bash file and preprocess for each tomogram

% Check processing stack
switch membrain.process_stack
    case 'unfiltered'
        append = '_';   % This is a hack... it assumes the input stack has some type of appendix.
    case 'dose-filtered'
        append = '_dose-filt';
end


% Check for assigned jobs
if isempty(proc_idx)
    disp([p.name,'No tomograms assigned to this task...']);
    return
end


disp([p.name,'Preparing scripts for Membrain segmentation...']);

% Parse star file name
if isempty(par)    
    script_name = [output_dir,'run_membrane_segmentation.sh'];
else
    script_name = [output_dir,'run_membrane_segmentation.sh_',num2str(par.task_id)];
end

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['export CUDA_VISIBLE_DEVICES=',char(strjoin(string(membrain.gpu_id), ',')),'\n\n']);
fprintf(script,['echo "##### Run Membrain Segmentation #####"','\n\n']);

% Print line for each tomogram
for i = 1:n_stacks
    
    % Attempt to parse tomo_name
    [~,name,~] = fileparts(tomolist(i).stack_name);
    d = dir([tomo_dir,name,append,'*']);
    if numel(d) > 1
        error([p.name,'ACHTUNG!!! tomo_dir contains more than one file that starts with "',name,'"...']);
    end
    tomo_name = d.name;
    
    % Calculate pixelsize
    pixelsize = tomolist(i).pixelsize*membrain.tomo_binning;
    
    % Print lines
    fprintf(script,[dep.membrain,' segment']);
    fprintf(script,[' --tomogram-path ',tomo_dir,tomo_name]);
    fprintf(script,[' --ckpt-path ',ckpt_path]);
    fprintf(script,[' --out-folder ',output_dir]);
    if sg_check_param(membrain,'rescale_patches')
        fprintf(script,' --rescale-patches');
    else
        fprintf(script,' --no-rescale-patches');
    end
    fprintf(script,[' --in-pixel-size ',num2str(pixelsize)]);
    fprintf(script,[' --out-pixel-size ',num2str(pixelsize)]);
    
    if sg_check_param(membrain,'store_probabilities')
        fprintf(script,' --store-probabilities');
    else
        fprintf(script,' --no-store-probabilities');
    end
    
    if sg_check_param(membrain,'store_connected_components')
        fprintf(script,' --store-connected-components');
    else
        fprintf(script,' --no-store-connected-components');
    end
    
    if sg_check_param(membrain,'connected_component_thres')
        fprintf(script,[' --connected-component-thres',num2str(membrain.connected_component_thres)]);
    end
    
    if sg_check_param(membrain,'test_time_augmentation')
        fprintf(script,' --test-time-augmentation');
    else
        fprintf(script,' --no-test-time-augmentation');
    end
    
    if sg_check_param(membrain,'segmentation_threshold')
        fprintf(script,[' --segmentation-threshold ',num2str(membrain.segmentation_threshold)]);
    end    
    
    if sg_check_param(membrain,'sliding_window_size')
        fprintf(script,[' --sliding-window-size ',num2str(membrain.sliding_window_size)]);
    end
    
    fprintf(script,'\n\n');  
    
end



% Close file
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running Membrain Segmentation...']);
system(script_name);



end


