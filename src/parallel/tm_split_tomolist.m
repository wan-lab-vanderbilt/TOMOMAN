function [partial_tomolist,partial_tomolist_name,par] = tm_split_tomolist(tomolist,root_dir,tomolist_name,par,task,task_params)
%% tm_split_tomolist
% Split an input tomolist for parallel processing.
%
% WW 07-2022

%% Backup old list

if par.task_id == 1
%     save([root_dir,tomolist_name,'~'],'tomolist');
    tm_save_tomolist(root_dir,tomolist_name,[]);
else
    pause(5);
end

%% Check for entries to process

% Parse skips
skip = [tomolist.skip];

% Check for entries where task has not been completed
incomplete = tm_check_task_completion(tomolist,task,task_params);

% Indices to process
proc_idx = find(~skip & incomplete);

%% Calculate jobs

% Number of stacks
n_stacks = numel(proc_idx);

% Calculate job array
job_array = tm_job_array(n_stacks,par.n_tasks);

% Check number of jobs
n_jobs = size(job_array,1);
if par.task_id > n_jobs         % Return empty arrays if too many tasks for jobs
    partial_tomolist = [];
    partial_tomolist_name = [];
    return
end




%% Split list

% Parse list
partial_tomolist = tomolist(proc_idx(job_array(par.task_id,2):job_array(par.task_id,3)));


%% Parse partial tomolist name

% Store original tomolist name
par.orig_tomolist_name = tomolist_name;

% Parse name
[path,name,ext] = fileparts(tomolist_name);
if ~isempty(path)
    path = [path,'/'];
end

% New name
partial_tomolist_name = ['temp/',path,name,'_',num2str(par.task_id),ext];   % Output to parallel temp directory


