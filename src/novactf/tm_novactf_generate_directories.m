function tm_novactf_generate_directories(stack_dir)
%% tm_novactf_generate_directories
% A function for generating a NovaCTF working folder in a stack directory. 
%
% WW 01-2018

%% Check check
if ~exist(stack_dir,'dir')
    error(['ACHTUNG!!! ',stack_dir,' does not exist!!!']);
end

%% Directory list

% List of directories to generate
directories = {'novaCTF/defocus_files/',...
               'novaCTF/scripts/',...
               'novaCTF/stacks/',...
               'novaCTF/logs/',...
               'novaCTF/comm/'};
           
%% Generate directories

for i = 1:numel(directories)
    
    % Full path
    d = [stack_dir,directories{i}];
    
    % Check for existence and create
    if ~exist(d,'dir')
        mkdir(d);
    else
        system(['rm -rf ',d,'*']);
    end
end

    
    
    
