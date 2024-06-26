function par_fields = tm_get_parallel_fields()
%% tm_get_parallel_fields
% Return the fields for tomoman parallel processing.
%
% WW 07-2022

%% Fields

par_fields = {'root_dir', 'str';... 
              'paramfilename', 'str';...
              'tomolist_name', 'str';...
              'n_nodes', 'num';...
              'node_id', 'num';...
              'n_tasks', 'num';...
              'local_id', 'num';...
              'task_id', 'num';...
              'n_tasks_per_node', 'num';...
              'cpus_per_task', 'num';...
              'gpu_per_node', 'num';...
              'gpu_per_task', 'num';...
              'gpu_list', 'num';...
              };

              
        
end
