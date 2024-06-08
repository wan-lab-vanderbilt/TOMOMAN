function par = tomoman_dosefilter(root_dir,paramfilename,par)
%% tomoman_dosefilter
% A function to perform dose (i.e. exposure) filtering on image stacks.
% Filtering is based off the Unblur algorithm (Grant and Grigorieff, eLife
% (2015) and can be performed in frame-aligned image stacks or
% MotionCor2-aligned frame stacks. In the latter case, filtered frame
% stacks are summed and compiled into dose-filtered tilt stacks. 
%
% WW 05-2022

%%%% DEBUG
% paramfilename = 'tomoman_dosefilter.param';


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
df_fields = tm_get_dosefilter_fields();
df = tm_parse_param(df_fields,param_cell);

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
% dep = tm_get_dependencies(p,'dosefilter',dep);      % Clean stacks
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

%     % Maybe in the future...
%     % Override GPU settings
%     df.Gpu = par.task_gpu; % Adjust GPU ID to start at 0
end



%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
    
    % Dose filter
    tomolist(t) = tm_exposure_filter(tomolist(t),p,df,write_list);
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end


% Write last task
if par_proc
    par.last_task = 'dosefilter';
end

% Close log
diary off



