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
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_arctis/yeast/tomo_test/';    % Tomolist, reconstruction list, and bash scripts go here.
% Tomolist
tomolist_name = 'tomolist.mat';     % Relative to rood_dir
% Reconstruction list
recons_list = 'recons_list.txt';    

% Parallelization
p.n_comp = 1;     % Number of computers/nodes for distributing tomograms should be mod of tomogram number!!!!
p.n_cores = 40;   % Number of cores per computer (20 for local, 40 for p.512g, 16 for p.192g) PLEASE DO NOT DEVIATE !!!!
p.queue = 'p.hpcl67'; % Queue: "local" or "p.hpcl67"(hpcl7xxx)

% Outputs
script_name = 'batch_bin';    % Root name of output scripts. One is written for each computer.


% binning parameters
p.tomo_bin = [2];   % Multiple numbers for serial binning; i.e. [2,2] produces bin2 and bin4 tomograms.
p.unbintomo_dir = [p.root_dir 'bin8_ctfphaseflip/'];   %unbinned tomogram directory

% Tomogram directories
p.bin_dir = {[p.root_dir 'bin16_ctfphaseflip/']};   % Destination of binned tomograms. For multiple binnings, supply as cell array.


%% Set some executable paths

% % Fourier crop stack executable
% p.fcrop_stack = '/fs/pool/pool-jasnin2/Jonathan/scripts/novaCTF/fourier_crop_stack.sh';

% Fourier crop volume executable
p.fcrop_vol = 'Fourier3D';
p.fcrop_vol_memlimit = 40000;

% % Path to novaCTF
% p.novactf = 'novaCTF';

%% Check check
p.main_dir = p.unbintomo_dir;  % Destination of first tomogram

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

% % Check for motl refinement
% if ~strcmp(p.motl_name,'none')
%     p = will_novactf_prepare_motl(p);
% end


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
    
    % Check binning scripts folder
    if exist([t.stack_dir,'/binning/'],'dir')
        system(['rm -rf ',t.stack_dir,'/binning/']);
    end
    mkdir([t.stack_dir,'/binning/']);  
    
    % Generate run script for tomogram
    tomoman_fcropcluster_generate_tomogram_runscript(t,p);
    
end

% Generate batch scripts
tomoman_fcropcluster_generate_batch_scripts(tomolist(r_idx),p,root_dir,script_name);






