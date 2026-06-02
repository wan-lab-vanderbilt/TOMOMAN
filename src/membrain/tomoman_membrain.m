function par = tomoman_membrain(root_dir,paramfilename,par)
%% tomoman_membrain
% A function for running the membrain to segment tomograms. 
%
% WW 06-2025

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_membrain_segment.param';
% par_proc = false;
% par = [];
% root_dir = sg_check_dir_slash(root_dir);

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
membrain_fields = tm_get_membrain_fields(task);
membrain = tm_parse_param(membrain_fields,param_cell);



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
dep = tm_get_dependencies(p,task,dep);              % IMOD_recons
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Override n_cores
    membrain.n_cores = par.cpus_per_task;

    % Override GPU settings
    if isfield(par,'task_gpu')
        membrain.gpu_id = par.task_gpu - 1; % Adjust GPU ID to start at 0
    end
    
end


%% Run membrain segmentation!!!

    
% Run IMOD reconstruction
tm_membrain_segment(tomolist, p, membrain, dep, par);
    

% Write last task
if par_proc
    par.last_task = 'imod_reconstruct';
end

% Close log
diary off    




