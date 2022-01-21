%% will_novactf_prepare_scripts_cluster
% A function to prepare scripts for running novaCTF to reconstruct a set of
% tomograms. As input, a tomolist generated from the tomoman scripts is
% required, as well as a list of tomograms to be reconstructed. The
% reconstruction list should be a list of numbers corresponding to the
% 'tomo_num' field in the tomolist.
%
% The jobs are to be run locally and are parallelized in two ways: first is
% by the number of computers, each of which calculates a single tomogram at
% a time. During the calculation of each tomogram, a large number of
% tilt-stacks are processed in parallel: this is defined by the number of
% cores per computer. 
%
% In each stack directory, a folder called novaCTF is created. Temporary
% files are stored there and scripts for running each step are written
% there. 
%
% The final outputs are batch scripts to be executed on each computer.
%
% Tomogram parameters are taken from the etomo files in the stack folder,
% i.e. the tilt.com and *_fid.xf files. 
%
% In this implementation, the NovaCTF pipeline is run as follows:
%  1 - Generate NovaCTF folders in stack directories
%  2 - Generate NovaCTF defocus files
%  3 - CTF-correct dose-filtered stacks
%  4 - Create aligned stacks (can be output to arbitrary sizes... good for producing a stack with nicely binnable dimensions; i.e. 3712)
%  5 - Taper algined stacks
%  6 - Bin stack via Fourier cropping
%  7 - Flip stacks
%  8 - R-filter stacks
%  9 - Reconstruct tomogram with NovaCTF
% 10 - Bin tomograms with Fourier cropping
%
% Most of the input parameters are stored in the 'p' array, which is passed
% to the various functions.
%
% WW 02-2018 
% SK 12-2018 added functionality to run on the cluster (Make sure you have imod and novaCTF in your path!!!)

%% Inputs

% Root dir
root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_arctis/yeast/tomo_test/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'recons_list.txt';    

% Parallelization on MPIB clusters
p.n_comp = 1;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
p.n_cores = 40;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g)!!!!
p.queue = 'p.hpcl67'; % Queue: "local" or "p.hpcl67"(hpcl7xxx) or "p.hpcl8"(hpcl8xxx) 

% Outputs
script_name = 'batch_novaCTF_cluster';    % Root name of output scripts. One is written for each computer.

% NovaCTF parameters
% 3D-CTF
p.stack='df';                  % Which stacks to process: 'r' = raw, 'w' = raw/whitened, 'df' = dose-filtered, 'dfw' = dosefiltered/whitened
p.correction_type = 'phaseflip';  % Options are 'phaseflip' or 'multiplication'
p.defocus_step = 15;              % Defocus step along tomogram thickness in nm
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
p.tomo_thickness = 2048; % Tomogram thickness in unbinned pixels.  Overwrites the value from the Tilt.com.
% Bin aligned stack
p.ali_stack_bin = [2];    % Leave blank '[]' to skip.
% Radial filter
p.radial = [];    % See RADIAL parameter for the IMOD tilt function. Leave empty '[]' to exclude parameter.
% Bin tomogram
p.tomo_bin = [2,2];   % Multiple numbers for serial binning; i.e. [2,2] produces bin2 and bin4 tomograms.

% Refined center against motivelist
p.motl_name = 'none'; % Set to 'none' to disable
p.motl_binning = 2;

% Tomogram directories
p.main_dir = [root_dir 'bin2_novactf/'];  % Destination of first tomogram
p.bin_dir = {[root_dir 'bin4_novactf/'],[root_dir 'bin8_novactf/']};   % Destination of binned tomograms. For multiple binnings, supply as cell array.


%% Set some executable paths

% Fourier crop stack executable
p.fcrop_stack = '/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/github/fcrop_stack/fourier_crop_stack.sh';

% Fourier crop volume executable
p.fcrop_vol = 'Fourier3D';
p.fcrop_vol_memlimit = 40000;

% Path to novaCTF
p.novactf = 'novaCTF';

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



%% Generate NovaCTF directory and scripts

% Loop through and generate scripts per tomogram
for i  = 1:n_tomos
    
    % Parse tomolist
    t = tomolist(r_idx(i));
    
    % Read in tilt.com
    tiltcom = tomoman_imod_parse_tiltcom([t.stack_dir,'tilt.com']);
    if ~isempty(p.tomo_thickness)
        tiltcom.THICKNESS = p.tomo_thickness;
    end

    % Generate directory structure
    tomoman_novactf_generate_directories(t.stack_dir);
    
    % Generate defocus files and determine number of stacks
    n_stacks = tomoman_novactf_generate_defocus_files(t,p,tiltcom);
    
    % Generate parallel stack-processing scripts
    tomoman_novactf_generate_parallel_scripts(t,p,n_stacks,tiltcom);
        
    % Generate run script for tomogram
    tomoman_novactf_generate_tomogram_runscript(t,p,n_stacks,tiltcom);
    
end

% Generate batch scripts
tomoman_novactf_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);






