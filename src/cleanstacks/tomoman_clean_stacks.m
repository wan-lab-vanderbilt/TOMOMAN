function par = tomoman_clean_stacks(root_dir,paramfilename,par)
%% tomoman_clean_stacks
% A function to aid in removing bad images from tilts. The function loops
% through the tomolist, opens each tilt stack in 3dmod, and asks for which
% tilts to be removed. It then generates a new stack with the bad tilts
% removed.
%
% Input comes from the tomoman_relion_motioncor.param file.
%
% WW 05-2022

%%%% DEBUG
% root_dir = pwd;
% paramfilename = 'tomoman_clean_stacks.param';


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
c_fields = tm_get_clean_stacks_fields();
c = tm_parse_param(c_fields,param_cell);


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
dep = tm_get_dependencies(p,'clean_stacks',dep);      % Clean stacks
tm_check_dependencies(dep,false);                   % Check dependencies


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;

% Check for processing task
proc = true;
if par_proc
    if par.task_id ~= 1
       proc = false;           
    end
end

if proc
    while all(t <= n_tilts)

        % Clean stacks
        tomolist(t) = tm_clean_stacks(tomolist(t),p,c,dep,par);     

        % Save tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');     

        t = t+b_size;

    end
else
    % Wait for sorting to finish
    disp([p.name,'Waiting for cleaning to finish...']);
    tm_wait_for_it(par.comm_dir,'tomoman_clean_stacks',10);  
end


% Write last task
if par_proc
    par.last_task = 'clean_stacks';
end

% Close log
diary off

 


