function bad_tilts = tm_run_arctic(tomolist,arctic, dep)
%% tm_run_arctic
% Generate a bash script and run ARCTiC. After completion, read the .csv
% results file and parse and return the indices of the removed tilts. 
%
% WW 08-2025


%% Parse parameters

% Check for ARCTiC subfolder
stack_dir = tm_check_absolute_path(tomolist.root_dir,tomolist.stack_dir);
arctic_dir = [stack_dir,'arctic/'];
if ~exist(arctic_dir,'dir')
    system(['mkdir ',arctic_dir]);
end

% Parse cleaned stack name
[~,st_name,st_ext] = fileparts(tomolist.stack_name);    % Parse stack name (ARCTiC doesn't allow .st as output extension...
clean_name = [st_name,arctic.clean_append,'.mrc'];

% Parse model path
model_path = tm_check_absolute_path(tomolist.root_dir,arctic.model);

%% Run ARCTiC

% Open run script
arctic_script = [arctic_dir,'run_arctic.sh'];
fid = fopen(arctic_script,'w');

% Write initial lines
fprintf(fid,['#!/bin/bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(fid,['export CUDA_VISIBLE_DEVICES=',char(strjoin(string(arctic.gpu_id), ',')),'\n\n']);
fprintf(fid,['echo "##### Run ARCTiC on ',tomolist.stack_name,' #####"','\n\n']);

% In case of overwrite, backup previous stack like IMOD
if isempty(arctic.clean_append)
    stack_name = [tomolist.stack_name,'~'];
    system(['mv ',stack_dir,tomolist.stack_name,' ',stack_dir,stack_name]);
    system(['ln -s ',stack_dir,stack_name,' ',stack_dir,tomolist.stack_name]);
end

% Print parameters
fprintf(fid,dep.arctic);
fprintf(fid,[' --input_ts ''',stack_dir,tomolist.stack_name,'''']);
fprintf(fid,[' --cleaned_ts ''',stack_dir,clean_name,'''']);
fprintf(fid,[' --angle_start ',num2str(min(tomolist.rawtlt))]);
fprintf(fid,[' --angle_step ',num2str(arctic.angle_step)]);
fprintf(fid,[' --model ',model_path]);
fprintf(fid,[' --pdf_output ',arctic_dir,'output_visualization.pdf']);
fprintf(fid,[' --csv_output ',arctic_dir,'classification_results.csv \n\n']);

% Check extension
if ~strcmp(st_ext,'.mrc')
    fprintf(fid,['mv ',stack_dir,clean_name,' ',stack_dir,st_name,arctic.clean_append,st_ext]);
end
    

% Close file
fclose(fid);

% Make executable
system(['chmod +x ',arctic_script]);

% Run file
system(arctic_script);


%% Return bad tilts

% Read .csv output
fid = fopen([arctic_dir,'classification_results.csv']);
cell_array = textscan(fid, '%s', 'Delimiter', ',');
csv = reshape(cell_array{1},3,[])';
fclose(fid);

% Parse removed tilts
n_tilts = size(csv,1)-1;
removed_idx = false(n_tilts,1);
for i = 1:n_tilts
    removed_idx(i) = strcmpi('true',csv{i+1,2});
end

% Parse and sort tilts currently in stack
% tilts = setdiff(tomolist.collected_tilts,tomolist(i).removed_tilts);
% bad_tilts = tilts(removed_idx);
bad_tilts = find(removed_idx);

