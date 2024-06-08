function tm_export2relion4_final(tomolist, p, export, dep, par)
% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Input dir
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/tomo/';    % Tomolist, reconstruction list, and bash scripts go here.
p.subtomo_dir = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/sg_subtomo/run_1/bin2/run_1/'; % Subtomogram averaging directory that you want to export to Relion from
p.relion_dir = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_ribosomes/yeast_tfs_brno/pt/relion_subtomo/test_bin2_10k/'; % Target Relion directory. You would start Relion using "relion --tomo&" from this directory


% Input lists
p.tomolist_name = 'tomolist.mat';     % Relative to rood_dir
p.motl_name = 'allmotl_scoreclean0_09_4_bin1.star';       % Relative to subtomo_dir/lists/. 
p.binning = 1;                        % Binning of the stopgap motl.
p.wedgelist_name = 'wedgelist.star';  % Relative to subtomo_dir/lists/. 

% IMOD/AreTomo parameters
p.imod_stack = 'dose_filt';  % Which stack was used for IMOD/AreTomo alignment. Options are 'unfiltered' and 'dose_filt'.


%% DO NOT CHANGE BELOW THIS LINE!!!!

%% Initialize

% Read tomolist
if exist([p.root_dir,'/',p.tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([p.root_dir,'/',p.tomolist_name]);
else
    error('TOMOMAN: No tomolist found!!!');
end

% read motl and wedgelist
if exist([p.subtomo_dir,'/lists/', p.motl_name],'file')
    motl = sg_motl_read([p.subtomo_dir,'/lists/', p.motl_name]);
else
    error('Motl not found!!!');
end

if exist([p.subtomo_dir,'/lists/', p.wedgelist_name],'file')
    wedgelist = sg_wedgelist_read([p.subtomo_dir,'/lists/', p.wedgelist_name]);
else
    error('Wedgelist not found!!!');
end


% Enforce binning 1!! 
if p.binning > 1
    error('Make sure to use bin1 motl from Stopgap!!! rescale to bin1 if you did not get to bin1 averaging in stopgap!!!');
end


% check tomograms from the motl (STOPGAP format)
rlist = unique([motl.tomo_num]);    
n_tomos = numel(rlist);

% Get indices of tomograms to reconstruct
[~,r_idx] = intersect([tomolist.tomo_num],rlist);

% Check for skips (THis is redundant! but still a good check to keep!!!)
skips = [tomolist(r_idx).skip];
if any(skips)
    error(['ACHTUNG!!! Are you running subtomogram averaging on tomogram that was set to skip??!!!']);
end

% Initialize rlnTomostar

rlnTomostar = struct();
rlncoords = struct();

% Loop through and generate scripts per tomogram
for i  = 1:n_tomos
    
    % Parse tomolist
    t = tomolist(r_idx(i));
    
    % Parse subset motl
    motl_ndx = [motl.tomo_num] == t.tomo_num;
    t_motl = motl(motl_ndx);
    
    % Export to Relion4
    [temptomostar,tempcoords] = tm_export2relion4_import_tomogram(t,t_motl,p.relion_dir,p.imod_stack);
    
    
    % concatanate tomostar and particlestar
    if i == 1
        rlnTomostar = temptomostar;
        rlncoords = tempcoords;
        
    else
        rlnTomostar = cat(1,rlnTomostar,temptomostar);
        rlncoords = cat(1,rlncoords,tempcoords);
    end

end

% Otput file names
tomostar_name = [p.relion_dir,'/tomograms.star'];
particlestar_name = [p.relion_dir,'/particles.star'];


tm_rlntomostar_write(tomostar_name,rlnTomostar);
tm_rlntomocoord2_1_write(particlestar_name,rlncoords);

