% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

% Reconstruction list
aretomo_list = 'aretomo_list_349-712_refined_recons.txt';    

p.aretomo_inbin = 2;  % Binning for the input stack for AreTomo
p.aretomo_outbin = 8; % AreTomo binning

% IMOD parameters
p.imod_stack = 'dose_filt';  % Which stack was used for IMOD alignment. Options are 'unfiltered' and 'dose_filt'.
p.imod_preali = 1;           % Whether to use original stack (0) or IMOD coarse aligned stack (1), make sure imod_param.coarsealignbin in exe_imod_preprocess is set to 1.

% Raw stack size (for FullImage parameter)
p.fullimage = [4096,4096]; % Image size of the unbinned tilt stack


%% DO NOT CHANGE BELOW THIS LINE %%

%% Initalize
diary([p.root_dir,'/',p.log_name]);

% Read tomolist
load([p.root_dir,'/',p.tomolist_name]);

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

%% Generate ARETOMO scripts


for i  = 1:n_tomos
    % Parse tomolist
    t = tomolist(r_idx(i));    
    
    % Align frames and generate stack
    tomoman_aretomo2imod(t,p,VolZ(i));
    
end

diary off