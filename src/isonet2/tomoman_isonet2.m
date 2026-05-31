function par = tomoman_isonet2(root_dir,paramfilename,par)
%% tomoman_isonet2
% A function to streamline tomogram denoising and missing-wedge
% compensation using IsoNet2. This was last updated for version 2.0.0-beta. 
%
% TOMOMAN runs IsoNet in 4 steps:
%
% 1. isonet2_prepare: This step involves generating the initial .star file, 
% odd/even tomogram reconstruction, and average tomogram reconstruction.
%
% 2. isonet2_denoise: This step can train a denoising model using  odd/even
% tomograms. Training can be run on a different subset of tomograms than
% the full training step.
%
% 3. isonet2_make_mask: This step runs the isonet2 make_mask function to
% make masks for isonet2 missingw edge filling training. Given how isonet2
% works, if you already know things about particles or targets, you may
% wish to skip this step and generate your own masks... 
%
% 4. isonet2_refine: This step trains the isonet2 network for data
% resotoration using an optinal subset and then runs prediction on the full
% dataset.
%
% WW 02-2026

% %%%% DEBUG
% root_dir = '/sb/wanlab/data/measles/02062026_wanw_wanw_Mev_TOMO/';
% paramfilename = 'tomoman_isonet2_prepare.param';
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
isonet2_fields = tm_get_isonet2_fields(task);
isonet2 = tm_parse_param(isonet2_fields,param_cell);



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

    % Override CPU settings
    isonet2.ncpu = par.cpus_per_task;
    
    % Override GPU settings
    isonet2.gpuID = par.task_gpu - 1; % Adjust GPU ID to start at 0
    
end


%% Run pipeline!!!


    
switch task
    case 'isonet2_prepare'                        
        % Reconstruct odd/even tomograms
        tm_isonet2_prepare(tomolist, p, isonet2, dep, par);

    case 'isonet2_denoise'
        % Denosie is performed in 2 steps. Training is non-parallel and
        % conducted by task 1. Prediction is parallelized. 
        
        %%%%% Run Denoise Training %%%%%
        
        % Check if this is a processing node
        if ~par_proc
            proc = true;
        elseif par.task_id == 1
            proc = true;
        else
            proc = false;
        end

        % Run process or wait
        if isonet2.run_denoise_training
            if proc
                % Run denoising training
                tm_isonet2_denoise_train(p, isonet2, isonet2_fields, dep);

                % Write comm file
                if par_proc
                    system(['touch ',par.comm_dir,'tomoman_isonet2_denoise_train']);
                end
            else
                % Wait for sorting to finish
                disp([p.name,'Waiting for denoise trianing to finish...']);
                tm_wait_for_it(par.comm_dir,'tomoman_isonet2_denoise_train',10);  
            end
        end
        
        %%%%% Run Denoise Prediction %%%%%
        if isonet2.run_denoise_prediction
            tm_isonet2_denoise_predict(p, isonet2, dep, par);
        end
        

    case 'isonet2_make_mask'
        % Make masks using isonet2 
        tm_isonet2_make_mask(p, isonet2, dep, par);
        
    case 'isonet2_make_particle_mask'
        % Make particle masks in TOMOMAN
        tm_isonet2_make_particle_mask(tomolist, p, isonet2, dep, par);
        
    case 'isonet2_refine'
        % Refine is performed in 2 steps. Training is non-parallel and
        % conducted by task 1. Prediction is parallelized. 
        
        %%%%% Run Refine Training %%%%%
        
        % Check if this is a processing node
        if ~par_proc
            proc = true;
        elseif par.task_id == 1
            proc = true;
        else
            proc = false;
        end

        % Run process or wait
        if isonet2.run_refine_training
            if proc
                % Run denoising training
                tm_isonet2_refine_train(p, isonet2, isonet2_fields, dep);

                % Write comm file
                if par_proc
                    system(['touch ',par.comm_dir,'tomoman_isonet2_refine_train']);
                end
            else
                % Wait for sorting to finish
                disp([p.name,'Waiting for denoise trianing to finish...']);
                tm_wait_for_it(par.comm_dir,'tomoman_isonet2_refine_train',10);  
            end
        end
        
        %%%%% Run Denoise Prediction %%%%%
        if isonet2.run_refine_prediction
            tm_isonet2_refine_predict(p, isonet2, dep, par);
        end

end    
    



% Write last task
if par_proc
    par.last_task = task;
end

% Close log
diary off


