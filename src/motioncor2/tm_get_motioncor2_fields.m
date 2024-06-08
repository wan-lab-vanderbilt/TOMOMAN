function mc2_fields = tm_get_motioncor2_fields()
%% tm_get_motioncor2_fields
% Return the fields for the MotionCor2 structs.
%
% WW 05-2022

%% Fields

mc2_fields = {'force_realign', 'boo', false;...         % Force realignment
              'image_size', 'num', [];...               % Crops or expands to image_size. Useful to produce image dimensions with integer binning factors (e.g. K2)
              'input_format', 'str', '';...             %  "tiff" or "mrc" or "eer"
              'dose_filter', 'boo', false;...           % Dose filter using MotionCor2 (not recommended...)
              'dose_filter_suffix', 'str', '';...       % Suffix to add to dose-filtered stack. 
              'ArcDir', 'str', '';...                   % Path of the archive folder
              'MaskCent', 'num', [0,0];...              % Center of subarea that will be used for alignement. Default is 0,0 corresponding to the frame center.
              'MaskSize', 'num', [1,1];...              % The size of subarea that will be used for alignment, default 1.0 1.0 corresponding full size.
              'Patch', 'num', [3,3];...                 % Number of patches to be used for patch based alignment, default 0 0 corresponding full frame alignment.
              'Iter', 'num', 5;...                      % Maximum iterations for iterative alignment, default 5 iterations.
              'Tol', 'num', 0.5;...                     % Tolerance for iterative alignment, default 0.5 pixel.
              'Bft', 'num', 100;...                     % B-Factor for alignment, default 100.
              'FtBin', 'num', 1;...                     % Binning performed in Fourier space, default 1.0.
              'Throw', 'num', 0;...                     % Throw initial number of frames, default is 0.
              'Trunc', 'num', 0;...                     % Truncate last number of frames, default is 0.
              'Group', 'num', '';...                    % Group every specified number of frames by adding them together. The alignment is then performed on the summed frames. By default, no grouping is performed.
              'FmRef', 'num', -1;...                    % Specify which frame to be the reference to which all other frames are aligned. By default (-1) the the central frame is chosen. The central frame is at N/2 based upon zero indexing where N is the number of frames that will be summed, i.e., not including the frames thrown away.
              'OutStack', 'boo', false;...              % Write out motion corrected frame stack. Default 0.
              'Align', 'num', 1;...                     % Generate aligned sum (1) or simple sum (0).
              'Tilt', 'num', '';...                     % Specify the starting angle and the step angle of tilt series. They are required for dose weighting. If not given, dose weighting will be disabled.
              'Mag', 'num', '';...                      % Correct anisotropic magnification by stretching image along the major axis, the axis where the lower magificantion is detected. Three inputs are needed including magnifications along major and minor axes and the angle of the major axis relative to the image x-axis in degree. By default no correction is performed.
              'Crop', 'num', '';...                     % Crop the loaded frames to the given size. By default the original size is loaded.
              'Gpu', 'num', 0;...                       % GPU IDs. Default 0. For multiple GPUs, separate IDs by space. For example, -Gpu 0 1 2 3 specifies 4 GPUs.
              'EerSampling', 'num', '';...              % EER sampling for final render. Set to 1 for 4k, and 2 for 8k. 
              'EerGrouping', 'num', '';...              % How many EER frames to group into a single dose fraction. REMEMBER, frames at the end of exposure that do not go into a whole fraction are discarded. 
              'FmIntFile', 'str', '';...                % Dose fractionation file. "Expert only" option. 
              'SplitSum', 'boo', false;...              % Write odd/even stacks for noise2noise training. 1 = true, 0 = false(default)
              };
              

        
end
