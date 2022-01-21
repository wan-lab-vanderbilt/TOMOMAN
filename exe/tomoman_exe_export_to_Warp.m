% Tomoman is a set of wrapper scripts for preprocessing to tomogram data
% collected by SerialEM. 

% WW,SK,PSE

clear all;
close all;
clc;

%% Inputs

% Input dir
p.root_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/tomo/';    % Tomolist, reconstruction list, and bash scripts go here.
p.subtomo_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/tm/bin8/run_1/'; % Subtomogram averaging directory that you want to export to Relion from
p.warp_dir = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/warp_test1/'; % Target Relion directory. You would start Relion using "relion --tomo&" from this directory


% Input lists
p.tomolist_name = 'tomolist.mat';     % Relative to rood_dir
p.motl_name = 'allmotl_1_bin1.star';       % Relative to subtomo_dir/lists/. 
p.binning = 4;                        % Binning of the stopgap motl.
p.wedgelist_name = 'wedgelist.star';  % Relative to subtomo_dir/lists/. 

% IMOD/AreTomo parameters
p.imod_stack = 'dose_filt';  % Which stack was used for IMOD/AreTomo alignment. Options are 'unfiltered' and 'dose_filt'.

% MotionCor Algorithm
p.mc_algorithm = 'relion'; % Which MotionCor algorithm to use for frame export. 'relion' or 'motioncor2' # [beware!! OPTION IS NO LONGER USED]

% Export only particles
p.only_particles = 1; 

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
if ~isempty(p.subtomo_dir)
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
end

% % Enforce binning 1!! 
% if p.binning > 1
%     error('Make sure to use bin1 motl from Stopgap!!! rescale to bin1 if you did not get to bin1 averaging in stopgap!!!');
% end

if ~isempty(p.subtomo_dir)

    % check tomograms from the motl (STOPGAP format)
    rlist = unique([motl.tomo_num]);    
    
else
    ndx = [tomolist.skip] == 0;
    rlist = unique([tomolist(ndx).tomo_num]);
    
end

n_tomos = numel(rlist);

% Get indices of tomograms to reconstruct
[~,r_idx] = intersect([tomolist.tomo_num],rlist);

% Check for skips (THis is redundant! but still a good check to keep!!!)
skips = [tomolist(r_idx).skip];
if any(skips)
    error(['ACHTUNG!!! Are you running subtomogram averaging on tomogram that was set to skip??!!!']);
end


% Loop through and generate scripts per tomogram
if ~p.only_particles
    for i  = 1:n_tomos

        % Parse tomolist
        t = tomolist(r_idx(i));

    %     % Parse subset motl
    %     motl_ndx = [motl.tomo_num] == t.tomo_num;
    %     t_motl = motl(motl_ndx);

        % Export to Relion4
        tomoman_export2warp_import_tomogram(t,p.warp_dir,p.imod_stack,p.mc_algorithm);

    end
end


if ~isempty(p.subtomo_dir)

    particlestar_name = [p.warp_dir,'/particles.star'];
    apix = tomolist(1).pixelsize.*p.binning;

    tomoman_sgmotl2relion_4warp(motl, tomolist, particlestar_name, apix)
end
% % % Generate one big particle file. At the moment I will stick to per
% % % tomogram star file for ease of debugging, 
% % tomoman_sgmotl2relioncoords1(t,motl)
