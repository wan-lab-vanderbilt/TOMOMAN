function par = tomoman_novactf(root_dir,paramfilename,par)
%% tomoman_novactf
% A function to reconstruct tomograms using NovaCTF. This uses the
% alignment parameters from the alignment_software and the CTF parameters
% from the ctf_determination_algorithm in the tomolist.
%
% Input comes from the tomoman_imod_preprocess.param file.
%
% Parallel processing of the stacks is run using MPI. The MPI command is
% set in the tm_get_dependencies function.
%
% WW 07-2022

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_novactf.param';


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



% Parse novactf struct
novactf_fields = tm_get_novactf_fields();
novactf = tm_parse_param(novactf_fields,param_cell);


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
dep = tm_get_dependencies(p,'linux');                 % Basic linux commands
dep = tm_get_dependencies(p,'novactf',dep);           % NovaCTF
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);
    if isempty(tomolist)
        par = tm_check_last_task(par_proc,par,'novactf');
        return
    end
    
    % Override n_cores
    novactf.n_cores = par.cpus_per_task;

end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
    
    % Run CTFFIND4
    tomolist(t) = tm_novactf(tomolist(t), p, novactf, dep, write_list);
    
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end


% Write last task
if par_proc
    par.last_task = 'novactf';
end


% Close log
diary off


