function par = tomoman_arctic(root_dir,paramfilename,par)
%% tomoman_arctic
% A function to run ARCTiC for automated cleaning of tilt-series.
%
% WW 07-225

%%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_arctic.param';
% par = [];


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




% Parse are-struct
arctic_fields = tm_get_arctic_fields();
arctic = tm_parse_param(arctic_fields,param_cell);

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


% Get dependencies
dep = tm_get_dependencies(p,'linux');               % Basic linux commands
dep = tm_get_dependencies(p,'arctic',dep);          % ARCTiC
tm_check_dependencies(dep,false);                   % Check dependencies

% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);



%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par,'arctic',arctic);
    if isempty(tomolist)
        par.last_task = 'arctic';
        return
    end
    
    % Override GPU settings
    arctic.Gpu = par.task_gpu - 1; % Adjust GPU ID to start at 0
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
    
    % Run ARCTiC
    tomolist(t) = tm_arctic(tomolist(t),p,arctic,dep,par);
    
    
    % Save tomolist
    tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
   
    
    t = t+b_size;
    
end

% Write last task
if par_proc
    par.last_task = 'arctic';
end

% Close log
diary off



