function membrain_fields = tm_get_membrain_fields(task)
%% tm_get_membrain_fields
% Return parameter fields for a given tomoman_isonet task. 
%
% WW 06-2023

%% Get fields

switch task
    case 'membrain_segment'
        membrain_fields = {'process_stack','str',[];...                 % Stack was used tomogram reconstruction
                           'tomo_dir','str',[];...                      % Directory containing tomograms to be segmented.
                           'tomo_binning','num',[];...                  % Binning of tomograms to be segmented.
                           'ckpt_path','str',[];...                     % Path to the pre-trained model checkpoint that should be used.
                           'out_folder','str',[];...                    % Output folder for segmentations.
                           'rescale_patches','boo',[];...               % Should patches be rescaled on-the-fly during inference? ('true' or 'false')
                           'store_probabilities','boo',[];...           % Should probability maps be output in addition to segmentations? ('true' or 'false')
                           'store_connected_components','boo',[];...    % Should connected components of the segmentation be computed? ('true' or 'false')
                           'connected_component_thres','boo',[];...     % (Default = 'none')Threshold for connected components. Components smaller than this will be removed from the segmentation. (Integer Value) 
                           'test_time_augmentation','boo',[];...        % (Default = 'true') Use 8-fold test time augmentation (TTA)? TTA improves segmentation quality slightly, but also increases runtime. 
                           'segmentation_threshold','num',[];...        % (Default = 0) Threshold for the membrane segmentation. Only voxels with a membrane score higher than this threshold will be segmented. 
                           'sliding_window_size','num',[];...           % (Default = 160) Sliding window size used for inference. Smaller values than 160 consume less GPU, but also lead to worse segmentation results!                           
                           'gpu_id','num',[];...                        % The ID of GPUs to be used for processing. e.g 0,1,2,3.
                           'subset_list','str',[];...                   % List containing tomo_num values for processing.
                          };
    otherwise
        error('ACHTUNG!!! Unsupported membrain task!!!');
end




