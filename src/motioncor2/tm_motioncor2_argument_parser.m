function param_str = tm_motioncor2_argument_parser(param)
%% tm_motioncor2_argument_parser
% An argument parser to set the default arguments for MotionCor2. It also
% checks required input arguments. 
%
% Written based on MotionCor2 build 01-30-2017.
%
% WW 04-2018

%% Initialize

% MotionCor2 parameters 
parameters = {'ArcDir','str';...
              'MaskCent','float';...
              'MaskSize','float';...
              'Patch','int';...
              'Iter','int';...
              'Tol','float';...
              'Bft','float';...
              'FtBin','float';...
              'kV','float';...
              'Throw','int';...
              'Trunc','int';...
              'Group','int';...
              'FmRef','int';...
              'OutStack','int';...
              'Align','int';...
              'Tilt','int';...
              'Mag','float';...
              'Crop','int';...
              'Gpu','int';...
              };
n_param = numel(parameters); 



%% Check fields

% Output string
param_str_cell = cell(n_param,1);

% Parse input fields
fields = fieldnames(param);
n_fields = numel(fields);

% Loop through and prepare outputs
for i = 1:n_fields
    
    % If field is present, set up string
    field_test = strcmp(parameters(:,1),fields(i));
    if any(field_test) && ~isempty(param.(fields{i}))
        
        % Assemble string based on field type
        field_type = parameters{find(field_test,1,'first'),2};
        
        switch field_type
            case 'str'
                param_str_cell{i} = [' -',fields{i},' ',param.(fields{i}),' '];
            case 'int'
                param_str_cell{i} = [' -',fields{i},' ',num2str(param.(fields{i}),'%i ')];
            case 'float'
                param_str_cell{i} = [' -',fields{i},' ',num2str(param.(fields{i}),'%f ')];
        end
        
    end
end

% Concatenate string
param_str = [param_str_cell{:}];





        
        

