%% tomoman_run.m
% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 
%
% WW 04-2018

%% Inputs

% Directory parameters
p.root_dir = '/fs/gpfs03/lv03/pool/pool-plitzko/will_wan/hempelmann/batch_test/sorting/';  % Root folder for dataset; stack directories will be generated here.
p.raw_stack_dir = [p.root_dir,'start/'];         % Folder containing raw stacks
p.raw_frame_dir = [p.root_dir,'frames/'];      % Folder containing unsorted frames

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

% Filename parameters
p.prefix = 'TS_';      % Beginning of stack/mdoc names (e.g. stackname is [prefix][tomonum].[raw_stack_ext])
p.digits = 1;         % Number of digits (i.e. leading zeros; e.g. 02 is digits=2, 002 is digits=3)
p.raw_stack_ext = '.st';  % File extension of raw stacks

% Data collection parameters
p.gainref = [p.root_dir,'none'];       % For no gainref, set to 'none'
p.defects_file = [p.root_dir,'none'];   % For no defects_file, set to 'none'
p.rotate_gain = 0;                                                  % Gain ref rotation
p.flip_gain = 0;                                                    % Gain ref flip; 0 = none, 1 = up/down, 2 = left/right
p.os = 'windows';                                                   % Operating system for data collection. Options are 'windows' and 'linux'
p.mirror_stack = 'n';                                               % Mirror images. For Titan2, use 'y'. For MiKrios set to 'none';


% Overrides (set to '' for no override)
ov.tilt_axis_angle = '';    % Tilt axis angle in degrees
ov.dose_rate = 20;  % e/pixel/s
ov.pixelsize = 2.156;  % Pixel size in Angstroms

%%%% Batch mode %%%%
batch_mode = 'single';  % 'single' runs a single stack through the whole pipeline before the next stack. 'step' runs all stacks through each step before progressing to the next step.


%%%% Find and sort new stacks? %%%%
s.sort_new = 1;                       % 1 = yes, 0 = no;
s.ignore_raw_stacks = 0;              % Move files even if raw stack is missing
s.ignore_missing_frames = 0;          % Move files even if frames are missing

%%%% Stack parameters %%%%
st.update_stack = 0;                 % Update stack parameters. 1 = yes, 0 = no; 
st.image_size = [5760,4092];         % I would suggest 3712, as this allows for a wide range of base2 binning. Images will be padded by copying edge pixels.
st.stack_prefix = 'TS_';             % Add prefix to stack names. Otherwise, stack names are [tomonum].st.
st.tilt_order = 'descend';            % Tilt order of the input stacks. Either 'ascend' or 'descend'. It appears that stacks from alignframes are ascending.
st.prealigned = 'alignframes';       % If stacks are already frame-aligned, provide name of alignment algorithm. Otherwise, leave empty.

