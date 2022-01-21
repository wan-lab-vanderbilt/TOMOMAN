% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Root dir
root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/tomo/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'recons_list.txt';    

% Parallelization on MPIB clusters
p.n_comp = 1;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
p.n_cores = 24;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl8'; % Queue: "local" or "p.hpcl67"(hpcl7xxx) or "p.hpcl8"(hpcl8xxx) 

% Outputs
script_name = 'batch_imod_uncorr_sirt10';    % Root name of output scripts. One is written for each computer.

% IMOD parameters
p.stack='df';                  % Which stacks to process: 'r' = raw, 'w' = raw/whitened, 'df' = dose-filtered, 'dfw' = dosefiltered/whitened
p.correction_type = 'uncorr';  % Options are 'ctfphaseflip' or 'uncorr'
p.defocus_step = 30;              % Defocus step along tomogram thickness in nm
% CTF parameters
p.famp = 0.07;    % Amplitude contrast
p.cs = 2.7;       % Spherical abberation (mm)
p.evk = 300;      % Voltage
% Aligned stack size
p.ali_dim = [4096,4096];
% Erase gold
p.goldradius = [];      % Leave blank '[]' to skip.
% Taper
p.taper_pixels = 100;   % Leave blank '[]' to skip.
% Thickness
p.tomo_thickness = 512; % Tomogram thickness in unbinned pixels.  Overwrites the value from the Tilt.com.
% Bin aligned stack
p.ali_stack_bin = [2];    % Leave blank '[]' to skip.
% Bin tomogram
p.tomo_bin = [2,2];   % Multiple numbers for serial binning; i.e. [2,2] produces relatively binned tomograms.

% Refined center against motivelist
p.motl_name = 'none'; % Set to 'none' to disable
p.motl_binning = 1;

% Tomogram directories
p.main_dir = [root_dir 'bin2_uncorr_sirt10/'];  % Destination of first tomogram (MAKE SURE IT"S THE RIGHT BINNING)
p.bin_dir = {[root_dir 'bin4_uncorr_sirt10/'],[root_dir 'bin8_uncorr_sirt10/'],};   % Destination of binned tomograms. For multiple binnings, supply as cell array.

% Pretilt option
p.pretilt = 0; % whether or not to apply pretilt (tiltcom parameter OFFSET) to tilt angles in .tlt file. 

% Fake SIRT iterations
p.fakesirtiter = [10];  % fake SIRT iterations for better contrast!

%% Set some executable paths

% Fourier crop stack executable (!!! Make sure is )
p.fcrop_stack = '/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/github/fcrop_stack/fourier_crop_stack.sh';

% Fourier crop volume executable
p.fcrop_vol = 'Fourier3D';
p.fcrop_vol_memlimit = 40000;

%% Check check

% Force p.bin_dir into cell array
if ~iscell(p.bin_dir)
    temp_bin_dir = p.bin_dir;
    p.bin_dir = cell(1,1);
    p.bin_dir{1} = temp_bin_dir;
end

% Check tomogram directories
n_binning = numel(p.tomo_bin);
if n_binning ~= numel(p.bin_dir)
    error('ACHTUNG!!! Number of bin_dir does not match number of tomo_bin!!!');
end

% Check for motl refinement
if ~strcmp(p.motl_name,'none')
    p = tomoman_novactf_prepare_motl(p);
end


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

% Check tomogram directories
if ~exist(p.main_dir,'dir')
    mkdir(p.main_dir);
end
for i = 1:n_binning
    if ~exist(p.bin_dir{i},'dir')
        mkdir(p.bin_dir{i});
    end
end



%% Generate IMOD directory and scripts

% Loop through and generate scripts per tomogram
for i  = 1:n_tomos    
    % Parse tomolist
    t = tomolist(r_idx(i));    
    
    % Check IMOD folder
    if exist([t.stack_dir,'/imod_batchprocess/'],'dir')
        system(['rm -rf ',t.stack_dir,'/imod_batchprocess/']);
    end
    mkdir([t.stack_dir,'/imod_batchprocess/']);   
    
    % Read in tilt.com
    tiltcom = [t.stack_dir,'tilt.com'];
    if exist(tiltcom, 'file')
        tiltcom = tomoman_imod_parse_tiltcom([t.stack_dir,'tilt.com']);
                        
        % Generate parallel stack-processing scripts
        tomoman_imod_batchprocess_generate_imod_scripts(t,p,tiltcom);
        
        % Generate run script for tomogram
        tomoman_imod_batchprocess_generate_tomogram_runscript(t,p);
    else
        error('tilt.com not found! Skipping stack')
    end
end

% Generate batch scripts
tomoman_imod_batchprocess_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);
