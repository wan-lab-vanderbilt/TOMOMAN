function tasks = tm_get_nonparallel_tasks()
%% tm_get_nonparallel_tasks
% Return a cell array with all non-parallel tomoman tasks.
%
% WW 07-2022


%% Task list
tasks = {'import';...
         'clean_stacks';...
         'cryocare_oe_recons';...
         'cryocare_train';...
         'cryocare_predict';...
         };
     
     
end