% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Root dir
root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/multishot/invitro/rubisco/fiveshot_go/tomo/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'recons_list.txt';    

% Parallelization on MPIB clusters
p.n_comp = 20;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
p.n_cores = 40;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl67'; % Queue: "local" or "p.hpcl67"(hpcl7xxx) or "p.hpcl8"(hpcl8xxx) 

% Outputs
script_name = 'batch_imod_3dfind';    % Root name of output scripts. One is written for each computer.

% IMOD parameters
p.stack='df';                  % Which stacks to process: 'r' = raw, 'w' = raw/whitened, 'df' = dose-filtered, 'dfw' = dosefiltered/whitened
% Binning for 3dbeadfind
p.beadfind_binning = 16;
% Erase gold in unbinned pixels
p.goldradius = [82];      % Leave blank '[]' to skip.

%% Set some executable paths

% Fourier crop stack executable
p.fcrop_stack = '/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/github/fcrop_stack/fourier_crop_stack.sh';

% Fourier crop volume executable
p.fcrop_vol = '/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/github/Fourier3D/Fourier3D';
p.fcrop_vol_memlimit = 40000;

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
    if exist([t.stack_dir,'/imod_batch3dfind/'],'dir')
        system(['rm -rf ',t.stack_dir,'/imod_batch3dfind/']);
    end
    mkdir([t.stack_dir,'/imod_batch3dfind/']);   
    
    % Read in tilt.com
    tiltcom = [t.stack_dir,'tilt.com'];
    if exist(tiltcom, 'file')
        tiltcom = tomoman_imod_parse_tiltcom([t.stack_dir,'tilt.com']);
                        
        % Generate parallel stack-processing scripts
        tomoman_imod_batch3dfind_generate_imod_scripts(t,p,tiltcom);
        
        % Generate run script for tomogram
        tomoman_imod_batch3dfind_generate_tomogram_runscript(t,p);
    else
        error('tilt.com not found! Skipping stack')
    end
end

% Generate batch scripts
tomoman_imod_batch3dfind_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);
