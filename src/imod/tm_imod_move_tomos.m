function tm_imod_move_tomos(tomolist_name,dest_dir,rename)
%% tm_imod_move_tomos
% Move IMOD reconstructed tomograms from their original IMOD subdirectories
% into a common tomomgram directory. Tomomgrams are parsed from the
% tomolist and moved into the 'dest_dir'. If rename is selected, tomograms
% are renamed to [tomo_num].mrc.
%
% The conditions for moving are if the tomolist shows the tomogram is not 
% skipped, has 'imod' as the alignment_software, and the reconstructed
% tomogram is in the folder.
%
% WW 06-2022

%% Check inputs

% Check for rename
if nargin == 2
    rename = false;
end


%% Initialize

% Read tomolist
tomolist = tm_read_tomolist('',tomolist_name);
n_tomos = numel(tomolist);

% Check for destination folder
if ~exist(dest_dir,'dir')
    mkdir(dest_dir);
end


%% Move tomograms
for i = 1:n_tomos
    
    % Check for skipping
    if tomolist(i).skip 
        disp(['TOMOMAN: Tomogram ',num2str(tomolist(i).tomo_num),' is marked as skipped... Moving to next tomogram!']);
        continue
    end
    
    % Check for imod alignment
    if ~strcmp(tomolist(i).alignment_software,'imod')
        disp(['TOMOMAN: Tomogram ',num2str(tomolist(i).tomo_num),' was not reconstructed with IMOD... Moving to next tomogram!']);
        continue
    end
    
    
    % Parse input stack
    switch tomolist(i).alignment_stack
        case 'unfiltered'
            [path,name,~] = fileparts(tomolist(i).stack_name);
        case 'dose-filtered'
            [path,name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
    end
    if ~isempty(path)
        path = [path,'/'];
    end
    
    % Parse tomogram name
    tomo_name = [path,name,'_rec.mrc'];
    
    % Check output name
    if rename
        out_name = [num2str(tomolist(i).tomo_num),'.mrc'];
    else
        out_name = tomo_name;
    end
    
    
    % Check for tomogram
    if ~exist([tomolist(i).stack_dir,'imod/',tomo_name],'file')
        warning(['TOMOMAN: ACHTUNG!!! ',tomo_name,' not found!!! Moving to next tomogram!']);
        continue
    end
    
    
    % Move tomogram
    system(['mv ',tomolist(i).stack_dir,'imod/',tomo_name,' ',dest_dir,'/',out_name]);
    disp(['TOMOMAN: Tomogram ',num2str(tomolist(i).tomo_num),' moved to ',dest_dir,'!!!']);
    
end


    
    
    
    
    
    
    
    
