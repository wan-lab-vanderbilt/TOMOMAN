function incomplete = tm_check_task_completion(tomolist,task,task_params)
%% tm_check_task_completion
% Check which tomolist entries have had a particular task completed. The
% returned array is the incompleted entries, i.e. those that still need to 
% be processed. 
%
% WW 07-2025

%% Task array

% Row cell containing task, what tomolist field is used for checking
% completion, and if aligned tilt-series are required. Those with an empty 
% second field do not contain tomolist fields to check completion and will 
% return as all incomplete. For 

check_array = {'archive', [], false;...
               'aretomo', 'stack_aligned', false;...
               'clean_stacks', 'clean_stack', false;...
               'cryocare_oe_recons', [], true;...
               'cryocare_predict', [], true;...
               'cryocare_train', [], true;...
               'ctffind4', 'ctf_determined', false;...
               'dosefilter', 'dose_filtered', false;...
               'export_relion4', [], false;...
               'export_warp', [], false;...
               'imod_preprocess', 'imod_preprocessed', false;...
               'imod_reconstruct', [], true;...
               'imod_aligned_stack', [], true;...
               'isonet_predict', [], true;...
               'isonet_prepare', [], true;...
               'isonet_train', [], true;...
               'membrain_segment', [], true;...               
               'motioncor2', 'frames_aligned', false;...
               'motioncor3', 'frames_aligned', false;...
               'novactf', 'tomo_recons', true;...
               'relion_motioncorr', 'frames_aligned', false;...
               'tiltctf', 'ctf_determined', true;...
               'arctic', 'stack_aligned', false;...
               };
               
%% Check for stack alignment

% Parse array index
array_idx = strcmp(check_array(:,1),task);

% Check for stack alignment
if check_array{array_idx,3}
    stack = tm_check_if_aligned(tomolist);
else
    stack = true(size(tomolist));
end


%% Check for forced processing

% Parse field names for task parameters
fields = fieldnames(task_params);

% Search for the "force_*" parameter
force_idx = startsWith(fields,'force_');

% Check if enabled
if sum(force_idx) > 1
    error(['Error checking parameters for task "',task,'"; more than 1 "force_" parameter found...']);
elseif sum(force_idx) == 0
    incomplete = true(size(tomolist)) & stack;
    return
elseif task_params.(fields{force_idx}) == 1
    % If enabled, return array to run all
    incomplete = true(size(tomolist)) & stack;
    return
end
    
%% Check parameters



% Check if empty
if isempty(check_array{array_idx,2})
    % Return array to run all
    incomplete = true(size(tomolist)) & stack;
    return
end

% Parse incomplete indices
incomplete = (~[tomolist.(check_array{array_idx,2})]) & stack;


               

