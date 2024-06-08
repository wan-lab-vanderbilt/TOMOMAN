function tm_cryocare_train(tomolist, p, cryocare, dep)
%% tm_cryocare_train
% A function for taking a tomolist and running cryoCARE training. All
% tomograms in the tomolist can be used or a subset of particles can be
% suppplied. 
%
% NOTE: This is not a parallel process; all computations must occur on one
% node. 
%
% WW 06-2023


%% Initialize
disp([p.name,'Preparing to perform cryoCARE training...']);

% Number of stacks
n_stacks = numel(tomolist);

% Check for subset_list
if sg_check_param(cryocare,'subset_list')
    subset_list = dlmread([p.root_dir,cryocare.subset_list]);
else
    subset_list = [];
end

% Check for cryocare directory
if ~exist([p.root_dir,cryocare.cryocare_dir],'dir')
    system(['mkdir -p ',p.root_dir,cryocare.cryocare_dir]);
end


%% Write extraction script
disp([p.name,'Writing script for extracting cryoCARE training data...']);

% Determine tomograms to use
use_tomo = false(n_stacks,1);


% Generate list of tomograms to use
for i = 1:n_stacks
        
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;        
    end
            
    % Check recons_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
        end
    end
        
    % Add to list of tomograms
    use_tomo(i) = process;        

end

% Find tomograms to use
use_idx = find(use_tomo);
n_use = numel(use_idx);

% Open extract .json
exscript_name = [p.root_dir,cryocare.cryocare_dir,'train_data_config.json'];
exscript = fopen(exscript_name,'w');
fprintf(exscript,'{\n');

% Write path to even tomograms
fprintf(exscript,'  "even": [\n');
c = 1;  % Line counter
for i = 1:n_use
    fprintf(exscript,['    "',p.root_dir,cryocare.tomo_dir,num2str(tomolist(use_idx(i)).tomo_num),'_EVN.rec"']);
    if c < n_use
        fprintf(exscript,',\n');
    else
        fprintf(exscript,'\n');
    end
    c = c+1; % Increment coutner
end
fprintf(exscript,'  ],\n');

% Write path to odd tomograms
fprintf(exscript,'  "odd": [\n');
c = 1;  % Line counter
for i = 1:n_use
    fprintf(exscript,['    "',p.root_dir,cryocare.tomo_dir,num2str(tomolist(use_idx(i)).tomo_num),'_ODD.rec"']);
    if c < n_use
        fprintf(exscript,',\n');
    else
        fprintf(exscript,'\n');
    end
    c = c+1; % Increment coutner
end
fprintf(exscript,'  ],\n');



% Write patch shape
fprintf(exscript,'  "patch_shape": [\n');
fprintf(exscript,['    ',num2str(cryocare.patch_shape(1)),',\n']);
fprintf(exscript,['    ',num2str(cryocare.patch_shape(2)),',\n']);
fprintf(exscript,['    ',num2str(cryocare.patch_shape(3)),'\n']);
fprintf(exscript,'  ],\n');

% Write remaining lines
fprintf(exscript,['  "num_slices": ',num2str(cryocare.num_slices),',\n']);
fprintf(exscript,['  "split": ',num2str(0.9),',\n']);   % Parameter not described in documentation...
fprintf(exscript,['  "tilt_axis": "','Y','",\n']);             % Locked to IMOD covention
fprintf(exscript,['  "n_normalization_samples": ',num2str(cryocare.n_normalization_samples),',\n']);
fprintf(exscript,['  "path": "',p.root_dir,cryocare.cryocare_dir,cryocare.model_name,'/"\n']);
fprintf(exscript,'}\n');

% Close file
fclose(exscript);
system(['chmod +x ',exscript_name]);


%% Write training script
disp([p.name,'Writing script for cryoCARE training...']);

% Open training .json
tscript_name = [p.root_dir,cryocare.cryocare_dir,'train_config.json'];
tscript = fopen(tscript_name,'w');

% Write lines
fprintf(tscript,'{\n');
fprintf(tscript,['  "train_data": "',p.root_dir,cryocare.cryocare_dir,cryocare.model_name,'/",\n']); 
fprintf(tscript,['  "epochs": ',num2str(cryocare.epochs),',\n']);
fprintf(tscript,['  "steps_per_epoch": ',num2str(cryocare.steps_per_epoch),',\n']);
fprintf(tscript,['  "batch_size": ',num2str(cryocare.batch_size),',\n']);
fprintf(tscript,['  "unet_kern_size": ',num2str(cryocare.unet_kern_size),',\n']);
fprintf(tscript,['  "unet_n_depth": ',num2str(cryocare.unet_n_depth),',\n']);
fprintf(tscript,['  "unet_n_first": ',num2str(cryocare.unet_n_first),',\n']);
fprintf(tscript,['  "learning_rate": ',num2str(cryocare.learning_rate),',\n']);
fprintf(tscript,['  "model_name": "',cryocare.model_name,'",\n']);
fprintf(tscript,['  "path": "',p.root_dir,cryocare.cryocare_dir,'",\n']);
fprintf(tscript,['  "gpu_id": [',regexprep(num2str(cryocare.gpu_id),'\s+',','),']\n']);
fprintf(tscript,'}\n');

% Close file
fclose(tscript);
system(['chmod +x ',tscript_name]);


%% Run CryoCARE Training

% Run extraction
disp([p.name,'Extracting cryoCARE training data...']);
system([dep.cryoCARE_extract_train_data,' --conf ',p.root_dir,cryocare.cryocare_dir,'train_data_config.json']);


% Run training
disp([p.name,'Running cryoCARE training...']);
system([dep.cryoCARE_train,' --conf ',p.root_dir,cryocare.cryocare_dir,'train_config.json']);





