function tm_isonet_prepare(tomolist, p, isonet, dep, par)
%% tm_isonet_prepare
% A function for taking a tomolist IsoNet parameters to prepare an IsoNet
% star file and optionally run deconvolution and mask generation.
%
% WW 06-2025


%% Initialize
disp([p.name,'Preparing tomograms for IsoNet processing!!!1!']);


% Check for subset_list
if sg_check_param(isonet,'subset_list')
    subset_list = dlmread([p.root_dir,isonet.subset_list]);
else
    subset_list = [];
end

% Check directories
isonet_dir = [p.root_dir,isonet.isonet_dir];
if ~exist(isonet_dir,'dir')
    mkdir(isonet_dir);
end
if isonet.run_deconv
    if ~exist([isonet_dir,isonet.deconv_dir],'dir')
        mkdir([isonet_dir,isonet.deconv_dir]);
    end
end
if isonet.make_masks
    if ~exist([isonet_dir,isonet.mask_dir],'dir')
        mkdir([isonet_dir,isonet.mask_dir]);
    end
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

% For boolean outputs
bool_string = {'false', 'true'};

%% Write inital star file
disp([p.name,'Preparing .star files for IsoNet processing...']);

% Parse star file name
if isempty(par)    
    star_name = [p.root_dir,isonet.isonet_dir,isonet.output_star];
else
    star_name = [p.root_dir,isonet.isonet_dir,isonet.output_star,'_',num2str(par.task_id)];
end

% Write starfile
tm_isonet_initialize_star(p,tomolist(proc_idx),isonet,star_name);

% % Concatenate parallel star files
% if ~isempty(par)
%    tm_isonet_cat_star_files(p,isonet,par); 
% end

%% Write bash file and preprocess for each tomogram

% Check for assigned jobs
if isempty(proc_idx)
    disp([p.name,'No tomograms assigned to this task...']);
    return
end


disp([p.name,'Preparing scripts for IsoNet pre-processing...']);

% Parse star file name
if isempty(par)    
    script_name = [p.root_dir,isonet.isonet_dir,'run_isonet_prepare.sh'];
else
    script_name = [p.root_dir,isonet.isonet_dir,'run_isonet_prepare.sh_',num2str(par.task_id)];
end

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Preparing Tomograms for IsoNet Processing #####"','\n\n\n']);

% Generate and move to temp dir
if ~isempty(par)
    temp_dir = [p.root_dir,isonet.isonet_dir,'temp_',num2str(par.task_id),'/'];
else
    temp_dir = [p.root_dir,isonet.isonet_dir,'temp/'];
end
fprintf(script,['mkdir -p ',temp_dir,'\n']);        % This is a hack because there is no temporary directory input. If this isn't here, parallel processing fails.
fprintf(script,['cd ',temp_dir,'\n']);


% Run deconvolution
if isonet.run_deconv
    fprintf(script,['echo "##### Run Decovolution #####"','\n']);
    fprintf(script,[dep.isonet,' deconv ',star_name]);
    if sg_check_param(isonet,'snrfalloff')
        fprintf(script,[' --snrfalloff ',num2str(isonet.snrfalloff)]);
    end
    if sg_check_param(isonet,'deconvstrength')
        fprintf(script,[' --deconvstrength ',num2str(isonet.deconvstrength)]);
    end
    if sg_check_param(isonet,'highpassnyquist')
        fprintf(script,[' --highpassnyquist ',num2str(isonet.highpassnyquist)]);
    end
    if sg_check_param(isonet,'n_cores')
        fprintf(script,[' --ncpu ',num2str(isonet.n_cores)]);
    end
    if ~isempty(subset_list)
        fprintf(script,[' --tomo_idx ',char(strjoin(string(subset_list), ','))]);
    end
    fprintf(script,[' --deconv_folder ',isonet_dir,isonet.deconv_dir,'\n\n']);
end

% Make masks
if isonet.make_masks
     fprintf(script,['echo "##### Make Masks #####"','\n']);
    fprintf(script,[dep.isonet,' make_mask ',star_name]);
    if sg_check_param(isonet,'density_percentage')
        fprintf(script,[' --density_percentage ',num2str(isonet.density_percentage)]);
    end
    if sg_check_param(isonet,'std_percentage')
        fprintf(script,[' --std_percentage ',num2str(isonet.std_percentage)]);
    end
    if sg_check_param(isonet,'use_deconv_tomo')
        fprintf(script,[' --use_deconv_tomo ',bool_string{isonet.use_deconv_tomo+1}]);
    end
    if sg_check_param(isonet,'z_crop')
        fprintf(script,[' --z_crop ',num2str(isonet.z_crop)]);
    end
    if ~isempty(subset_list)
        fprintf(script,[' --tomo_idx ',char(strjoin(string(subset_list), ','))]);
    end
    fprintf(script,[' --mask_folder ',isonet_dir,isonet.mask_dir,'\n\n']);
end


% Cleanup
fprintf(script,['cd ',p.root_dir,'\n']);
fprintf(script,['rm -rf ',temp_dir,'\n']);

% Close file
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet pre-processing...']);
system(script_name);

% Concatenate parallel star files
if ~isempty(par)
    
    % Write completed com
    system(['touch ',par.comm_dir,'tomoman_isonet_prepare_',num2str(par.task_id)]);
    
    % Run process or wait
    if par.task_id == 1
        % Wait for parallel jobs
        disp([par.name,'Waiting for all tasks to finish...']);
        tm_wait_for_them(par.comm_dir,'tomoman_isonet_prepare',par.n_tasks,5);
        
        % Assemble star files
        disp([par.name,'All parallel star files written!!! Assembling full star file...']);
        tm_isonet_cat_star_files(p,isonet,par); 
        
        % Write completion file
        system(['touch ',par.comm_dir,'tomoman_isonet_prepare_star']);
    else
        % Wait for sorting to finish
        disp([p.name,'Waiting for full star files...']);
        tm_wait_for_it(par.comm_dir,'tomoman_isonet_prepare_star',5);  
    end
    
   
end                


end


