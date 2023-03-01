% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Input dir
p.root_dir = '/fs/pool/pool-sagar/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/tomo/';    % Tomolist, reconstruction list, and bash scripts go here.
p.archive_dir = '/fs/pool/pool-sagar/Sagar/Depositions/sputter/empiar/pt/'; % Target Relion directory. You would start Relion using "relion --tomo&" from this directory


% Input lists
p.tomolist_name = 'tomolist.mat';     % Relative to rood_dir

% IMOD/AreTomo parameters
p.imod_stack = 'dose_filt';  % Which stack was used for IMOD/AreTomo alignment. Options are 'unfiltered' and 'dose_filt'.

% Subset
p.select_list = ''; % absolute path to subset list

%% DO NOT CHANGE BELOW THIS LINE!!!!

%% Initialize

% Read tomolist
if exist([p.root_dir,'/',p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,'/',p.tomolist_name]);
    
else
    error('TOMOMAN: No tomolist found!!!');
end

%% Run pipeline!!!

% Generate subset motl
if ~isempty(p.select_list)
    subset = dlmread(p.select_list);
    sub_ndx = ismember([tomolist.tomo_num], subset');
    tomolist = tomolist(sub_ndx);
end

n_tilts = size(tomolist,2);
b_size = 1;
write_list = false;
t = 1;


while all(t <= n_tilts)    
    
    % TiltCTF
    tomolist(t) = tomoman_export2EMPIAR_tomogram(p,tomolist(t));
    % Save tomolist
    save([p.empiar_dir,p.tomolist_name],'tomolist');
   
    % Increment counter
    t = t+b_size;
end

