function tm_cryocare_predict(tomolist, p, cryocare, dep, par)
%% tm_cryocare_predict
% A function for taking a tomolist and running batched cryoCARE denoising
% using a pre-trained model.
%
% WW 07-2023


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

% Check for outp[ut directory for denoised tomograms
if ~exist([p.root_dir,cryocare.output_dir],'dir')
    system(['mkdir -p ',p.root_dir,cryocare.output_dir]);
end


%% Write prediction script
disp([p.name,'Writing script for denoising tomograms using cryoCARE...']);

% Determine tomograms to use
use_tomo = false(n_stacks,1);


% Generate list of tomograms to use
for i = 1:n_stacks
        
    % Check processing
    process = true;
    if tomolist(i).skip
        process = false;  
        disp([p.name,tomolist(i).stack_name,' has been set to skip... Moving on to next stack...']);
    end
            
    % Check subset_list
    if ~isempty(subset_list)
        if ~any(subset_list == tomolist(i).tomo_num)
            process = false;
            disp([p.name,tomolist(i).stack_name,' is not in the subset_list... Moving on to next stack...']);
        end
    end
    
    % Check if aligned
    if ~tm_check_if_aligned(tomolist(i))
        process = false;
        disp([p.name,tomolist(i).stack_name,' has not been aligned... Moving on to next stack...']);
    end
        
    % Add to list of tomograms
    use_tomo(i) = process;        

end

% Find tomograms to use
use_idx = find(use_tomo);
n_use = numel(use_idx);

% Parse prediction script name
if sg_check_param(par,'task_id')
    pscript_name = [p.root_dir,cryocare.cryocare_dir,'predict_config_',num2str(par.task_id),'.json'];
    temp_dir = ['temp_',num2str(par.task_id),'/'];
else
    pscript_name = [p.root_dir,cryocare.cryocare_dir,'predict_config.json'];
    temp_dir = 'temp/';
end

% Open predict .json
pscript = fopen(pscript_name,'w');
fprintf(pscript,'{\n');

% Write path
fprintf(pscript,['  "path": "',p.root_dir,cryocare.cryocare_dir,cryocare.model_name,'.tar.gz",\n']);


% Write path to even tomograms
fprintf(pscript,'  "even": [\n');
c = 1;  % Line counter
for i = 1:n_use
    name = parse_name(cryocare,tomolist(use_idx(i)));
    fprintf(pscript,['    "',p.root_dir,cryocare.tomo_dir,name,'_EVN.rec"']);
    if c < n_use
        fprintf(pscript,',\n');
    else
        fprintf(pscript,'\n');
    end
    c = c+1; % Increment coutner
end
fprintf(pscript,'  ],\n');

% Write path to odd tomograms
fprintf(pscript,'  "odd": [\n');
c = 1;  % Line counter
for i = 1:n_use
    name = parse_name(cryocare,tomolist(use_idx(i)));
    fprintf(pscript,['    "',p.root_dir,cryocare.tomo_dir,name,'_ODD.rec"']);
    if c < n_use
        fprintf(pscript,',\n');
    else
        fprintf(pscript,'\n');
    end
    c = c+1; % Increment coutner
end
fprintf(pscript,'  ],\n');


% Write n_tiles
fprintf(pscript,'  "n_tiles": [\n');
fprintf(pscript,['    ',num2str(cryocare.n_tiles(1)),',\n']);
fprintf(pscript,['    ',num2str(cryocare.n_tiles(2)),',\n']);
fprintf(pscript,['    ',num2str(cryocare.n_tiles(3)),'\n']);
fprintf(pscript,'  ],\n');

% Write output directory
fprintf(pscript,['  "output": "',p.root_dir,cryocare.output_dir,temp_dir,'",\n']);

% Write overwrite (Seems broken...)
if cryocare.overwrite
    fprintf(pscript,'  "ovewrite": "True",\n');
else
    fprintf(pscript,'  "ovewrite": "False",\n');
end

% Write GPU
fprintf(pscript,['  "gpu_id": [',regexprep(num2str(cryocare.gpu_id),'\s+',','),']\n']);
fprintf(pscript,'}\n');

% Close file
fclose(pscript);
system(['chmod +x ',pscript_name]);


%% Run prediction
disp([p.name,'Denoising tomograms using cryoCARE...']);


% Run predicting
system([dep.cryoCARE_predict,' --conf ',pscript_name]);


%% Cleanup
disp([p.name,'CryoCARE Denoising Complete!!!1! Finishing job...']);

% Move files
for i = 1:n_use
    
    % Names for temporary and final tomograms
    name = parse_name(cryocare,tomolist(use_idx(i)));
    temp_name = [name,'_EVN.rec'];
    final_name = [name,'_denoised.rec'];
    
    % Move and rename tomograms
    system(['mv ',p.root_dir,cryocare.output_dir,temp_dir,temp_name,' ',p.root_dir,cryocare.output_dir,final_name]);
    
    
end

% Remove temporary directory
system(['rmdir ',p.root_dir,cryocare.output_dir,temp_dir]);


end

function name = parse_name(cryocare,t)

% Check stack type
switch cryocare.process_stack
    case 'dose-filtered'
        [~,name,~] = fileparts(t.dose_filtered_stack_name);
    case 'unfiltered'
        [~,name,~] = fileparts(t.stack_name);
end

end
