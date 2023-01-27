% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

%%%% Clean stacks %%%%
c.force_cleaning = 0;     % 1 = yes, 0 = no;
c.clean_binning = 16;      % Binning to open 3dmod with
c.clean_append = '';      % Append to name for cleaned stack. Setting blank ('') overwrites old file.
c.denovo = 1;           % 1 = start from scratch, 0 = USe cleaning information from the tomolist. TODO -1 = remove additional on top of previous. 


%% DO NOT CHANGE BELOW THIS LINE %%

%% Initalize

diary([p.root_dir,p.log_name]);
disp('TOMOMAN Initializing!!!');

% Read tomolist
if exist([p.root_dir,p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,p.tomolist_name]);
else
    error('TOMOMAN: No tomolist found!!!');
end

%% Check dependencies

% List of dependent commands
dependencies = {'3dmod','newstack'};

% Loop through and test commands
for i = 1:numel(dependencies)
    [test,~] = system(['which ',dependencies{i}]);
    if test == 1
        error(['ACHTUNG!!! ',dependencies{i},' not found!!! Source the package prior to running MATLAB!!!']);
    end
end


%% Run pipeline!!!

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)
        
    % Clean stacks
    tomolist(t) = tomoman_clean_stacks(tomolist(t),p,c,write_list);     
    % Save tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');     
            
    t = t+b_size;
    
end

diary off