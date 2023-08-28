% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs
experiment = '17072022/'; % New data should be linked inside an experiment folder in the root directory

% Directory parameters
p.root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';  % Root folder for dataset; stack directories will be generated here.
p.raw_stack_dir = [p.root_dir,experiment '/raw_data/' ];         % Folder containing raw stacks (It is recommended to use links)
p.raw_frame_dir = [p.root_dir,experiment '/frames/' ];      % Folder containing unsorted frames (It is recommended to use links)

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

% Filename parameters
p.prefix = 'AUTO';      % Beginning of stack/mdoc names (e.g. stackname is [prefix][tomonum].[raw_stack_ext])
%p.digits = 3;         % OBSOLETE; CAN BE REMOVED; Number of digits (i.e. leading zeros; e.g. 02 is digits=2, 002 is digits=3)
p.raw_stack_ext = '.st';  % File extension of raw stacks

% Data collection parameters
p.gainref = '/fs/pool/pool-plitzko/Sagar/Data/fromTFS/Arctis/chlamy/17072022/gainref/20220717_000157_EER_GainReference.gain';       % For no gainref, set to 'none, set to 'AUTO' if you are lazy!
p.defects_file = [p.root_dir,'none'];   % For no defects_file, set to 'none'
p.rotate_gain = 0;                                                  % Gain ref rotation
p.flip_gain = 0;                                                    % Gain ref flip; 0 = none, 1 = up/down, 2 = left/right
p.os = 'windows';                                                   % Operating system for data collection. Options are 'windows' and 'linux'
p.mirror_stack = 'y';                                               % Mirror images, MAKE SURE YOU KNOW YOUR STUFF!!;


% Overrides (set to '' for no override)
ov.tilt_axis_angle = -85;    % Tilt axis angle in degrees
ov.dose_rate = 9.05;  % e/pixel/s
ov.pixelsize = 1.96;  % Pixel size in Angstroms
ov.target_defocus = []; % Target defocus in Microns

%%%% Find and sort new stacks? %%%%
s.ignore_raw_stacks = 1;              % Move files even if raw stack is missing
s.ignore_missing_frames = 0;          % Move files even if frames are missing

%%%% Tomo5 specific part %%%%
p.if_tomo5 = 1; % Default= 0. whether or not the Data was aquired with Tomo5 
p.if_tomo5_subframepath_missing = 0; %(only valid for TOmo5 mdoc bug with subframepath)
p.if_tomo5_subframepath_rounderror = 0; %(only valid for TOmo5 mdoc bug with subframepath)

%%%% EER bugs %%%%
p.if_eer_serialembug = 0; % ! for EER, 0 for MRC


%% DO NOT CHANGE BELOW THIS LINE %%

%% Initalize
diary([p.root_dir,p.log_name]);
disp('TOMOMAN Initializing!!!');

% Check extension
if ~strcmp(p.raw_stack_ext(1),'.')
    raw_stack_ext = ['.',p.raw_stack_ext];
end

% Check OS
if ~any(strcmp(p.os,{'windows','linux'}))
    error('ACHTUNG!!! Invalid p.os parameter!!! Only "windows" and "linux" supported!!!');
end

% Read tomolist
if exist([p.root_dir,p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,p.tomolist_name]);
else
    disp('TOMOMAN: No tomolist found... Generating new tomolist!!!');
    tomolist = struct([]);
end


%% check for gain ref

if strcmp(p.gainref, 'AUTO')
        
  p = tomoman_autocheck_gainref(p);
               
end

%% Sort new stacks
 
 % Sort stackstomolist
 tomolist = tomoman_sort_new_stacks(p,ov,s,tomolist);

 % Write tomolist
 save([p.root_dir,p.tomolist_name],'tomolist');

 
