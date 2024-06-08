function par = tomoman_archive(root_dir,paramfilename,par)
%% tomoman_archive
% A function to archive tomoman project. This function will creat a minimal
% tomoman project for archival or upload to databases such as EMPIAR. 
%
% Input comes from the tomoman_archive.param file.
%
% SK 09-2023

%%%% DEBUG
% paramfilename = 'tomoman_archive.param';


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
archive_fields = tm_get_archive_fields();
archive = tm_parse_param(archive_fields,param_cell);


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
% dep = tm_get_dependencies('imod',dep);              % IMOD
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);
    
    % Split tomolist
    [tomolist,p.tomolist_name,par] = tm_split_tomolist(tomolist,p.root_dir,p.tomolist_name,par);
    if isempty(tomolist)
        return
    end
    
end

%% Run pipeline!!!

% Generate subset motl
if ~isempty(archive.archive_list)
    subset = dlmread(archive.archive_list);
    sub_ndx = ismember([tomolist.tomo_num], subset');
    tomolist = tomolist(sub_ndx);
end

n_tilts = size(tomolist,2);
b_size = 1;
t = 1;


while all(t <= n_tilts)    
    
    % Archive
    tomolist(t) = tm_archive_tomogram(p,tomolist(t),archive,par);
    % Save tomolist
    if par_proc
        save([p.root_dir,p.tomolist_name],'tomolist');
    else
        save([archive.archive_dir,p.tomolist_name],'tomolist');
    end
    % Increment counter
    t = t+b_size;
end

% Write last task
if par_proc
    par.last_task = 'archive';
    par.archive_dir = archive.archive_dir;
end

% Close log
diary off

