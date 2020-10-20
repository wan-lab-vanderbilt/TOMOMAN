function tomolist = tomoman_generate_tomolist(n_tomos)
%% tomoman_generate_tomolist.m
% A function for generating a new tomoman tomolist. The tomolist is a
% struct array that contains various details about tomogram file locations
% and about processing statuses. 
%
% WW 12-2017

%% Fields 

% Fields
fields = {'root_dir',...
          'stack_dir',...
          'frame_dir',...
          'mdoc_name',...
          'tomo_num',...
          'collected_tilts',...
          'frame_names',...
          'n_frames',...
          'pixelsize',...
          'image_size',...
          'cumulative_exposure_time',...
          'dose',...
          'target_defocus',...
          'gainref',...
          'defects_file',...
          'rotate_gain',...
          'flip_gain',...
          'raw_stack_name',...
          'mirror_stack',...
          'skip',...
          'frames_aligned',...
          'frame_alignment_algorithm',...
          'stack_name',...
          'clean_stack',...
          'removed_tilts',...
          'rawtlt',...
          'max_tilt',...
          'min_tilt',...
          'tilt_axis_angle',...
          'dose_filtered',...
          'dose_filtered_stack_name',...
          'dose_filter_algorithm',...
          'imod_preprocessed',...
          'ctf_determined',...
          'ctf_determination_algorithm',...
          'determined_defocii',...
          'stacked_aligned',...
          };
      
values = {'none',... % root_dir
    'none',...       % stack_dir
    'none',...       % frame_dir
    'none',...       % mdoc_name
    [],...           % tomo_none
    [],...           % collected_tilts
    {},...           % frame_names
    [],...           % n_frames
    [],...           % pixelsize
    [],...           % imagesize
    [],...           % cumulative_exposure_time
    [],...           % dose
    [],...           % target_defocus
    'none',...       % gainref
    'none',...       % defects_file
    [],...           % rotate_gain
    [],...           % flip_gain
    'none',...       % raw_stack_name
    'none',...       % mirror_stack
    false,...        % skip
    false,...        % frames_aligned
    'none',...       % frame_alignment_algorithm
    'none',...       % stack_name
    false,...        % clean_st4ack
    [],...           % remove_tilts
    [],...           % rawtlt
    [],...           % max_tilt
    [],...           % min_tilt
    [],...           % tilt_axis_angle
    false,...        % dose_filtered
    'none',...       % dose_filtered_stack_name
    'none',...       % dose_filter_algorithm     
    false,...        % imod_preprocessed
    false,...        % ctf_determined
    'none',...       % ctf_determination_algorithm
    [],...           % determined_defocii
    false,...        % stacked_aligned
    };
  
    
%% Initialize struct array

tomolist = cell2struct(repmat(values,[n_tomos,1]),fields,2);

