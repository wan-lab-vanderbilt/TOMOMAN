function tm_isonet2_refine_train(p, isonet2, isonet2_fields, dep)
%% tm_isonet2_refine_train
% Run isonet2 refine training. 
%
% WW 02-2026


%% Initialize
disp([p.name,'Preparing tomograms for IsoNet2 Refine Training!!!1!']);


% Check directories
isonet2_dir = [p.root_dir,isonet2.isonet2_dir];
training_dir = [isonet2_dir,isonet2.refine_training_subdir];
if exist(training_dir,'dir')
    if ~sg_check_param(isonet2,'continue_training') 
        disp([p.name,'Previous result_dir detected... Deleting old directory...']);
        system(['rm -rf ',training_dir]);
        mkdir(training_dir);
        
    else
        % Find latest model
        model_dir = dir([training_dir,'*.pt']);
        [~,model_idx] = sort([model_dir.datenum]);
        model_name = [training_dir,model_dir(model_idx(end)).name];
    end
else
    mkdir(training_dir);
end

% Parse star names
star_filename = [isonet2_dir,isonet2.star_filename];
training_star_filename = [isonet2_dir,'refine_training.star'];

% Check for subset_list
if sg_check_param(isonet2,'training_subset_list')
    % Read subset list
    subset_list = dlmread([p.root_dir,isonet2.training_subset_list]);
    
    % Read start file
    star = stopgap_star_read(star_filename);
    
    % Pares index
    [~,subset_idx,~] = intersect([star.rlnIndex],subset_list);
    
    % Write star
    stopgap_star_write(star(subset_idx),training_star_filename,'isonet2',[],4);
    
else
    % Copy starfile
    system(['cp ',star_filename,' ',training_star_filename]);
end


% For boolean outputs
bool_string = {'False', 'True'};


%% Run training

% Initialize training runscript
script_name = [isonet2_dir,'run_refine_training.sh'];
log_name = [isonet2_dir,'refine_training.log'];

% Open reconstruction script
script = fopen(script_name,'w');

% Write initial lines
fprintf(script,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(script,['echo "##### Running IsoNet2 RSefine Training #####"','\n\n\n']);

% Write script
fprintf(script,[dep.isonet2,' refine ',training_star_filename]);
fprintf(script,[' --ncpus ',num2str(isonet2.ncpus)]);
fprintf(script,[' --gpuID ',regexprep(num2str(isonet2.gpuID),'\s+',',')]);
fprintf(script,[' --output_dir ',training_dir]);

% Check for continued training
if sg_check_param(isonet2,'continue_training')
    fprintf(script,[' --pretrained_model ',model_name]);
end

% Fill remaining parameters
for i = 12:size(isonet2_fields,1)
    % Skip empty field
    if isempty(isonet2.(isonet2_fields{i,1}))
        continue
    end
    
    % Write field
    if strcmp(isonet2_fields{i,2},'boo')
        fprintf(script,[' --',isonet2_fields{i,1},' ',bool_string{isonet2.(isonet2_fields{i,1})+1}]);
    else
        fprintf(script,[' --',isonet2_fields{i,1},' ',isonet2.(isonet2_fields{i,1})]);
    end
    
end

% Append log output
fprintf(script,[' > ',log_name]);

% Close script
fclose(script);

% Make executable
system(['chmod +x ',script_name]);

% Run file
disp([p.name,'Running IsoNet2 Refine training...']);
system(script_name);









    



