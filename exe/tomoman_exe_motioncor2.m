% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-plitzko/Sagar/software/sagar/tomoman/10-2020/test/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

%%%% Align frames / generate stack %%%%
a.force_realign = 1;                  % 1 = yes, 0 = no;
a.image_size = [4096,4096];           % I would suggest 3712, as this allows for a wide range of base2 binning. Images will be padded by copying edge pixels.
a.stack_prefix = 'AUTO';                   % Add prefix to stack names. Otherwise, stack names are [tomonum].st.
% MotionCor2 parameters
mc2.input_format = 'eer';    % 'tiff' or 'mrc' or 'eer'
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
mc2.OutStack = 1;            % Write out motion corrected frame stack. Default 0.
mc2.Align = 1;               % Generate aligned sum (1) or simple sum (0)
mc2.Tilt = [];                % Specify the starting angle and the step angle of tilt series. They are required for dose weighting. If not given, dose weighting will be disabled.
mc2.Mag = [];                 % 1. Correct anisotropic magnification by stretching image along the major axis, the axis where the lower magificantion is detected. 2. Three inputs are needed including magnifications along major and minor axes and the angle of the major axis relative to the image x-axis in degree. 3. By default no correction is performed.
mc2.Crop = [];                % 1. Crop the loaded frames to the given size. 2. By default the original size is loaded.
mc2.Gpu = '2 3';                  % GPU IDs. Default 0. For multiple GPUs, separate IDs by space. For example, -Gpu 0 1 2 3 specifies 4 GPUs.

%% EER specific part
mc2.EerSampling = 1;        % EER sampling for final render. Set to 1 for 4k, and 2 for 8k. 
mc2.EerGrouping = 15;       % How many EER frames to group into a single dose fraction. REMEMBER, frames at the end of exposure that do not go into a whole fraction are discarded. 
mc2.FmIntFile = '';         % Dose fractionation file. "Expert only" option. 


%% Odd/even stacks for noise2noise training
mc2.SplitSum = 1;              % write odd/even stacks. 1 = true, 0 = false(default);


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
    
    % Align frames and generate stack
    tomolist(t) = tomoman_motioncor2_newstack(tomolist(t),p,a,mc2,write_list);
    % Write tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');

    
    t = t+b_size;
    
end

diary off