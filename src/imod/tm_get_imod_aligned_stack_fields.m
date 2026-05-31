function imod_fields = tm_get_imod_aligned_stack_fields()
%% tm_get_imod_aligned_stack_fields
% Return input fields for generating aligned stacks with IMOD. 
%
% WW 10-2025


%% Fields

imod_fields = {'erase_radius','num';...                     % Set to 'none' to skip. Radius (in pixels) for gold fiducial erasing. Requires a *_erase.fid file from IMOD.
               'ali_stack_bin','num';...                    % Binning factor of aligned stack prior to reconstruction. Set to 1 for no binning.
               'process_stack','str';...                    % Stack for processing. Either 'unfiltered' or 'dose-filtered'
               'ctfphaseflip','num';...                      % Apply stripwise CTF-correction using ctfphaseflip
               'deftolerance','num';...                     % Defocus tolerance in nm
               'interwidth','num';...                       % Interpolation width in pixels
               'maxwidth','num';...                         % Maximum strip width in pixels
               'output_dir','str';...                     % Output directory for aligned stacks, relative to root_dir.
               'subset_list','str';...                      % List of tomograms to be reconstructed; list is a plain-text file with a column of target tomo_num. Path is relative to root dir. Set to "none" to reconstruct all tomogmrams.
               'gpu_id','num';...                           % GPU ID's for IMOD Reconstruction. Set to 'none' for no GPUs.
               };





