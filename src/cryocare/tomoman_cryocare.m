function par = tomoman_cryocare(root_dir,paramfilename,par)
%% tomoman_cryocare
% A function to streamline tomogram denoising using cryoCARE using the
% odd/even tomogram-2-tomogram (T2T) apprach. This requires three different
% subfunctions:
%
% 1. Odd/Even tomogram reconstruction. This function is used to reconstruct
% tomograms from the tilt series generated from the odd and even frames. A
% prerequisite for this is the generation of odd and even tilt series
% during frame alignment. Reconstruction is performed using WBP in IMOD.
% This uses a 'tomoman_cryocare_oe_recons' parameter file. 
%
% 2. CryoCARE Training. This involves extracting subvolumes for training
% and the actual training step. This can be performed using a subset of the
% tomograms in the tomolist by providing an input text file containig the
% tomo_num's to use. This uses a 'tomoman_cryocare_train' parameter file.
%
% 3. CryoCARE Predicition. This is for denoising tomograms using a
% precalculated training file. This can either be performed on the full
% dataset or a subset. This uses a 'tomoman_cryocare_predict' parameter
% file.
%
% WW 06-2023

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_cryocare_predict.param';

%% Check check

% Check for parallel processing
par_proc = false;
if nargin == 3
    if ~isempty(par)
        par_proc = true;        
    end
else
    par = [];
end

% Check root_dir
root_dir = sg_check_dir_slash(root_dir);

%% Read inputs

% Parse task from paramfile
task = tm_parse_tasks([root_dir,paramfilename]);

% Read param
param_cell = tm_read_paramfile([root_dir,paramfilename]);

% Parse p-struct
p_fields = tm_get_basic_p();
p = tm_parse_param(p_fields,param_cell);

% Overrides for parallel processing
if par_proc    
    p.root_dir = par.root_dir;              % Root directory
end



% Parse cryocare struct
cryocare_fields = tm_get_cryocare_fields(task);
cryocare = tm_parse_param(cryocare_fields,param_cell);



% Parse node name
if par_proc
    p.name = par.name;
else
    p.name = 'TOMOMAN: ';
end



%% Initalize

% Open log
if ~par_proc
    diary([p.root_dir,p.log_name]);
else
    diary([p.root_dir,p.log_name,'_',num2str(par.task_id)]);
end
disp([p.name,' Initializing!!!']);


% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);


% Get dependencies
dep = tm_get_dependencies(p,'linux');               % Basic linux commands
dep = tm_get_dependencies(p,task,dep);              % cryoCARE
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    switch task
        case {'cryocare_oe_recons','cryocare_predict'}
            [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);            
    end
    if isempty(tomolist)
        return
    end
    
    % Override n_cores
    if strcmp(task,'cryocare_oe_recons')
        cryocare.n_cores = par.cpus_per_task;
    end

    % Override GPU settings
    cryocare.gpu_id = par.task_gpu - 1; % Adjust GPU ID to start at 0
    
end


%% Run pipeline!!!


    
switch task
    case 'cryocare_oe_recons'                        
        % Reconstruct odd/even tomograms
        tm_cryocare_oe_recons(tomolist, p, cryocare, dep);

    case 'cryocare_train'

        % Check if this is a processing node
        if ~par_proc
            proc = true;
        elseif par.task_id == 1
            proc = true;
        else
            proc = false;
        end

        % Run process or wait
        if proc
            % Extract training data and perform training
            tm_cryocare_train(tomolist, p, cryocare, dep);

            % Write comm file
            if par_proc
                system(['touch ',par.comm_dir,'tomoman_cryocare_train']);
            end
        else
            % Wait for sorting to finish
            disp([p.name,'Waiting for cleaning to finish...']);
            tm_wait_for_it(par.comm_dir,'tomoman_cryocare_train',10);  
        end

    case 'cryocare_predict'
        % Perform denoising 
        tm_cryocare_predict(tomolist, p, cryocare, dep, par);

end    
    



% Write last task
if par_proc
    par.last_task = task;
end

% Close log
diary off


