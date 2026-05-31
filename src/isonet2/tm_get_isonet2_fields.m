function isonet2_fields = tm_get_isonet2_fields(task)
%% tm_get_isonet2_fields
% Return parameter fields for a given tomoman_isonet2 task. 
%
% WW 02-2026

%% Get fields

switch task
    case 'isonet2_prepare'
        isonet2_fields = {'isonet2_dir', 'str', 'isonet2/';...                   % Relative to root_dir
                          'tomo_subdir', 'str', 'wbp_tomo/';...                  % Relative to isonet2_dir. Tomograms are reconstructed into ODD, EVN, and AVG subfolders.
                          'star_filename', 'str',  'isonet2.star';...            % Filename of output star file. This goes into the isonet2_dir.
                          'subset_list', 'str', [];...                           % List containing tomo_num values for processing.
                          'reconstruct_tomos', 'boo', true;...                   % Whether to reconstruct tomograms. 1', 'yes, 0', 'just create star file.
                          'erase_radius', 'str', [];...                          % Set to 'none' to skip. Radius (in pixels) for gold fiducial erasing. Requires a *_erase.fid file from IMOD.
                          'process_stack', 'str', [];...                         % Stack for processing. Either 'unfiltered' or 'dose-filtered'
                          'binning', 'num', [];...                               % Binning factor of aligned stack prior to reconstruction. Set to 1 for no binning.
                          'number_subtomos','num',3000;...                         % Number of subtomograms to extract per tomogram.
                          'gpuID','num',[];...                                   % The ID of gpu to be used for IMOD reconstruction.
                          };
        
    case 'isonet2_denoise'
        isonet2_fields = {'isonet2_dir', 'str', 'isonet2/';...                              % Relative to root_dir
%                          'tomo_subdir', 'str', 'wbp_tomo/';...                             % Relative to isonet2_dir. Tomograms are reconstructed into ODD, EVN, and AVG subfolders.
                          'denoise_training_subdir', 'str', 'denoise_training/';...         % Relative to isonet2_dir. Output directory for denoising models
                          'denoise_predict_subdir', 'str', 'denoise_tomos/';...             % Relative to isonet2_dir. Output directory for denoised tomograms
                          'star_filename', 'str', 'isonet2.star';...                        % Filename of output star file. This goes into the isonet2_dir.
                          'ncpus', 'num', '16';...                                          % Number of CPUs to use for data processing
                          'gpuID', 'num', '3';...                                           % ID of GPU to use for processing
                          'run_denoise_training', 'boo', '1';...                            % Run denoise training. If set to 0, training is skipped and the latest model in the denoise_training_subdir is used.
                          'training_subset_list', 'str', 'none';...                         % List containing tomo_num values for training.
                          'continue_training', 'boo', '0';...                               % Continue training on a pretrained model.
                          'run_denoise_prediction', 'boo', '1';...                          % Run denoise prediction. If set to 0, training is skipped and only training is run
                          'predict_subset_list', 'str', 'none';...                          % Subset to use for predictoin
                          'arch', 'str', 'unet_medium';...                                  % Network architecture string (e.g., unet-small, unet-medium, unet-large). Determines model capacity and VRAM requirements. Default: "unet-medium".
                          'batch_size', 'str', 'auto';...                                   % Number of subtomograms per optimization step; if "auto", this is automatically determined by multiplying the number of available GPUs by 2. If the number of GPUs is 1, batch size is 4. Batch size per GPU matters for gradient stability. Default: "auto".
                          'bfactor', 'str', '0';...                                         % B-factor applied during training/prediction to boost high-frequency content. For cellular tomograms we recommend a b-factor of 0. For isolated samples, you can use a b-factor from 200–300. Default: 0.
                          'clip_first_peak_mode', 'str', '1';...                            % Controls attenuation of overrepresented very-low-frequency CTF peak. Options 2 and 3 might increase low-resolution contrast. Default: 1.
                          'CTF_mode', 'str', 'network';...                                  % CTF handling mode: "None", "phase_only", "wiener", or "network". Default: "None".
                          'cube_size', 'str', '96';...                                      % Size in voxels of training subvolumes. Must be compatible with the network (divisible by the network downsampling factors). This allows any multiple of 16 >= 64. Default: 96.
                          'deconvstrength', 'str', '1';...                                  % Scalar multiplier for deconvolution strength; increasing this emphasizes correction and low-frequency recovery. Default: 1.0.
                          'do_phaseflip_input', 'boo', '1';...                              % Whether to apply phase flip during training. Default: True.
                          'epochs', 'str', '50';...                                         % Number of training epochs. Default: 50.
                          'highpassnyquist', 'str', '0.02';...                              % Fraction of the Nyquist used as a very-low-frequency high-pass cutoff; use to remove large-scale intensity gradients and drift. Default: 0.02.
                          'isCTFflipped', 'boo', '0';...                                    % Whether input tomograms are phase flipped. Default: False.
                          'learning_rate', 'str', '3e-4';...                                % Initial learning rate. Default: 3e-4.
                          'learning_rate_min', 'str', '3e-4';...                            % Minimum learning rate for scheduler. Default: 3e-4.
                          'loss_func', 'str', 'L2';...                                      % Loss function to use (L2, Huber, L1). Default: "L2".
                          'mixed_precision', 'boo', '1';...                                 % If True, uses float16/mixed precision to reduce VRAM and speed up training. Default: True.
                          'save_interval', 'str', '10';...                                  % Interval to save model checkpoints. Default: 10.
                          'snrfalloff', 'str', '0';...                                      % Controls frequency-dependent SNR attenuation applied during deconvolution; larger values reduce high-frequency contribution more aggressively. Default: 0.
                          'with_preview', 'boo', '0';...                                    % If True, run prediction every save interval. Default: True.
                          };
        
    case 'isonet2_make_mask'
        isonet2_fields = {'isonet2_dir', 'str', 'isonet2/';...                              % Relative to root_dir
                          'mask_subdir', 'str', 'masks/';...                                % Relative to isonet2_dir. 
                          'star_filename', 'str', 'isonet2.star';...                        % Filename of output star file. This goes into the isonet2_dir.
                          'subset_list', 'str', 'none';...                                  % List containing tomo_num values for processing.
                          'density_percentage', 'str', '50';...                             % Percentage of voxels retained based on local density ranking; lower values create stricter masks (keep fewer voxels). Default: 50.
                          'std_percentage', 'str', '50';...                                 % Percentage retained based on local standard-deviation ranking; lower values emphasize textured regions. Default: 50.
                          'patch_size', 'str', '4';...                                      % Local patch size used for max/std local filters; larger values smooth detection of specimen regions; default works for typical pixel sizes. Default: 4.
                          'z_crop', 'str', '0.2';...                                        % Fraction of tomogram Z to crop from both ends; masks out top and bottom 10% each when set to 0.2. Use to avoid sampling low-quality reconstruction edges. Default: 0.2.
                          };
                      
    case 'isonet2_make_particle_mask'
        isonet2_fields = {'isonet2_dir', 'str', 'isonet2/';...                  % Relative to root_dir
                          'mask_subdir', 'str', 'masks/';...                    % Relative to isonet2_dir. 
                          'star_filename', 'str', 'isonet2.star';...            % Filename of output star file. This goes into the isonet2_dir.
                          'subset_list', 'str', 'none';...                      % List containing tomo_num values for processing.
                          'process_stack', 'str', 'dose-filtered';...       % Stack used for processing. Either 'unfiltered' or 'dose-filtered'
                          'sg_motl_name', 'str', 'motl.star';...            % STOPGAP-formatted motivelist 
                          'point_list', 'str', 'none';...                   % Plain text file containing 3D positions; substitute for STOGAP motivelist. Columns are tomo_num, x, y, z. 
                          'boxsize', 'num', '48';...                        % Edge size for particle box. Cubic boxes are placed at each particle position to generate the mask.
                          'list_binning', 'num', '8';...                    % Binning of the input motivelist or point list. If different from the mask binning, the list will be rescaled accordingly.
                          'mask_binning', 'num', '8';...                    % Binning of the output mask.
                        };
                      
    case 'isonet2_refine'
        isonet2_fields = {'isonet2_dir', 'str', 'isonet2/';...                              % Relative to root_dir
                          'refine_training_subdir', 'str', 'refine_training/';...           % Relative to isonet2_dir. Output directory for denoising models
                          'refine_predict_subdir', 'str', 'refine_tomos/';...               % Relative to isonet2_dir. Output directory for denoised tomograms
                          'star_filename', 'str', 'isonet2.star';...            % Filename of output star file. This goes into the isonet2_dir.
                          'ncpus', 'num', '16';...                              % Number of CPUs to use for data processing
                          'gpuID', 'num', '3';...                               % ID of GPU to use for processing
                          'run_refine_training', 'boo', '1';...                 % Run denoise training. If set to 0, training is skipped and the latest model in the denoise_training_subdir is used.
                          'training_subset_list', 'str', 'none';...             % List containing tomo_num values for training.
                          'continue_training', 'boo', '0';...                   % Continue training on a pretrained model.
                          'run_refine_prediction', 'boo', '1';...               % Run denoise prediction. If set to 0, training is skipped and only training is run
                          'predict_subset_list', 'str', 'none';...              % Subset to use for predictoin
                          'apply_mw_x1', 'str', 'true';...                      % Whether to apply missing wedge to subtomograms at the beginning. Default: True.
                          'arch', 'str', 'unet-medium';...                      % Network architecture string (e.g., unet-small, unet-medium, unet-large, scunet-fast). Determines model capacity and VRAM requirements. Default: "unet-medium".
                          'batch_size', 'str', 'none';...                       % Number of subtomograms per optimization step; if None, this is automatically determined by multiplying the number of available GPUs by 2. If the number of GPUs is 1, batch size is 4. Batch size per GPU matters for gradient stability. Default: None.
                          'bfactor', 'str', '0';...                             % B-factor applied during training/prediction to boost high-frequency content. For cellular tomograms we recommend a b-factor of 0. For isolated samples, you can use a b-factor from 200–300. Default: 0.
                          'clip_first_peak_mode', 'str', '1';...                % Controls attenuation of overrepresented very-low-frequency CTF peak. Options 2 and 3 might increase low-resolution contrast. Default: 1. 0 none; 1 constant clip; 2 negative sine; 3 cosine
                          'CTF_mode', 'str', 'network';...                      % CTF handling mode: "None", "phase_only", "wiener", or "network". Default: "None".
                          'cube_size', 'str', '96';...                          % Size in voxels of training subvolumes. Must be compatible with the network (divisible by the network downsampling factors). This allows any multiple of 16 >= 64. Default: 96.
                          'deconvstrength', 'str', '1';...                      % Scalar multiplier for deconvolution strength; increasing this emphasizes correction and low-frequency recovery but can introduce ringing/artifacts if set too high. Default: 1.0.
                          'do_phaseflip_input', 'str', 'true';...               % Whether to apply phase flip during training. Default: True.
                          'epochs', 'str', '50';...                             % Number of training epochs. Default: 50.
                          'highpassnyquist', 'str', '0.02';...                  % Fraction of the Nyquist used as a very-low-frequency high-pass cutoff; use to remove large-scale intensity gradients and drift; usually left at default. Default: 0.02.
                          'isCTFflipped', 'str', 'false';...                    % Whether input tomograms are phase flipped. Default: False.
                          'learning_rate', 'str', '3e-4';...                    % Initial learning rate. Default: 3e-4.
                          'learning_rate_min', 'str', '3e-4';...                % Minimum learning rate for scheduler. Default: 3e-4.
                          'loss_func', 'str', 'L2';...                          % Loss function to use (L2, Huber, L1). Default: "L2".
                          'method', 'str', 'isonet2-n2n';...                    % "isonet2" for single-map missing-wedge correction, "isonet2-n2n" for noise2noise when even/odd halves are present. If omitted, the code auto-detects the method from the STAR columns. Default: "None" (auto-detect).
                          'mixed_precision', 'boo', 'true';...                  % If True, uses float16/mixed precision to reduce VRAM and speed up training. Default: True.
                          'mw_weight', 'str', '-1';...                          % Weight for missing wedge loss. Higher values correspond to stronger emphasis on missing wedge regions. Disabled by default. Default: -1 (disabled).
                          'noise_level', 'str', '0';...                         % Adds artificial noise during training. Default: 0.
                          'noise_mode', 'str', 'nofilter';...                   % Controls filter applied when generating synthetic noise (None, ramp, hamming). Default: "nofilter".
                          'prev_tomo_idx', 'str', '1';...                       % If set, automatically predict only the tomograms listed by these indices (e.g., "1,2,4" or "5-10,15,16"). Default: 1.
                          'random_rot_weight', 'str', '0.2';...                 % Percentage of rotations applied as random augmentation. Default: 0.2.
                          'save_interval', 'str', '10 ';...                     % Interval to save model checkpoints. Default: 10.
                          'snrfalloff', 'str', '0';...                          % Controls frequency-dependent SNR attenuation applied during deconvolution; larger values reduce high-frequency contribution more aggressively and can stabilize deconvolution on noisy data; smaller values preserve more high-frequency content but risk amplifying noise. Default: 0.
                          'with_preview', 'boo', 'false';...                    % If True, run prediction every save interval. Default: True.
                          };
end




