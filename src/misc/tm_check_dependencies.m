function tm_check_dependencies(dep,disp_path)
%% tm_check_dependencies
% Function to check that external packages are available. 
%
% disp_path option to display paths of found dependencies. May be useful
% for debugging.
%
% WW 05-2022


%% Check inputs

if nargin == 1
    disp_path = false;
end


%% Check dependencies


% Parse fields
fields = fieldnames(dep);
n_dep = numel(fields);

% Loop through and test commands
for i = 1:n_dep
    [test,path] = system(['which ',dep.(fields{i})]);
    if test == 1
        error(['ACHTUNG!!! ',dep.(fields{i}),' not found!!! Source the package prior to running MATLAB!!!']);
    else
        if disp_path
            disp([dep.(fields{i}),' found here: ',path]);
        end
    end
end

