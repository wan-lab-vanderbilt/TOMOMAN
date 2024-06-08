function par = tomoman_tiltctf(root_dir,paramfilename,par)
%% tomoman_tiltctf
% A function to run tiltctf and CTFFIND4. Tiltctf is an algorithm for
% generating more coherent powerspectra from tilted images via stretching
% with respect to defocus offset. Defocus is estimated from these spectra
% using CTFFIND4.
%
% Input comes from the tomoman_tiltctf.param file.
%
% SK, WW 06-2022

% %%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_tiltctf.param';
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



% Parse tctf-struct
tctf_fields = tm_get_tiltctf_fields();
tctf = tm_parse_param(tctf_fields,param_cell);

% Parse ctffind4-struct
ctffind4_fields = tm_get_ctffind4_fields();
ctffind4 = tm_parse_param(ctffind4_fields,param_cell);

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
dep = tm_get_dependencies(p,'tiltctf',dep);          % CTFFIND4
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
    
%     % Override GPU settings
%     tctf.Gpu = par.task_gpu; 
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
    
    % Run tiltctf    
    tomolist(t) = tm_tiltctf_ctffind4(tomolist(t),p,tctf,ctffind4,dep,write_list);
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end

% Write last task
if par_proc
    par.last_task = 'tiltctf';
end

% Close log
diary off




