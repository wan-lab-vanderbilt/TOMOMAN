function tm_par_finish_run(par,paramfilename)
%% tm_par_finish
% Complete a parallel TOMOMAN run.
%
% WW 07-2022

%% Check check
if isempty(par)
    return
end


%% Finish run

% Read paramfile
param_cell = tm_read_paramfile([par.root_dir,paramfilename]);

% Parse p-struct
p_fields = tm_get_basic_p();
p = tm_parse_param(p_fields,param_cell);

% Open log
diary([p.root_dir,p.log_name,'_',num2str(par.task_id)]);

% Write output file
% output_name = [par.comm_dir,'tomoman_complete_',num2str(par.task_id)];
output_name = [par.comm_dir,'par_',par.last_task,'_',num2str(par.task_id)];
system(['touch ',output_name]);
disp([par.name,'Parallel ',par.last_task,' on task ',num2str(par.task_id),' complete!!!']);


% Compile results
if par.task_id == 1
    
    % Wait for parallel jobs
    disp([par.name,'Waiting for all parallel tasks to complete...']);
    tm_wait_for_them(par.comm_dir,['par_',par.last_task],par.n_tasks,10);
    
    
    % Early return for non-parallel tasks
    parallel_task =  tm_par_check_parallel_task(par.last_task);     % Also includes tasks that don't require tomolist assembly; e.g. cryoCARE
    if ~parallel_task
        system(['touch ',par.comm_dir,'final_',par.last_task]);
        disp([par.name,'All parallel tasks completed!!! Moving to next task...']);
        return
    end
    disp([par.name,'All parallel tasks to completed!!! Assembling final results...']);
    

    % Parse tomolist name
    [path,name,ext] = fileparts(par.orig_tomolist_name);
    if ~isempty(path)
        path = [path,'/'];
    end
    
    % Load original tomolist
   tomolist = tm_read_tomolist(par.root_dir,par.orig_tomolist_name);
    
    % Read in partial tomolists
    for i = 1:par.n_tasks

        % Partial name
        partial_tomolist_name = ['temp/',path,name,'_',num2str(i),ext];   % Located in parallel temp directory
        
        % Read list
        partial_tomolist = tm_read_tomolist(par.root_dir,partial_tomolist_name);
        if isempty(partial_tomolist)
            continue
        end
        
        % Update entries in old tomolist
        for j = 1:numel(partial_tomolist)
            t_idx = [tomolist.tomo_num] == partial_tomolist(j).tomo_num;
            tomolist(t_idx) = partial_tomolist(j);
        end
        
    end
    

        
    % Write output
    if isfield(par,'archive_dir')
%         save([par.archive_dir,par.orig_tomolist_name],'tomolist');
        tm_save_tomolist(par.archive_dir,par.orig_tomolist_name,tomolist);
    else
%         save([par.root_dir,par.orig_tomolist_name],'tomolist');
        tm_save_tomolist(par.root_dir,par.orig_tomolist_name,tomolist);
    end
    
    system(['touch ',par.comm_dir,'final_',par.last_task]);
    disp([par.name,'Final results for ',par.last_task,' completed!!! Moving on to next task...']);    
    
else
    
    disp([par.name,'Waiting for ',par.last_task,' to complete...']);
    tm_wait_for_it(par.comm_dir,['final_',par.last_task],5)
    
    disp([par.name,'Parallel TOMOMAN run complete!!!']);    
    
end
    
    
% Close log
diary off
    





