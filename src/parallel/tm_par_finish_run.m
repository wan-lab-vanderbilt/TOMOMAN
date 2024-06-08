function tm_par_finish_run(par)
%% 
% Complete a parallel TOMOMAN run.
%
% WW 07-2022

%% Finish run

% Write output file
output_name = [par.comm_dir,'tomoman_complete_',num2str(par.task_id)];
system(['touch ',output_name]);
disp([par.name,'Parallel TOMOMAN task complete!!!']);


% Compile results
if par.task_id == 1
    
    % Wait for parallel jobs
    disp([par.name,'Waiting for all parallel tasks to complete...']);
    tm_wait_for_them(par.comm_dir,'tomoman_complete',par.n_tasks,10);
    disp([par.name,'All parallel tasks to completed!!! Assembling final results...']);
    
    % Early return for non-parallel tasks
    parallel_task =  tm_par_check_parallel_task(par.last_task);     % Also includes tasks that don't require tomolist assembly; e.g. cryoCARE
    if ~parallel_task
        disp([par.name,'Parallel TOMOMAN run complete!!!']);
        return
    end
    
    % Array to hold partial tomolists
    partial_tomolist = cell(par.n_tasks,1);
    

    % Parse tomolist name
    [path,name,ext] = fileparts(par.orig_tomolist_name);
    if ~isempty(path)
        path = [path,'/'];
    end
    
    
    % Read in partial tomolists
    for i = 1:par.n_tasks

        % Partial name
        partial_tomolist_name = ['temp/',path,name,'_',num2str(i),ext];   % Located in parallel temp directory
        
        % Read list
        partial_tomolist{i} = tm_read_tomolist(par.root_dir,partial_tomolist_name);
        
    end
    
    % Concatenate lists
    tomolist = [partial_tomolist{:}];
        
    % Write output
    if isfield(par,'archive_dir')
        save([par.archive_dir,par.orig_tomolist_name],'tomolist');
    else
        save([par.root_dir,par.orig_tomolist_name],'tomolist');
    end
    
    
    disp([par.name,'Parallel TOMOMAN run complete!!!']);    
    
else
    
    disp([par.name,'Parallel TOMOMAN run complete!!!']);    
    
end
    
    
    





