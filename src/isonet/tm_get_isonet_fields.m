function isonet_fields = tm_get_isonet_fields(task)
%% tm_get_isonet_fields
% Return parameter fields for a given tomoman_isonet task. 
%
% WW 06-2025

%% Get fields

switch task
    case 'isonet_prepare'
        isonet_fields = {'process_stack','str',[];...                       % Stack was used tomogram reconstruction
                         'tomo_dir','str',[];...                            % Directory with tomograms
                         'tomo_binning','num',[];...                        % Binning of the tomograms
                         'isonet_dir','str','isonet';...                    % Directory for IsoNet processing
                         'output_star','str','tomograms.star';...           % star file similar to that from "relion". You can modify this file manually or with gui.
                         'number_subtomos','num',100;...                    % Number of subtomograms to be extracted in later processes. If you want to extract different number of subtomograms in different tomograms, you can modify them in the star file generated with this command or with gui.
                         'run_deconv','boo',true;...                        % Run deconvolution. 
                         'deconv_dir','str','deconv/';...                   % Folder created to save deconvoluted tomograms.
                         'snrfalloff','num',1;...                           % SNR fall rate with the frequency. High values means losing more high frequency. If this value is not set, the program will look for the parameter in the star file. If this value is not set and not found in star file, the default value 1.0 will be used.
                         'deconvstrength','num',1;...                       % Strength of the deconvolution. If this value is not set, the program will look for the parameter in the star file. If this value is not set and not found in star file, the default value 1.0 will be used.
                         'highpassnyquist','num',0.02;...                   % Highpass filter for at very low frequency. We suggest to keep this default value.
                         'n_cores','num',1;...                              % Number of cpus to use.
                         'make_masks','boo',true;...                        % Make masks
                         'mask_dir','str','mask/';...                       % path and name of the mask to save as
                         'density_percentage','num',50;...                  % The approximate percentage of pixels to keep based on their local pixel density. If this value is not set, the program will look for the parameter in the star file. If this value is not set and not found in star file, the default value 50 will be used.
                         'std_percentage','num',50;...                      % The approximate percentage of pixels to keep based on their local standard deviation. If this value is not set, the program will look for the parameter in the star file. If this value is not set and not found in star file, the default value 50 will be used.
                         'use_deconv_tomo','boo',true;...                   % If CTF deconvolved tomogram is found in tomogram.star, use that tomogram instead.
                         'z_crop','num',[];...                              % If exclude the top and bottom regions of tomograms along z axis. For example, "--z_crop 0.2" will mask out the top 20% and bottom 20% region along z axis.
                         'subset_list','str',[];...                         % List containing tomo_num values for processing
                         };
        
    case 'isonet_train'
        isonet_fields = {'isonet_dir','str','isonet';...                    % Directory for IsoNet processing
                         'star_filename','str',[];...                       % Name of star file to process. Should be located in isonet_dir
                         'subtomo_folder','str',[];...                      % Folder for output subtomograms.
                         'subtomo_star','str',[];...                        % Star file for output subtomograms.
                         'result_dir','str',[];...                          % The name of directory to save refined neural network models and subtomograms
                         'run_extract','boo',true;...                       % Run subtomogram extraction
                         'use_deconv_tomo','boo',true;...                   % (True) If CTF deconvolved tomogram is found in tomogram.star, use that tomogram instead.
                         'cube_size','num',64;...                           % (64) Size of cubes for training, should be divisible by 8, eg. 32, 64. The actual sizes of extracted subtomograms are 1.5 times of this value.
                         'crop_size','num',80;...                           % (80) The size of subtomogram, should be larger then the cube_size The default value is 16+cube_size.
                         'iterations','num',[];...                          % (30) Number of training iterations.
                         'noise_level','num',[];...                         % (0.05,0.1,0.15,0.2) Level of noise STD(added noise)/STD(data) after the iteration defined in noise_start_iter.
                         'noise_start_iter','num',[];...                    % (11,16,21,26) Iteration that start to add noise of corresponding noise level.
                         'remove_intermediate','boo',[];...                 % Remove intermediate training files
                         'pretrained_model','str',[];...                    % A trained neural network model in ".h5" format to start with. File should be in the results_dir.
                         'continue_from','str',[];...                       % A Json file to continue from. That json file is generated at each iteration of refine. File should be in the results_dir. 
                         'n_cores','str',[];...                             % Number of CPUs for training
                         'gpuID','num',[];...                               % The ID of gpu to be used during the training. e.g 0,1,2,3.
                         'subset_list','str',[];...                         % List containing tomo_num values for processing.
                           };
        
    case 'isonet_predict'
        isonet_fields = {'isonet_dir','str','isonet';...                    % Directory for IsoNet processing
                         'star_filename','str',[];...                       % Name of star file to process. Should be located in isonet_dir
                         'result_dir','str',[];...                          % The name of directory to save refined neural network models and subtomograms
                         'model_name','str',[];...                          % Name of the .h5 model to use. Typically its model_[iteration].h5, which is determined by how you trained. This file should be in the results_dir.
                         'output_dir','str',[];...                          % Directory to output IsoNet processed tomograms. Relative to root_dir.
                         'use_deconv_tomo','boo',true;...                   % (True) If CTF deconvolved tomogram is found in tomogram.star, use that tomogram instead.
                         'cube_size','num',64;...                           % (64) Size of cubes for training, should be divisible by 8, eg. 32, 64. The actual sizes of extracted subtomograms are 1.5 times of this value.
                         'crop_size','num',80;...                           % (80) The size of subtomogram, should be larger then the cube_size The default value is 16+cube_size.
                         'gpuID','num',[];...                               % The ID of gpu to be used during the training. e.g 0,1,2,3.
                         'subset_list','str',[];...                         % List containing tomo_num values for processing.
                           };
end




