% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

% Written for CTFFIND 4.1.14

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';  % Root folder for dataset; stack directories will be generat/fs/pool/pool-plitzko/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/tomo/ed here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir


%%%% CTFFIND4 %%%%

ctf.force_ctffind = 0;                   % 1 = yes, 0 = no;
ctf.imod_stack = 'unfiltered';  % Options are 'unfiltered' and 'dose_filt'.
ctf.auto_targetdf = 1;          % Determine target defocus using the zero tilt. Default is 0;
ctf.init_def_range = 1;         % Defocuse tolerance for determination of target defocus. 
% ctf.rest_zeroastig = 0;       % restrict astigmatism to that of the zero tilt. Default is 0; % __FUTURE__

% CTFFIND parameters
ctffind.ps_size = 512;             % Size of power-spectrum in pixels
ctffind.evk = 300;                 % Acceleration voltage
ctffind.cs = 2.7;                  % Spherical aberration
ctffind.famp = 0.07;               % Ampltidue contrast
ctffind.min_res = 40;              % Minimum resolution to fit
ctffind.max_res = 5;               % Maximum resolution to fit
ctffind.def_range = 0.6;           % Defocus tolerance in microns
ctffind.def_step = 0.01;           % Defocus search step in microns. Default is 0.01.
ctffind.known_astig = 0;           % Do you know what astigmatism is present? (0 = no, 1 = yes). Default is 0;
ctffind.slower = 0;                % Slower, more exhaustive search (0 = no, 1 = yes). Default is 0;
ctffind.astig = 0;                 % Known astigmatism.
ctffind.astig_angle = 0;           % Known astigmatism angle.
ctffind.rest_astig = 1;            % Restrict astigmatism (0 = no, 1 = yes). Default = 1;
ctffind.exp_astig = 200;           % Expected (tolerated) astigmatism. Default is 200.
ctffind.det_pshift = 0;            % Determine phase shift (0 = no, 1 = yes).
ctffind.pshift_min = 0;            % Minimum phase shift (rad). Default = 0.0.
ctffind.pshift_max = 3.15;         % Maximum phase shift (rad). Default = 3.15.
ctffind.pshift_step = 0.1;         % Phase shift search step. Default = 0.1.
ctffind.expert = 1;                % Do you want to set expert options? (0 = no, 1 = yes) Default is 0;
ctffind.resample = 1;              % Resample micrograph if pixel size too small? (0 = no, 1 = yes)
ctffind.known_defocus = 0;         % Do you already know the defocus?  (0 = no, 1 = yes) Default is 0; 
ctffind.known_defocus_1 = 0.0;     % Known defocus 1 .   Default is 0;
ctffind.known_defocus_2 = 0.0;     % Known defocus 2 .   Default is 0;
ctffinf.known_defocus_astig = 0;   % Known defocus astigmatism.   Default is 0;
ctffinf.known_defocus_pshift = 0;  % Known defocus phase shift in radians.   Default is 0;
ctffind.nthreads = 20;             % Desired number of parallel threads. 



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
    
    if ctf.auto_targetdf
        % Run ctffind4 on zero tilt to find target defocus
        tomolist(t) = tomoman_targetdefocus_ctffind4(tomolist(t), p, ctf, ctffind, write_list);
    end
    
    
    % CTFIND4
    tomolist(t) = tomoman_ctffind4(tomolist(t), p, ctf, ctffind, write_list);
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
   
    % Increment counter
    t = t+b_size;
end

diary off