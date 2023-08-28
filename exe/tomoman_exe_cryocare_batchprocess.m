% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Root dir
root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'recons_list_1-712.txt';    

% Parallelization on MPIB clusters
p.n_comp = 10;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
% p.n_cores = 24;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl8'; % Queue: "p.hpcl8"(hpcl8xxx) 

% Outputs
script_name = 'batch_cryocare';    % Root name of output scripts. One is written for each computer.

% Cryocare parameters
p.cc_option = 'predict'; % 'train'=  only train, 'predict' = only predict, 
p.cc_boxsize = 72; %
p.cc_depth = 3;

% odd even tomogram directories
p.odd_tomodir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/bin4_uncorr_evn_1-712/'; % 
p.evn_tomodir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/bin4_uncorr_odd_1-712/'; %

% Cryocare train individual or train for a given set of tomograms
p.cc_batch_train = 0; % only compatibvle with cc_option = 'train'

% Model to be used for prediction [give absolute path]
p.cc_model = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/bin4_cryocare_train_n50/CryoCARE_model_box72_d3.tar.gz';

% Cryocare folder 
p.cryocare_dir = [root_dir,'/bin4_cryocare/'];

%% Set some executable paths




%% DO NOT CHANGE BELOW THIS LINE!!!


%% Initialize

% Read tomolist
load([root_dir,'/',tomolist_name]);

% Read reconstruction list
rlist = dlmread([root_dir,'/',recons_list]);
n_tomos = numel(rlist);

% Get indices of tomograms to reconstruct
[~,r_idx] = intersect([tomolist.tomo_num],rlist);

% Check for skips
skips = [tomolist(r_idx).skip];
if any(skips)
    skip_list = rlist(skips);
    for i = numel(skip_list)
        warning(['ACHTUNG!!! Tomogram ',num2str(skip_list(i)),' was set to skip!!!']);
    end
    
    % Update lists
    rlist = rlist(~skips);
    r_idx = r_idx(~skips);
    n_tomos = numel(rlist);
    
end

% make output dir
if ~exist(p.cryocare_dir, 'dir')
    mkdir(p.cryocare_dir);
end
%% Generate CRYOCARE directory and scripts

% Loop through and generate scripts per tomogram
if p.cc_batch_train
    %% Train on a set of tomograms. 
    if strcmp(p.cc_option,'predict')
        error('Jobtype predict is not supported in batch mode!!!')
    else
        % Set common cryocare path
        p.cc_path = p.cryocare_dir;
        
        % Generate run script for selected tomogram
        tomoman_cryocare_generate_tomogram_runscript(tomolist(r_idx),p);
    
        % Generate batch scripts
        tomoman_cryocare_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);
    end

else
    
    for i  = 1:n_tomos        
        % Parse tomolist
        t = tomolist(r_idx(i));    

        if exist([t.stack_dir,'/cryocare/'],'dir')
            system(['rm -rf ',t.stack_dir,'/cryocare/']);
        end
        mkdir([t.stack_dir,'/cryocare/']);   
        p.cc_path = [t.stack_dir,'/cryocare/'];

        % Generate run script for a tomogram
        tomoman_cryocare_generate_tomogram_runscript(t,p);
    end
    % Generate batch scripts
    tomoman_cryocare_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);

end

