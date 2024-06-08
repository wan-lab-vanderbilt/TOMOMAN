function df_fields = tm_get_dosefilter_fields()
%% tm_get_dosefilter_fields
% Return the fields for the dosefilter structs.
%
% WW 05-2022

%% Fields


df_fields = {'dfilt_append','str';...       % Append name to dose-filtered stack. Setting to 'none' overwrites stack this is NOT recommended...
             'preexposure','num';...        % Pre-exposure prior to initial image collection.
             'check_oddeven','boo';...       % Check for odd/even stacks. Filter by image if present.
             'filter_frames','boo';...      % Dose filter frames instead of images. In order to do this, the OutStack MotionCor2 parameter must have been used to generate aligned frame stacks.
             'remove_frames','boo';...      % Remove frame stacks after dose filtering and summation.
             'a','num';...                  % Resolution-dependent critical exposure constant 'a'. Set to 'none' to use default.
             'b','num';...                  % Resolution-dependent critical exposure constant 'b'. Set to 'none' to use default.
             'c','num';...                  % Resolution-dependent critical exposure constant 'c'. Set to 'none' to use default.
             'force_dfilt','boo'};          % Binning to open 3dmod with
    
        
end
