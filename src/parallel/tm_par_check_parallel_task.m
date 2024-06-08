function parallel_task =  tm_par_check_parallel_task(task)
%% tm_par_check_parallel_task
% Check an input test against a list of non-parallel tasks.
%
% NOTE: Here, a non-parallel task also refers to a task that does not
% require reassembly of a tomolist.
%
% WW 07-2022

%% Check task

% Get list of non-parallel tasks
np_tasks = tm_get_nonparallel_tasks();

if any(strcmpi(np_tasks,task))
    parallel_task = false;
else
    parallel_task = true;
end



