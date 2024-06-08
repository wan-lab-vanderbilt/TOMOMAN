function par = tm_par_initialize_dirs(par)
%% tm_par_initialize_dirs
% Initialize temporary and communication directories for parallel
% processing.
%
% WW 07-2022


%% Initialize directories

% Communications directory
par.comm_dir = [par.root_dir,'comm/'];

% Temporary directory
par.temp_dir = [par.root_dir,'temp/'];


% Initialize directories
if par.task_id == 1
    
    % List of directories
    d_list = {'comm_dir','temp_dir'};
    n_dir = numel(d_list);
    
    % Make directories
    for i = 1:n_dir
        if exist(par.(d_list{i}),'dir')
            system(['rm -rf ',par.(d_list{i})]);
        end
        mkdir(par.(d_list{i}));
    end
end






