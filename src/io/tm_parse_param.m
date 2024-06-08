function param_struct = tm_parse_param(fields,param_cell)
%% tm_parse_param
% Takes a cell containing the paramters of interest and a cell containing
% the raw parameters data (from tm_read_param_file.m) and returns a struct
% containing parameters of interest.
%
% WW 05-2022


%% Parse parameters

% Number of target fields
n_fields = size(fields,1);

% Initialize struct
param_struct = struct();

% Fill struct
for i = 1:n_fields
    
    % Find index of parameter
    idx = strcmpi(fields{i,1},param_cell{1});
    
    % Check input field
    if any(idx)
        % Store field in struct
        param_struct.(fields{i,1}) = param_cell{2}{idx};
        
        % Check directory
        if endsWith(fields{i,1},'dir')
            param_struct.(fields{i,1}) = sg_check_dir_slash(param_struct.(fields{i,1}));
        end
        
    end
    
end

% Evaluate fields
param_struct = tm_evaluate_field_types(param_struct,fields);