%%%% Align frames / generate stack %%%%
% MotionCor2 parameters
mc2.ali_frames = 0;                     % 1 = yes, 0 = no;
mc2.force_realign = 0;                  % 1 = yes, 0 = no;
mc2.input_format = 'mrc';    % 'tiff' or 'mrc'
mc2.dose_filter = 0;          % Dose filter using MotionCor2 (not recommended...)
mc2.dose_filter_suffix = '';  % Suffix to add to dose-filtered stack. 
mc2.ArcDir = '';              % Path of the archive folder
mc2.MaskCent = [];            % Center of subarea that will be used for alignement,default 0 0 corresponding to the frame center.
mc2.MaskSize = [];            % The size of subarea that will be used for alignment, default 1.0 1.0 corresponding full size.
mc2.Patch = [3,3];            % Number of patches to be used for patch based alignment, default 0 0 corresponding full frame alignment.
mc2.Iter = 7;                 % Maximum iterations for iterative alignment, default 5 iterations.
mc2.Tol = 0.5;                % Tolerance for iterative alignment, default 0.5 pixel.
mc2.Bft = [];                 % B-Factor for alignment, default 100.
mc2.FtBin = [];               % Binning performed in Fourier space, default 1.0.
mc2.kV = [];                  % High tension in kV needed for dose weighting. Default is 300.
mc2.Throw = [];               % Throw initial number of frames, default is 0.
mc2.Trunc = [];               % Truncate last number of frames, default is 0.
mc2.Group = [];               % Group every specified number of frames by adding them together. The alignment is then performed on the summed frames. By default, no grouping is performed.
mc2.FmRef = [];               % Specify which frame to be the reference to which all other frames are aligned. By default (-1) the the central frame is chosen. The central frame is at N/2 based upon zero indexing where N is the number of frames that will be summed, i.e., not including the frames thrown away.
mc2.OutStack = 0;            % Write out motion corrected frame stack. Default 0.
mc2.Align = [];               % Generate aligned sum (1) or simple sum (0)
mc2.Tilt = [];                % Specify the starting angle and the step angle of tilt series. They are required for dose weighting. If not given, dose weighting will be disabled.
mc2.Mag = [];                 % 1. Correct anisotropic magnification by stretching image along the major axis, the axis where the lower magificantion is detected. 2. Three inputs are needed including magnifications along major and minor axes and the angle of the major axis relative to the image x-axis in degree. 3. By default no correction is performed.
mc2.Crop = [];                % 1. Crop the loaded frames to the given size. 2. By default the original size is loaded.
mc2.Gpu = 3;                  % GPU IDs. Default 0. For multiple GPUs, separate IDs by space. For example, -Gpu 0 1 2 3 specifies 4 GPUs.


%%%% Clean stacks %%%%
c.clean_stacks = 0;
c.force_cleaning = 0;     % 1 = yes, 0 = no;
c.clean_binning = 4;      % Binning to open 3dmod with
c.clean_append = '';      % Append to name for cleaned stack. Setting blank ('') overwrites old file.


%%%% Dose filter stacks %%%%
df.dose_filter = 0;                 % 1 = yes, 0 = no;
df.force_dfilt = 0;                 % 1 = yes, 0 = no;
df.dfilt_append = '_dose-filt';     % Append name to dose-filtered stack. Empty ('') overwrites stack; this is NOT recommended...
df.filter_frames = 0;               % Dose filter frames instead of images. In order to do this, the OutStack MotionCor2 parameter must have been used to generate aligned frame stacks.
df.preexposure = 0;                 % Pre-exposure prior to initial image collection.
df.a = '';                          % Resolution-dependent critical exposure constant 'a'. Leave emtpy ('') to use default.
df.b = '';                          % Resolution-dependent critical exposure constant 'b'. Leave emtpy ('') to use default.
df.c = '';                          % Resolution-dependent critical exposure constant 'c'. Leave emtpy ('') to use default.


%%%% IMOD preprocess %%%%
imod_param.imod_preprocess = 1;               % 1 = yes, 0 = no;
imod_param.force_imod = 0;                    % 1 = yes, 0 = no;
% Copytomocoms
imod_param.copytomocoms = 1;       % Run copytomocoms
imod_param.goldsize = 6;          % Gold diameter (nm)
% CCD Eraser
imod_param.ccderaser = 1;          % Run CCD Eraser
imod_param.archiveoriginal = 0;    % Archive and delete original stack
% Coarse alignment
imod_param.coarsealign = 1;        % Perform coarse alignment 
imod_param.coarsealignbin = 2;     % Bin factor for coarse alignment
imod_param.coarseantialias = -1;   % Antialiasing filter for coarse alignment
imod_param.convbyte = '/';         % Convert to bytes: '/' = no, '0' = yes
% Autoseed and beadtrack
imod_param.autoseed = 0;           % Run autofidseed and beadtrack
imod_param.localareatracking = 1;  % Local area bead tracking (1=yes,0=no)
imod_param.localareasize = 1000;   % Size of local area
imod_param.sobelfilter = 1;        % Use Sobel filter (1=yes,0=no)
imod_param.sobelkernel = 1.5;      % Sobel filter kernel (default 1.5)
imod_param.n_rounds = 2;           % Number of rounds of tracking in run (default = 2)
imod_param.n_runs = 2;             % Number of times to run beadtrack (default = 2)
imod_param.two_surf = 2;           % Track beads on two surfaces (1=yes,0=no) 
imod_param.n_beads = 100;          % Target number of beads
imod_param.adjustsize = 1;         % Adjust size of beads based on average bead size (1=yes,0=no) 


