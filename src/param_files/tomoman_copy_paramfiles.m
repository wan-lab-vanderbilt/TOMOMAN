function tomoman_copy_paramfiles(root_dir, tomolist_name, log_name, varargin)
%% tomoman_copy_paramfiles
% A function to copy TOMOMAN parameter files to target root directory. If
% tomolist_name and log_name are provided, they will be updated in all
% .param files. Additional optional inputs include which tasks for copy
% .param files for; if no tasks are given, all files will be copied.
%
% WW 06-2022


%% Check inputs

% Check for root_dir
if nargin < 1
    error('TOMOMAN: Achtung!!! You need to at least give an input root_dir!!!');
end

% Check root_dir
root_dir = sg_check_dir_slash(root_dir);

% Check for tomolist_name
if (nargin < 2) || isempty(tomolist_name)
    warning('TOMOMAN: Using default tomolist_name: tomolist.mat');
    tomolist_name = 'tomolist.mat';
end

% Check for log_name
if (nargin < 3) || isempty(log_name)
    warning('TOMOMAN: Using default log_name: tomoman.log');
    log_name = 'tomoman.log';
end
    
% Get task list
tasks = tm_get_tasks();

% Check which tasks to copy
if (nargin < 4) || isempty(varargin)
    cp_tasks = tasks(2:end);   % Skip pipeline
    
else
    
    % Check for invalid tasks
    diff = setdiff(varargin,tasks);
    if ~isempty(diff)
        error(['TOMOMAN: Achtung!!! The following input tasks are invalid: ',sprintf('\n%s',diff{:})]);
    end
    
    % Make list of tasks
    cp_tasks = intersect(tasks,varargin);
    
end
        
% Parse script directory
[path,~,~] = fileparts(which('tomoman_copy_paramfiles'));   % Directory is same as this function.
        
%% Copy files



for i = 1:numel(cp_tasks)
    
    % Copy file
    source_name = [path,'/tomoman_',cp_tasks{i},'.param'];
    dest_name = [root_dir,'tomoman_',cp_tasks{i},'.param'];
    system(['cp ',source_name,' ',dest_name]);
    
    % Replace fields
    system(['sed -i "s+%root_directory+',root_dir,'+g" ',dest_name]);
    system(['sed -i "s+%tomolist_filename+',tomolist_name,'+g" ',dest_name]);
    system(['sed -i "s+%tomoman_log_filename+',log_name,'+g" ',dest_name]);
    
end
    
     
end
         
         


