function par = tm_parse_parallel_inputs(input_cell)
%% tm_parse_parallel_inputs
% Parse inputs for a parallel TOMOMAN job.
%
% WW 07-2022


% % % % % % % % % DEBUG
% input_cell = {'root_dir', '/hd1/wwan/mintu/VUKrios_Apr22/tomoman_test2/',...
%               'paramfilename', 'tomoman_aretomo.param',...
%               'n_nodes', '1',...
%               'node_id', '0',...
%               'n_tasks', '2',...
%               'local_id', '0',...
%               'task_id', '0',...
%               'n_tasks_per_node', '1',...
%               'cpus_per_task', '10',...
%               'gpu_per_node', '4',...
%               'gpu_per_task', '2'}; %,...
% %              'gpu_list', '2,3'};



%% Parse inputs

% Concatenate to parser paramters
par_fields = tm_get_parallel_fields;

% Parse inputs into a param_cell
inputs = reshape(input_cell,2,[])';
param_cell = cell(1,2);
param_cell{1} = inputs(:,1);
param_cell{2} = inputs(:,2);



% Parse par-struct
par = tm_parse_param(par_fields,param_cell);

% Increment IDs from 0-indexing to 1-indexing
par.node_id = par.node_id+1;
par.local_id = par.local_id+1;
par.task_id = par.task_id+1;


%% Calculate additional numbers

% % Calculate overall task ID
% par.task_id = ((par.node_id-1)*par.n_tasks_per_node)+par.local_id;

% Determine GPU indices for task
if par.gpu_per_task ~= 0
    if sg_check_param(par,'gpu_list')
    %     gpu_array = reshape(par.gpu_list,par.gpu_per_task,par.n_tasks_per_node);
        gpu_array = reshape(par.gpu_list,par.gpu_per_task,[]);
        gpu_array = gpu_array + 1;  % Increment for MATLAB 1-indexing
    else
    %     gpu_array = reshape((1:par.gpu_per_node),par.gpu_per_task,par.n_tasks_per_node);
        gpu_array = reshape((1:par.gpu_per_node),par.gpu_per_task,[]);
    end
    
    % Store GPU indices
    par.task_gpu = gpu_array(:,par.local_id)';  % Store as MATLAB indices, starting from 1
    % par.task_gpu = gpu_array(:,mod(par.local_id,par.gpu_per_node)+1)';  % Store as MATLAB indices, starting from 1
    
end



%% Parse parallel task name

% Set task name
par.name = ['TOMOMAN_task',num2str(par.task_id),': '];

% Write task parameters
disp([par.name,'Running TOMOMAN in parallel... Listing parallel parameters:']);
disp([par.name,'Node ID: ',num2str(par.n_nodes)]);
disp([par.name,'Local ID: ',num2str(par.local_id)]);
disp([par.name,'Task ID: ',num2str(par.task_id)]);
if par.gpu_per_task ~= 0
    disp([par.name,'Assigned GPU IDs: ',num2str(par.task_gpu)]);
end


 

 

 

 