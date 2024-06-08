function imod_fields = tm_get_imod_recons_fields()
%% tm_get_imod_recons_fields
% Return input fields for IMOD reconstruction. 
%
% WW 07-2023


%% Fields

imod_fields = {'n_cores','num';...                           % Number of cores for parallel processing. Parallel processing is only for building stacks; tomogram reconstruction and binning is not parallelized.
               'gpu_id','num';...                           % GPU ID's for IMOD Reconstruction. Set to 'none' for no GPUs.
               'ali_dim','num';...                          % Size of aligned stack. (Typically 4096,4096 for Falcon 4 and 4092,5760 for K3)
               'erase_radius','num';...                     % Set to 'none' to skip. Radius (in pixels) for gold fiducial erasing. Requires a *_erase.fid file from IMOD.
               'taper_pixels','num';...                     % Taper edges of rotated image after generating aligned stack. Uses IMOD's mrctaper function.
               'ali_stack_bin','num';...                    % Binning factor of aligned stack prior to reconstruction. Set to 1 for no binning.
               'process_stack','str';...                    % Stack for processing. Either 'unfiltered' or 'dose-filtered'
               'ctfphaseflip','num';...                      % Apply stripwise CTF-correction using ctfphaseflip
               'deftolerance','num';...                     % Defocus tolerance in nm
               'interwidth','num';...                       % Interpolation width in pixels
               'maxwidth','num';...                         % Maximum strip width in pixels
               'cs','num';...                               % Spherical abberation.
               'famp','num';...                             % Phase amplitude. This should match what you used for CTF estimation.
               'radial','num';...                           % RADIAL parameter from the IMOD tilt function. Set to 'none' to skip.
               'fakesirtiter','num';                        % fake SIRT iterations for better contrast!'
               'tomo_bin','num';...                         % Final output binning parameters.
               'output_dir_prefix','str';...                 % Prefix of output directory, relative to root_dir. For example, if prefix is "novactf_" and tomo_bin is "1,2", then output directories are novactf_bin1/ and novactf_bin2/.
               'recons_list','str';...                      % List of tomograms to be reconstructed; list is a plain-text file with a column of target tomo_num. Path is relative to root dir. Set to "none" to reconstruct all tomogmrams.
               'f3d_memlimit','num';...                     % Memory limit for Fourier3D. Fourier3D is used to bin tomograms by Fourier cropping.
               };





