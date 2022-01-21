% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/tomo/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

%%%% Dose filter stacks %%%%
df.dose_filter = 1;                 % 1 = yes, 0 = no;
df.force_dfilt = 0;                 % 1 = yes, 0 = no;
df.dfilt_append = '-dose_filt';     % Append name to dose-filtered stack. Empty ('') overwrites stack; this is NOT recommended...
df.filter_frames = 0;               % Dose filter frames instead of images. In order to do this, the OutStack MotionCor2 parameter must have been used to generate aligned frame stacks.
df.preexposure = 0;                 % Pre-exposure prior to initial image collection.
df.a = '';                          % Resolution-dependent critical exposure constant 'a'. Leave emtpy ('') to use default.
df.b = '';                          % Resolution-dependent critical exposure constant 'b'. Leave emtpy ('') to use default.
df.c = '';                          % Resolution-dependent critical exposure constant 'c'. Leave emtpy ('') to use default.

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
dependencies = {'newstack'};

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
    
    % Dose filter
    tomolist(t) = tomoman_exposure_filter(tomolist(t),p,df,write_list);
    
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
    
    t = t+b_size;
    
end

diary off