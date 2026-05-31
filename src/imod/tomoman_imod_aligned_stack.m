function par = tomoman_imod_aligned_stack(root_dir,paramfilename,par)
%% tomoman_imod_aligned_stack
% A function for batch generation of aligned stacks. While IMOD is used to
% generate the aligned stack, the alignment can be performed with any
% supported TOMOMAN task.
%
% WW 10-2025

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_imod_aligned_stack.param';

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
imod_fields = tm_get_imod_aligned_stack_fields();
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
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par,'imod_reconstruct',imod);            
    
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
% write_list = false;
t = 1;

while all(t <= n_tilts)
    
    % Run IMOD reconstruction
    tm_imod_aligned_stack(tomolist(t), p, imod);    
    
%     % Save tomolist
%     tm_save_tomolist(p.root_dir,p.tomolist_name,tomolist);
    
    t = t+b_size;
    
end

% Write last task
if par_proc
    par.last_task = 'imod_reconstruct';
end

% Close log
diary off    




