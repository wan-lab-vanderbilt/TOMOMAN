function par = tomoman_relion_motioncorr(root_dir,paramfilename,par)
%% tomoman_relion_motioncorr
% A function to take a tomolist and parameter file to run relion's
% implementation of motioncor. This is particularly useful when processing
% .eer formatted frames.
%
% Input comes from the tomoman_relion_motioncorr.param file.
%
% WW 05-2022

%%%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_relion_motioncorr.param';



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



% Parse ov-struct
[rmc_fields, a_fields] = tm_get_relionmc_fields();
relionmc = tm_parse_param(rmc_fields,param_cell);
a = tm_parse_param(a_fields,param_cell);


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
dep = tm_get_dependencies(p,'relionmc');      % Relion MotionCor2
dep = tm_get_dependencies(p,'linux',dep);     % Basic linux commands
tm_check_dependencies(dep,false);           % Check dependencies


% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);


%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);
    if isempty(tomolist)
        return
    end

    relionmc.n_cores = par.cpus_per_task;

    
end



%% Run pipeline!!!

% Number of tomograms
n_tomos = numel(tomolist);
write_list = false;

for t = 1:n_tomos
    
    % Align frames and generate stack
    tomolist(t) = tm_relion_motioncorr_newstack(tomolist(t),p,a,relionmc,dep,write_list,par);
    
    % Write tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');

    
    
end

% Write last task
if par_proc
    par.last_task = 'relion_motioncorr';
end

% Close log
diary off

