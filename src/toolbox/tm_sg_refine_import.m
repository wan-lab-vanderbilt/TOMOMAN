function tm_sg_refine_import(input_tomolist_name,sg_refine_listdir,iteration,projlist_name,xflist_name,wedgelist_name,ctflist_name,refine_run_name,output_tomolist_name)
%% tm_sg_refine_import
% A function to import the results of STOPGAP refine into an updated
% tomolist. This also generates a subfolder that contains all necessary
% files for CTF correction and tomogram reconstruction. 
%
% WW 11-2025

% % %%%% DEBUG
% input_tomolist_name = 'tomolist.mat';
% sg_refine_listdir = '/sb/wanlab/data/misc/ribosomes/04042026_wanw_wanw_ribosomes_serialEM_subtomo/bin2_refine/lists/';
% iteration = 4;
% projlist_name = 'projlist';
% xflist_name = 'xflist';
% wedgelist_name = 'wedgelist';
% ctflist_name = 'ctflist';
% refine_run_name = 'bin2';
% output_tomolist_name = 'tomolist_sgrefine4.mat';

%% Initialize

% Load tomolist
load(input_tomolist_name,'tomolist');

% Load projlist
projlist = sg_projlist_read([sg_refine_listdir,projlist_name,'_',num2str(iteration),'.star']);
tomos = unique(projlist.tomo_num);  % Tomograms to update
n_tomos = numel(tomos);

% Load xflist
xflist = sg_xflist_read([sg_refine_listdir,xflist_name,'_',num2str(iteration),'.star']);

% Load wedgelist
wedgelist = sg_wedgelist_read([sg_refine_listdir,wedgelist_name,'_',num2str(iteration),'.star']);

% Load ctflist
if ~isempty(ctflist_name)
    update_ctf = true;
    ctflist = sg_ctflist_read([sg_refine_listdir,ctflist_name,'_',num2str(iteration),'.star']);
else
    update_ctf = false;
end


%% Update tomolist

for i = 1:n_tomos
    
    % Parse tomogram index
    t_idx = [tomolist.tomo_num] == tomos(i);
    
    % Parse stack basename
    switch tomolist(t_idx).alignment_stack
        case 'unfiltered'
            [~,stack_name,~] = fileparts(tomolist(t_idx).stack_name);
        case 'dose-filtered'
            [~,stack_name,~] = fileparts(tomolist(t_idx).dose_filtered_stack_name);
        otherwise
            error(['ACHTUNG!!! ',tomolist(t_idx).alignment_stack,' is an unsupported alignment_stack type!!!']);
    end
    
    % Parse sg_refine subdirectory
    sg_refine_subdir = ['sg_refine_',refine_run_name,'_',num2str(iteration),'/'];
    system(['mkdir -p ',tomolist(t_idx).stack_dir,sg_refine_subdir]);
    
    % Copy tilt.com from prior alignment
    switch lower(tomolist(t_idx).alignment_software)
        case 'imod'
            source_dir = 'imod/';
        case 'aretomo'
            source_dir = 'AreTomo/';
        otherwise
            if startsWith(tomolist(t_idx).alignment_software,'sg_refine_')
                source_dir = [tomolist(t_idx).alignment_software,'/'];
            else
                error(['ACHTUNG !!! ',tomolist(t_idx).alignment_software,' is an unsupported alignment_software type!!!']);
            end
    end
    if ~strcmp(source_dir,sg_refine_subdir)
        copyfile([tomolist(t_idx).stack_dir,source_dir,'tilt.com'],[tomolist(t_idx).stack_dir,sg_refine_subdir,'tilt.com']);
        erase_test = dir([tomolist(t_idx).stack_dir,source_dir,'*_erase.fid']);
        if ~isempty(erase_test)
            copyfile([tomolist(t_idx).stack_dir,source_dir,'*_erase.fid'],[tomolist(t_idx).stack_dir,sg_refine_subdir]);
        end
    else
        warning('ACHUTNG!!! sg_refine_subdir is the same as current one... tilt.com copying skipped...');
    end
    
    % Update tomolist 
    tomolist(t_idx).alignment_software = ['sg_refine_',refine_run_name,'_',num2str(iteration)];
    
    % Write new .xf file
    xf_idx = [xflist.tomo_num] == tomos(i);
    xf_name = [tomolist(t_idx).stack_dir,sg_refine_subdir,stack_name,'.xf'];
    sg_write_IMOD_xf(xf_name,xflist(xf_idx),'xflist');
    
    % Write new .tlt file
    tlt_idx = [wedgelist.tomo_num] == tomos(i);
    tlt_name = [tomolist(t_idx).stack_dir,sg_refine_subdir,stack_name,'.tlt'];
    dlmwrite(tlt_name,wedgelist(tlt_idx).tilt_angle,' ');
    
    
    % Write new ctfphaseflip file
    if update_ctf
        
        % Parse index
        ctf_idx = [ctflist.tomo_num] == tomos(i);
        
        % Update tomolist
        if all(ctflist(ctf_idx).pshift == 0)
            tomolist(t_idx).determined_defocii = cat(2,ctflist(ctf_idx).defocus_1,ctflist(ctf_idx).defocus_2,ctflist(ctf_idx).astig_angle);
        else
            tomolist(t_idx).determined_defocii = cat(2,ctflist(ctf_idx).defocus_1,ctflist(ctf_idx).defocus_2,ctflist(ctf_idx).astig_angle,ctflist(ctf_idx).pshift);
        end
        tomolist(t_idx).ctf_determination_algorithm = ['sg_refine_',num2str(iteration)];

        
        % Write ctfphaseflip file
        tm_write_ctfphaseflip(tomolist(t_idx),'sg_refine');
    end
    
    
    
end

% Save tomolist
tm_save_tomolist([],output_tomolist_name,tomolist);
