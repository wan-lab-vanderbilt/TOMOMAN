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


%%%% IMOD preprocess %%%%
imod_param.imod_preprocess = 1;               % 1 = yes, 0 = no;
imod_param.force_imod = 0;                    % 1 = yes, 0 = no;
% Copytomocoms
imod_param.copytomocoms = 1;       % Run copytomocoms
imod_param.goldsize = [];          % Gold diameter (nm)
imod_param.rotation =[];       % Tilt axis rotation (deg), leave empty to use from the tomolist. 
% CCD Eraser
imod_param.ccderaser = 1;          % Run CCD Eraser
imod_param.archiveoriginal = 0;    % Archive and delete original stack
% Coarse alignment
imod_param.coarsealign = 1;        % Perform coarse alignment 
imod_param.tiltxcorrbinning = 8;     % Bin factor for coarse alignment
imod_param.tiltxcorrangleoffset = 0; % offset angle (pretilt) for coarse alignment
imod_param.ExcludeCentralPeak = 0;    % Exclude central peak??
imod_param.ShiftLimitsXandY = []; % maximum shift in unbinned pixels
imod_param.coarsealignbin = 1;     % Bin factor for coarse alignmened stack
imod_param.coarseantialias = 1;   % Antialiasing filter for coarse alignment
imod_param.convbyte = '/';         % Convert to bytes: '/' = no, '0' = yes
% Autoseed and beadtrack
imod_param.autoseed = 0;           % Run autofidseed and beadtrack
imod_param.localareatracking = 0;  % Local area bead tracking (1=yes,0=no)
imod_param.localareasize = 1000;   % Size of local area
imod_param.sobelfilter = 1;        % Use Sobel filter (1=yes,0=no)
imod_param.sobelkernel = 1.5;      % Sobel filter kernel (default 1.5)
imod_param.n_rounds = 2;           % Number of rounds of tracking in run (default = 2)
imod_param.n_runs = 2;             % Number of times to run beadtrack (default = 2)
imod_param.two_surf = 0;           % Track beads on two surfaces (1=yes,0=no) 
imod_param.n_beads = 20;          % Target number of beads
imod_param.adjustsize = 1;         % Adjust size of beads based on average bead size (1=yes,0=no) 

% Tomogram Positioning
imod_param.positioning_thickness = 4096;    % Thickness for tomogram positioning.
imod_param.positioning_binning = 8;         % Binning for tomogram positioning. 
imod_param.alignedstack_binning = 8;        % Binning for aligned stack. 

%% DO NOT CHANGE BELOW THIS LINE %%

%% Initalize

diary([p.root_dir,p.log_name]);
disp('TOMOMAN Initializing!!!');

% Read tomolist
if exist([p.root_dir,p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,p.tomolist_name]);
else
    error('TOMOMAN: No tomolist found!!!');
end

%% Check dependencies

% List of dependent commands
dependencies = {'ctffind'};

% Loop through and test commands
for i = 1:numel(dependencies)
    [test,~] = system(['which ',dependencies{i}]);
    if test == 1
        error(['ACHTUNG!!! ',dependencies{i},' not found!!! Source the package prior to running MATLAB!!!']);
    end
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;

while all(t <= n_tilts)
    
    % Preprocess
    tomolist(t) = tomoman_imod_preprocess(tomolist(t), p, imod_param, write_list);
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');

    
    t = t+b_size;
    
end

diary off