%%%% GCTF %%%%
gctf_param.run_gctf = 0;                     % 1 = yes, 0 = no;
gctf_param.force_gctf = 0;                   % 1 = yes, 0 = no;
gctf_param.input_type = 'stack';             % What to use as input for gctf. 'stack' for image stack or 'frames' for raw frames.
% Normal options(should specify)
gctf_param.kV = 300;                         % High tension in Kilovolt, typically 300, 200 or 120
gctf_param.cs = 2.7;                         % Spherical aberration, in  millimeter
gctf_param.ac = 0.07;                        % Amplitude contrast; normal range 0.04~0.1; pure ice 0.04, carbon 0.1; but doesn't matter too much if using wrong value
% Phase plate options:  
gctf_param.determine_pshift = 0;             % Determine phase shift. 1 = yes, 0 = no. (default = 0)
gctf_param.phase_shift_L = 0.0;              % User defined phase shift, lowest phase shift,  in degree; typically, ~90.0 for micrographs using phase plate 
gctf_param.phase_shift_H = 180.0;            % User defined phase shift, highest phase shift, final range will be (phase_shift_L, phase_shift_H)  
gctf_param.phase_shift_S = 10.0;             % User defined phase shift search step; don't worry about the accuracy; this is just the search step, Gctf will refine the phase shift anyway.
gctf_param.phase_shift_T = 1;                % Phase shift target in the search; 1: CCC; 2: resolution limit; 
% Additional options (Note: TOMOMAN automatically sets the defocus low and high parameters {defL,defH} using the defocus_width and the target_defocus.)
gctf_param.dstep = 14.0;                     % Detector size in micrometer; don't worry if unknown; just use default. (default = 14.0)
gctf_param.defWidth = 20000;                 % Range to search around target defocus (Angstroms); i.e. range will be (TargetDefocus - defWidth) -- (TargetDefocus + defWidth).
gctf_param.defS = 500;                       % Step of defocus value used to search, in angstrom (default = 500)
gctf_param.astm = 1000;                      % Estimated astigmation in angstrom, don't need to be accurate, within 0.1~10 times is OK (default = 1000)
gctf_param.bfac = 150;                       % Bfactor used to decrease high resolution amplitude,A^2; NOT the estimated micrograph Bfactor! suggested range 50~300 except using 'REBS method'. (default = 150)
gctf_param.resL = 50;                        % Lowest Resolution to be used for search, in angstrom (default = 50)
gctf_param.resH = 4;                         % Highest Resolution to be used for search, in angstrom (default = 4)
gctf_param.boxsize = 512;                    % Boxsize in pixel to be used for FFT, 512 or 1024 highly recommended (default = 1024)
% Advanced additional options:  
gctf_param.do_EPA = 1;                       % 1: Do Equiphase average; 0: Don't do;  only for nice output, will NOT be used for CTF determination. (default = 0)
gctf_param.EPA_oversmp = 4;                  % Over-sampling factor for EPA. (default = 4)
gctf_param.overlap = 0.5;                    % Overlapping factor for grid boxes sampling, for boxsize=512, 0.5 means 256 pixeles overlapping (default = 0.5)
gctf_param.convsize = 85;                    % Boxsize to be used for smoothing, suggested 1/10 ~ 1/20 of boxsize in pixel, e.g. 40 for 512 boxsize (default = 85)
% High resolution refinement options:  
gctf_param.do_Hres_ref = 0;                  % Whether to do High-resolution refinement or not, very useful for selecting high quality micrographs (default = 0)
gctf_param.Href_resL = 15.0;                 % Lowest Resolution  to be used for High-resolution refinement, in angstrom (default = 15.0)
gctf_param.Href_resH = 4.0;                  % Highest Resolution  to be used for High-resolution refinement, in angstrom (default = 4.0)
gctf_param.Href_bfac = 50;                   % Bfactor to be used for High-resolution refinement,A^2 NOT the estimated micrograph Bfactor! (default = 50)
% Bfactor estimation options:  
gctf_param.B_resL = 15.0;                    % Lowest resolution for Bfactor estimation; This output Bfactor is the real estimation of the micrograph (default = 15)
gctf_param.B_resH = 6.0;                     % Highest resolution for Bfactor estimation (default = 6)
% Movie options to calculate defocuses of each frame:  
gctf_param.do_mdef_refine = 0;               % Whether to do CTF refinement of each frames, by default it will do averaged frames. Not quite useful at the moment, but maybe in future. (default = 0)
gctf_param.mdef_aveN = 1;                    % Average number of movie frames for movie or particle stack CTF refinement (default = 1)
gctf_param.mdef_fit = 0;                     % 0: no fitting; 1: linear fitting defocus changes in Z-direction (default = 0)
gctf_param.mdef_ave_type = 0;                % 0: coherent average, average FFT with phase information(suggested for movies); 1:incoherent average, only average amplitude(suggested for particle stack); (default = 0)
% CTF refinement options(to refine user provided CTF parameters):  
gctf_param.refine_input_ctf = 0;             % 1: to refine user provided CTF; 0: By default Gctf wil NOT refine user-provided CTF parameters but do ab initial determination, even if the '--input_ctfstar' is provided; (default = 0)
gctf_param.input_ctfstar = 'none';           % Input file name with previous CTF parameters
gctf_param.defU_init = 20000.0;              % User input initial defocus_U, only for single micrograph, use '--input_ctfstar' for multiple micrographs. (default = 20000)
gctf_param.defV_init = 20000.0;              % User input initial defocus_V, only for single micrograph, use '--input_ctfstar' for multiple micrographs. (default = 20000)
gctf_param.defA_init = 0.0;                  % User input initial defocus_Angle, only for single micrograph, use '--input_ctfstar' for multiple micrographs. (default = 0)
gctf_param.B_init = 200.0;                   % User input initial Bfactor, only for single micrograph, use '--input_ctfstar' for multiple micrographs. (default = 200)
gctf_param.defU_err = 500.0;                 % Estimated error of user input initial defocus_U, unlike defU_init, this will be effective for all micrographs. (default = 500)
gctf_param.defV_err = 500.0;                 % Estimated error of user input initial defocus_V, unlike defV_init, this will be effective for all micrographs. (default = 500)
gctf_param.defA_err = 15.0;                  % Estimated error of user input initial defocus_Angle,  unlike defA_init, this will be effective for all micrographs.
gctf_param.B_err = 50.0;                     % Estimated error of user input initial Bfactor, unlike B_init, this will be effective for all micrographs. (default = 50)
% Validation options:  
gctf_param.do_validation = 0;                % Whether to validate the CTF determination. (default = 0)
% CTF output file options:  
gctf_param.ctfout_resL = 100.0;              % Lowest resolution for CTF diagnosis file. NOTE this only affects the final output of .ctf file, nothing related to CTF determination. (default = 100)
gctf_param.ctfout_resH = '';                 % Highest resolution for CTF diagnosis file, ~Nyqiust by default.
gctf_param.ctfout_bfac = 50;                 % Bfactor for CTF diagnosis file. NOTE this only affects the final output of .ctf file, nothing related to CTF determination. (default = 50)
% I/O options:  
gctf_param.input_ctfstar = '';     % Input star file (must be star file) containing the raw micrographs and CTF information for further refinement.
gctf_param.boxsuffix = '';                    % Input .box/.star in EMAN/Relion box format, used for local refinement
gctf_param.ctfstar = '';            % Output star files to record all CTF parameters. Use 'NULL' or 'NONE' to skip writing out the CTF star file.
gctf_param.logsuffix = '';                          % Output suffix to be used for log files.                                                             ### NOTE: use '_ctffind3.log' for old version of Relion( before 1.4), because it needs this suffix for particle extraction! Otherwise, you can change the suffix of CTF log files by 'rename _gctf.log _ctffind3.log *_gctf.log' and then extract your particles.
gctf_param.write_local_ctf = 0;                              % Whether to write out a diagnosis power spectrum file for each particle.
gctf_param.plot_res_ring = 1;                                % Whether to plot an estimated resolution ring on the final .ctf diagnosis file 
gctf_param.do_unfinished = [];                               % Specify this option to continue processing the unfinished, otherwise it will overwrite everything. 
gctf_param.skip_check_mrc = [];                              % Specify this option to skip checking the MRC file format. Sometimes, there are special MRC that the file size does not match head information. To force Gctf run on such micrograph, specify this option might help to solve the problem.
gctf_param.skip_check_gpu = [];                              % Specify this option to skip checking the GPUs.
gctf_param.gid = 3;                                          % GPU id, normally it's 0, use gpu_info to get information of all available GPUs.



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

