function par = tomoman_must(root_dir,paramfilename,par)
%% tomoman_must
% A function for running the tomogram reconstruction using MUST.  
%
% WW 08-2025

%%%% DEBUG
% root_dir = '/dors/wan_lab/home/wanw/research/HIV_testset/subset_from_scratch/tomo';
% paramfilename = 'tomoman_must_reconstruct.param';
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
must_fields = tm_get_must_fields();
must = tm_parse_param(must_fields,param_cell);



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
dep = tm_get_dependencies(p,'linux');                       % Basic linux commands
dep = tm_get_dependencies(p,'must_reconstruct',dep);        % MUST
tm_check_dependencies(dep,false);                           % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Override n_cores
    must.n_cores = par.cpus_per_task;

    % Override GPU settings
    if isfield(par,'task_gpu')
        must.gpu_id = par.task_gpu - 1; % Adjust GPU ID to start at 0
    end
    
end



%% Run MUST reconstruction!!!

n_tilts = size(tomolist,2);
b_size = 1;
% write_list = false;
t = 1;

while all(t <= n_tilts)
    
    % Run MUST reconstruction
    tm_must_reconstruct(tomolist(t), p, must, dep);    
    
    t = t+b_size;
    
end

% Write last task
if par_proc
    par.last_task = 'must_reconstruct';
end

% Close log
diary off    





