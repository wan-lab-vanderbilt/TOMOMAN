function tm_isonet_train(tomolist, p, isonet, dep, par)
%% tm_isonet_train
% A function for taking a tomolist IsoNet parameters to optionally extract
% subtomograms and train/refine an IsoNet network. 
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
subtomo_dir = [isonet_dir,isonet.subtomo_folder];
result_dir = [p.root_dir,isonet.isonet_dir,isonet.result_dir];
if exist(result_dir,'dir')
    if ~sg_check_param(isonet,'pretrained_model') && ~sg_check_param(isonet,'continue_from') 
        disp([p.name,'Previous result_dir detected... Deleting old directory...']);
        system(['rm -rf ',result_dir]);
    end
end


% Parse star names
tomo_star_name = [p.root_dir,isonet.isonet_dir,isonet.star_filename];
subtomo_star_name = [p.root_dir,isonet.isonet_dir,isonet.subtomo_star];
    
% Parse tomograms to process
proc_tomo_num = [tomolist(~[tomolist.skip] & tm_check_if_aligned(tomolist)).tomo_num];    % Parse tomo_num for non-skipped
if ~isempty(subset_list)
    proc_tomo_num = intersect(proc_tomo_num,subset_list);
end

% % Parse indices
% [~,proc_idx,~] = intersect([tomolist.tomo_num],proc_tomo_num);   % In case tomo_num doesn't match index in tomolist

% For boolean outputs
bool_string = {'false', 'true'};



%% Write bash file and preprocess for each tomogram

disp([p.name,'Preparing scripts for IsoNet training...']);

% Parse star file name
script_name = [p.root_dir,isonet.isonet_dir,'run_isonet_train.sh'];

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Running IsoNet Training #####"','\n\n\n']);

% Run extraction
if isonet.run_extract
    fprintf(script,['echo "##### Run Extraction #####"','\n']);
    fprintf(script,[dep.isonet,' extract ',tomo_star_name]);
    fprintf(script,[' --use_deconv_tomo ',bool_string{isonet.use_deconv_tomo+1}]);
    fprintf(script,[' --subtomo_star ',subtomo_star_name]);
    fprintf(script,[' --subtomo_folder ',subtomo_dir]);
    if sg_check_param(isonet,'cube_size')
        fprintf(script,[' --cube_size ',num2str(isonet.cube_size)]);
    end
    if sg_check_param(isonet,'crop_size')
        fprintf(script,[' --crop_size ',num2str(isonet.crop_size)]);       
    end
    if ~isempty(subset_list)
        fprintf(script,[' --tomo_idx ',char(strjoin(string(proc_tomo_num), ','))]);
    end
    fprintf(script,'\n\n');           
end

% Run training
fprintf(script,['echo "##### Run IsoNet Refine #####"','\n']);
fprintf(script,[dep.isonet,' refine ',subtomo_star_name]);
fprintf(script,[' --iterations ',num2str(isonet.iterations)]);
fprintf(script,[' --result_dir ',result_dir]);
if sg_check_param(isonet,'gpuID')
    fprintf(script,[' --gpuID ',char(strjoin(string(isonet.gpuID), ','))]);
end
if sg_check_param(isonet,'noise_level')
    fprintf(script,[' --noise_level ',char(strjoin(string(isonet.noise_level), ','))]);
end
if sg_check_param(isonet,'noise_start_iter')
    fprintf(script,[' --noise_start_iter ',char(strjoin(string(isonet.noise_start_iter), ','))]);
end
if sg_check_param(isonet,'remove_intermediate')
    fprintf(script,[' --remove_intermediate ',bool_string{isonet.remove_intermediate+1}]);
end
if sg_check_param(isonet,'pretrained_model')
    fprintf(script,[' --pretrained_model ',isonet.pretrained_model]);
end
if sg_check_param(isonet,'continue_from')
    fprintf(script,[' --continue_from ',isonet.continue_from]);
end
fprintf(script,'\n\n');



% Close file
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet training...']);
system(script_name);



end


