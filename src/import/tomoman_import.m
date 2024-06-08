function par = tomoman_import(root_dir,paramfilename,par)
%% tomoman_import
% A function to check the raw_stack_dir for new stacks and .mdoc files, and
% generate symlinks for them, along with their frames, to new tilt-stack 
% directories. If no prior tomolist exists, a new one will also be 
% generated and filled.
%
% Input comes from the tomoman_sortnew.param file.
%
% WW 05-2022

% % % % % % DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_import.param';
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
p_fields = tm_get_import_p();
p = tm_parse_param(p_fields,param_cell);

% Overrides for parallel processing
if par_proc    
    p.root_dir = par.root_dir;              % Root directory
end


% Parse ov-struct
ov_fields = tm_get_import_ov();
ov = tm_parse_param(ov_fields,param_cell);

% Parse s-struct
s_fields = tm_get_import_s();
s = tm_parse_param(s_fields,param_cell);

% Parse node name
if par_proc
    p.name = par.name;
else
    p.name = 'TOMOMAN: ';
end


%% Check parameters

% Check OS
if ~any(strcmp(p.os,{'windows','linux'}))
    error('ACHTUNG!!! Invalid p.os parameter!!! Only "windows" and "linux" supported!!!');
end

% % Check for gainref
% if strcmp(p.gainref, 'AUTO')        
%   p = tomoman_autocheck_gainref(p);               
% end


%% Initalize


% Open log
if ~par_proc
    diary([p.root_dir,p.log_name]);
else
    diary([p.root_dir,p.log_name,'_',num2str(par.task_id)]);
end
disp([p.name,'Initializing!!!']);


% Read tomolist
tomolist = tm_read_tomolist(p.root_dir,p.tomolist_name);

%% Sort new stacks
 
% Check for processing task
proc = true;
if par_proc
    if par.task_id ~= 1
        proc = false;
    end
end

% Sort new stacks
if proc
    % Sort stacks
    tomolist = tm_import_new_stacks(p,ov,s,tomolist,par);
    % Write tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
else
    % Wait for sorting to finish
    disp([p.name,'Waiting for sorting to finish...']);
    tm_wait_for_it(par.comm_dir,'tomoman_import',40); 
end


% Write last task
if par_proc
    par.last_task = 'import';
    par.orig_tomolist_name = p.tomolist_name;
end

% Close log
diary off

 

end


