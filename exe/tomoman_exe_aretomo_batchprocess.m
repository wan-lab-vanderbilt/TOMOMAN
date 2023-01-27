% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Root dir
p.root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';    % Tomolist, reconstruction list, and bash scripts go here.

% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
aretomo_list = 'aretomo_list_349-712_refined.txt';    

% Parallelization on MPIB clusters
p.n_comp = 10;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
p.n_cores = 24;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl8'; % Queue: "local" or "p.512g"(hpcl7xxx) or "p.192g"(hpcl4xxx) I suggest to use hpcl4xxx for optimal resource usage!

% Outputs
script_name = 'batch_aretomo';    % Root name of output scripts. One is written for each computer.

% IMOD parameters
p.imod_stack = 'dose_filt';  % Which stack was used for IMOD alignment. Options are 'unfiltered' and 'dose_filt'.
p.imod_preali = 1;           % Whether to use original stack (0) or IMOD coarse aligned stack (1), make sure imod_param.coarsealignbin in exe_imod_preprocess is set to 1.

% Tomogram directories
p.main_dir = [p.root_dir 'bin8_aretomo_349-712/'];  % Destination of first tomogram (MAKE SURE IT"S THE RIGHT BINNING)

% Known Tilt Angle Offset in case of lamellae (Tip: if pretilt off lamella is -10 then tilt angle offset is 10)
p.titlangleoffset = 0; % Angle offset in digrees

% AreTomo Params
p.aretomo_useunfilt = 1; % use non dose-weighted stack for aretomo
p.aretomo_inbin = 2;  % Binning for the input stack 
p.aretomo_outbin = 8;              % AreTomo binning
p.Wbp = 1;      % Use Weighted Back Projection for reconstruction 
p.TiltCor = 1;  % correct tilt angle offset
p.Patch_x = 0; % number of Patches in X
p.Patch_y = 0; % number of Patches in Y
p.tiltaxisangle = ''; % leave empty to use the one from the Tomolist. 
p.tiltaxisangle_refineflag = 0; % Refineflag: Default is 1 as defined in the Aretomo Manual section 16. 

% % In case you want to just reconstruct previously aligned tomo 
% p.aretomo_reconstruct = 1; 
% p.goldradius = [];  % Leave blank '[]' to skip.

% AreTomo executive
p.aretomo_exe = '/fs/pool/pool-plitzko/Sagar/scripts/3rd_party/AreTomo/AreTomo_1.2.0_06-23-2022/AreTomo_1.2.0_Cuda101_06-23-2022';

%% Initialize

% Read tomolist
load([p.root_dir,'/',tomolist_name]);

% Read reconstruction list
aretomolist = dlmread([p.root_dir,'/',aretomo_list]);
rlist = (aretomolist(:,1));
AlignZ = (aretomolist(:,2));
VolZ = (aretomolist(:,3));

n_tomos = numel(rlist);


% Get indices of tomograms to reconstruct
[~,r_idx] = intersect([tomolist.tomo_num],rlist(:,1));

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

% Check tomogram directories
if ~exist(p.main_dir,'dir')
    mkdir(p.main_dir);
end


%% Generate ARETOMO scripts

% Loop through and generate scripts per tomogram
for i  = 1:n_tomos
    % Parse tomolist
    t = tomolist(r_idx(i));    
    
    % Check areTomo folder
    if exist([t.stack_dir,'/AreTomo/'],'dir')
        system(['rm -rf ',t.stack_dir,'/AreTomo/']);
    end
    mkdir([t.stack_dir,'/AreTomo/']);   
   
    % Generate run script for tomogram
    tomoman_aretomo_batchprocess_generate_tomogram_runscript(t,p,AlignZ(i),VolZ(i));
end

% Generate batch scripts
tomoman_aretomo_batchprocess_generate_batch_scripts(tomolist(r_idx),p,p.root_dir,script_name);
