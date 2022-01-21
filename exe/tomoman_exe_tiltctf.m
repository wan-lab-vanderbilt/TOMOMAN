%% tomoman_run_tiltctf
% A function for running tomoman's tiltctf function to generate power
% spectra from a tilt stack, and using CTFFIND4 to determine defocus
% parameters.
%
% Tiltctf calculates power spectra by tiling images; tiles are taken at
% steps equal to half the power spectrum size along the tilt-axis (where
% the defocus is constnat) at steps equal to the desired defocus tolerance
% along the tilt axis. Off-axis angles are rescaled in Fourier space to
% match the Thon rings on the tilt axis; this is performed using linear
% rescaling and a scaling factor determined from a previously calculated
% lookup table.
%
% Tiltctf requires alignment and tilt files from IMOD to be in the stack
% folders.
%
% Scaling in Fourier space; i.e. fscaling=2 upscales the spectra by an 
% additional factor of two, effectively doubling the pixelsize and halving 
% the Nyquist frequency. This can help with aliasing of Thon rings for 
% small pixelsizes.Try to set this so that the maximum expected Thon rings
% end at around Nyquist.
%
% For CTFFIND4, defocus ranges are set based on def_range and
% target_defocus values. Minimum resolution is set as X%
% fraction Nyquist from the first node at the high end of the defocus 
% range.Maximum resolution is set to Nyquist. 
% 
% WW 07-2018
% SK 10-2020

%% Inputs


%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/tomo/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist_tiltctf.mat';     % Relative to root_dir
p.log_name = 'tomoman_tiltctf.log';           % Relative to root_dir


% tilctf parameters
tctf.force_run = 1;             % 1 = yes, 0 = no;
tctf.imod_stack = 'dose_filt';  % Which stack was used for IMOD alignment. Options are 'unfiltered' and 'dose_filt'.
tctf.ps_size = 512;          % Size of power-spectrum in pixels
tctf.def_tol = 0.05;         % Defocus tolerance in microns.
tctf.fscaling = 2;           % Scaling in Fourier space.
tctf.calc_ps = 1;           % 1 = to run ps calculation from scratch, 0 = to only run ctffind4 on already calculated ps
tctf.invert_tiltangle_sign = 0; % default = 0 = Do not invert the sign of tilt angles; 1 = invert the sign of the tilt angles.
tctf.ifgpu = 0;             % 1 = Use GPU.
tctf.gpudevice = 3;         % idex of the GPU. starting with 1!!!

% CTFFIND parameters
ctffind.ps_size = 512;             % Size of power-spectrum in pixels
ctffind.evk = 300;                 % Acceleration voltage
ctffind.cs = 2.7;                  % Spherical aberration
ctffind.famp = 0.07;               % Ampltidue contrast
ctffind.min_res = 45;              % Minimum resolution to fit
ctffind.max_res = 5;               % Maximum resolution to fit
ctffind.def_range = 0.5;           % Defocus tolerance in microns
ctffind.def_step = 0.01;           % Defocus search step in microns. Default is 0.01.
ctffind.known_astig = 0;           % Do you know what astigmatism is present? (0 = no, 1 = yes). Default is 0;
ctffind.slower = 1;                % Slower, more exhaustive search (0 = no, 1 = yes). Default is 0;
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
ctffind.nthreads = 10;             % Desired number of parallel threads. 



%% DO NOT CHANGE BELOW THIS LINE %%

% Debug options (DO NOT CHANGE THESE UNLESS YOU WERE ASKED TO!!)
tctf.write_unstretched = false;
tctf.write_negative = false;
tctf.visualdebug = false; 
tctf.xtiltoption = 0;             % 0 = Do not use, 1 = use as is, -1 = use inverse of xtilt, (Use -1 if you determined xtilt using IMOD's tomopitch)

%% Initalize

diary([p.root_dir,p.log_name]);
disp('TOMOMAN Initializing!!!');

% Read tomolist
if exist([p.root_dir,p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,p.tomolist_name]);
    
    % Creat backup if forcing tiltctf on top of ctffind4 (this is default anyways)
    if tctf.force_run
        datetime = clock;
        copyfile([p.root_dir,p.tomolist_name],[p.root_dir,p.tomolist_name,'.tiltctfbak',num2str(datetime(1)),num2str(datetime(2)),num2str(datetime(3)),'_',num2str(datetime(4)),num2str(datetime(5)),num2str(datetime(6))]);
    end
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
    
    % TiltCTF
    tomolist(t) = tomoman_tiltctf_ctffind4(tomolist(t),p,tctf,ctffind,write_list);
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');
   
    % Increment counter
    t = t+b_size;
end

diary off


