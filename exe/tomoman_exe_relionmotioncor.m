% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Directory parameters
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/tomo/';  % Root folder for dataset; stack directories will be generated here.

% Tomolist 
p.tomolist_name = 'tomolist.mat';     % Relative to root_dir
p.log_name = 'tomoman.log';           % Relative to root_dir

%%%% Align frames / generate stack %%%%
a.force_realign = 0;                  % 1 = yes, 0 = no;
a.image_size = [4096,4096];           % 4096 for 4k rendering, 8192 for 8k rendering (NOT RECOMMENDED)
a.stack_prefix = 'AUTO';
% Relion's motioncor parameters
relionmc.input_format = 'eer';    % 'tiff' or 'mrc' or 'eer'
relionmc.patch = [1,1];            % Number of patches to be used for patch based alignment, default 0 0 corresponding full frame alignment.
relionmc.bin_factor = 1;                 % Maximum iterations for iterative alignment, default 5 iterations.
relionmc.bfactor = 150;                 % B-Factor for alignment, default 150.
relionmc.eer_grouping = 45;            % EER grouping, default 40 
relionmc.eer_upsampling = 1;            % EER upsampling (1 = 4K or 2 = 8K)

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
dependencies = {'ctffind'};

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
    
    % Align frames and generate stack
    tomolist(t) = tomoman_relion_motioncor_newstack(tomolist(t),p,a,relionmc,write_list);
    % Write tomolist
    save([p.root_dir,p.tomolist_name],'tomolist');

    
    t = t+b_size;
    
end

diary off