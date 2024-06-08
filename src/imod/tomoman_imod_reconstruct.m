function par = tomoman_imod_reconstruct(root_dir,paramfilename,par)
%% tomoman_imod_reconstruct
% A function for batch reconstruction of tomograms in IMOD. Tomogram
% alignment can be performed with any software supported by TOMOMAN.
%
% WW 07-2023

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_imod_reconstruct.param';

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
imod_fields = tm_get_imod_recons_fields();
imod = tm_parse_param(imod_fields,param_cell);



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
    
    % Split tomolist
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);            

    
    % Override n_cores
    imod.n_cores = par.cpus_per_task;

    % Override GPU settings
    if isfield(par,'task_gpu')
        imod.gpu_id = par.task_gpu - 1; % Adjust GPU ID to start at 0
    end
    
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
% write_list = false;
t = 1;

while all(t <= n_tilts)
    
    % Run CTFFIND4
    tm_imod_reconstruct(tomolist(t), p, imod, dep);    
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end

% Write last task
if par_proc
    par.last_task = 'imod_reconstruct';
end

% Close log
diary off    




