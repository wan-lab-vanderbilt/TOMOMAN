% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Root dir
root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_arctis/chlamy/tomo/all/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'rubisco_tomo_list.txt';    

% Parallelization on MPIB clusters
p.n_comp = 1;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
% p.n_cores = 24;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl8'; % Queue: "p.hpcl8"(hpcl8xxx) 

% Outputs
script_name = 'batch_cryocare';    % Root name of output scripts. One is written for each computer.

% Cryocare parameters
p.cc_train = 1; % train cryocare network. Default = 1(yes). 0 = No training (not yet supported!)
p.cc_boxsize = 72; %
p.cc_depth = 3; %


% odd even tomogram directories
p.odd_tomodir = '/fs/pool/pool-plitzko/Sagar/Projects/project_arctis/chlamy/tomo/all/bin4_uncorr_dfevn'; % 
p.evn_tomodir = '/fs/pool/pool-plitzko/Sagar/Projects/project_arctis/chlamy/tomo/all/bin4_uncorr_dfodd'; %

%% Set some executable paths


% cryocare command line interface (Thanks to Ricardo!!! Awesome stuff :))
% maybe it's a good idea to make it a part of Cryocare module! 
p.cryocare_cli = '/fs/pool/pool-plitzko/Sagar/scripts/CRYOCARE_CLI/';


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


%% Generate IMOD directory and scripts

% Loop through and generate scripts per tomogram
for i  = 1:n_tomos    
    % Parse tomolist
    t = tomolist(r_idx(i));    
    
    % Check IMOD folder
    if exist([t.stack_dir,'/cryocare/'],'dir')
        system(['rm -rf ',t.stack_dir,'/cryocare/']);
    end
    mkdir([t.stack_dir,'/cryocare/']);   
    
    % Generate run script for tomogram
    tomoman_cryocare_generate_tomogram_runscript(t,p);
end

% Generate batch scripts
tomoman_cryocare_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);