%% Check dependencies

% List of dependent commands
dependencies = {'gctf','motioncor2','3dmod','newstack'};

% Loop through and test commands
for i = 1:numel(dependencies)
    [test,~] = system(['which ',dependencies{i}]);
    if test == 1
        error(['ACHTUNG!!! ',dependencies{i},' not found!!! Source the package prior to running MATLAB!!!']);
    end
end



%% Sort new stacks
 
 % Must be run all together...
 if s.sort_new == 1
     % Sort stacks
     tomolist = tomoman_sort_new_stacks(p,ov,s,tomolist);
     
     % Write tomolist
     save([p.root_dir,p.tomolist_name],'tomolist');
 end
 
 
 
%% Run pipeline!!!

% Set batchmode settings 
n_tilts = size(tomolist,2);
switch batch_mode
    case 'single'
        b_size = 1;
        write_list = false;
        t = 1;
    case 'step'
        b_size = n_tilts;
        write_list = true;
        t = 1:n_tilts;
end

while all(t <= n_tilts)

    % Check tomogram parameters
    if st.update_stack == 1
        tomolist(t) = tomoman_stack_param(tomolist(t),st);
        % Write tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');
    end
    
    % Align frames
    if mc2.ali_frames == 1    
        % Align frames and generate stack
        tomolist(t) = tomoman_motioncor2_newstack(tomolist(t),p,st,mc2,write_list);
        % Write tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');
    end


    % Clean stacks
    if c.clean_stacks == 1    
        % Clean stacks
        tomolist(t) = tomoman_clean_stacks(tomolist(t),p,c,st,write_list);     
        % Save tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');     
     end

    % Apply dose filter
    if df.dose_filter == 1
        % Dose filter
        tomolist(t) = tomoman_exposure_filter(tomolist(t),p,st,df,write_list);
        % Save tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');
    end

    % IMOD preprocess
    if imod_param.imod_preprocess == 1    
        % Preprocess
        tomolist(t) = tomoman_imod_preprocess(tomolist(t), p, imod_param, write_list);
        % Save tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');
    end

    % GCTF
    if gctf_param.run_gctf == 1    
        % Preprocess
        tomolist(t) = tomoman_gctf(tomolist(t), p, gctf_param, write_list);
        % Save tomolist
        save([p.root_dir,p.tomolist_name],'tomolist');
    end
    
    % Increment counter
    t = t+b_size;
end

diary off



















