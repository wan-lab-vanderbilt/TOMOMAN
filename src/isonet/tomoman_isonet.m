function par = tomoman_isonet(root_dir,paramfilename,par)
%% tomoman_isonet
% A function to streamline tomogram denoising and missing-wedge
% compensation using IsoNet. This was last updated for version 0.2.0. It is
% assumed that you have already reconstructed tomograms at an appropriate
% binning (~10A/pix) in a separate folder. tomoman_imod_reconstruct can be
% used to facilitate this. 
%
% TOMOMAN runs IsoNet in 3 steps:
%
% 1. isonet_prepare: This step involves generating the initial .star file, 
% and optionally, running decovolution and mask generation. NOTE: you
% should prepare the full dataset you wish to denoise at the end.
%
% 2. isonet_train: This step takes the output of isonet_prepare, extracts
% subtomograms, and runs training. NOTE: You can run this on a subset of
% the full dataset. Also, this process is not run in parallel.
%
% 3. isonet_predict: This uses a pre-trained IsoNet network (e.g. output
% from the isonet_train step) and uses it to predict the dataset. 
%
% WW 06-2025

% % %%%% DEBUG
% root_dir = '/dors/wan_lab/home/wanw/research/temp/tomoman_parallel_testing/';
% paramfilename = 'tomoman_isonet_prepare.param';
% par_proc = false;
% par = [];
% root_dir = sg_check_dir_slash(root_dir);

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

% Parse task from paramfile
task = tm_parse_tasks([root_dir,paramfilename]);

% Read param
param_cell = tm_read_paramfile([root_dir,paramfilename]);

% Parse p-struct
p_fields = tm_get_basic_p();
p = tm_parse_param(p_fields,param_cell);

% Overrides for parallel processing
if par_proc    
    p.root_dir = par.root_dir;              % Root directory
end



% Parse isonet struct
isonet_fields = tm_get_isonet_fields(task);
isonet = tm_parse_param(isonet_fields,param_cell);



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
dep = tm_get_dependencies(p,'linux');               % Basic linux commands
dep = tm_get_dependencies(p,task,dep);              % IsoNet
tm_check_dependencies(dep,false);                   % Check dependencies

%% Parallel processing

% Set parallel settings
if par_proc
    disp([p.name,'Parallel processing enabled...']);    
    
    % Override n_cores
    if strcmp(task,'isonet_prepare')
        isonet.n_cores = par.cpus_per_task;
    end

    % Override GPU settings
    isonet.gpu_id = par.task_gpu - 1; % Adjust GPU ID to start at 0
    
end


%% Run pipeline!!!


    
switch task
    case 'isonet_prepare'                        
        % Reconstruct odd/even tomograms
        tm_isonet_prepare(tomolist, p, isonet, dep, par);

    case 'isonet_train'

        % Check if this is a processing node
        if ~par_proc
            proc = true;
        elseif par.task_id == 1
            proc = true;
        else
            proc = false;
        end

        % Run process or wait
        if proc
            % Extract training data and perform training
            tm_isonet_train(tomolist, p, isonet, dep, par);

            % Write comm file
            if par_proc
                system(['touch ',par.comm_dir,'tomoman_isonet_train']);
            end
        else
            % Wait for sorting to finish
            disp([p.name,'Waiting for cleaning to finish...']);
            tm_wait_for_it(par.comm_dir,'tomoman_cryocare_train',10);  
        end

    case 'isonet_predict'
        % Perform denoising 
        tm_isonet_predict(tomolist, p, isonet, dep, par);

end    
    



% Write last task
if par_proc
    par.last_task = task;
end

% Close log
diary off


