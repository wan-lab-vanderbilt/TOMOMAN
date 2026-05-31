function tm_update_dose_rate(input_tomolist_name,output_tomolist_name,dose_rate)
%% tm_update_dose_rate
% A function to apply a new dose_rate value to a tomolist.
%
% WW 02-2025

%% Initialize

% Load tomolist
tomolist = tm_read_tomolist([],input_tomolist_name);
n_stacks = numel(tomolist);

% Initilize mdoc parsing fields
mdoc_fields = {'ExposureTime'};
mdoc_field_types = {'num'};

%% Update tomolist

% Loop through stacks
for i = 1:n_stacks
    
    % Load and parse .mdoc
    mdoc_param = tm_parse_mdoc([tomolist(i).stack_dir,'/',tomolist(i).mdoc_name],mdoc_fields,mdoc_field_types);
    
    % Get doses
    total_exposure = cumsum([mdoc_param.ExposureTime]');
    tomolist(i).cumulative_exposure_time = total_exposure;
    total_dose = (total_exposure.*dose_rate)./([tomolist(i).pixelsize].^2);
    tomolist(i).dose = total_dose;

end

% Write tomolist
tm_save_tomolist([],output_tomolist_name,tomolist);


