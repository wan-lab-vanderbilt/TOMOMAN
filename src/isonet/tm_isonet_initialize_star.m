function star = tm_isonet_initialize_star(p,tomolist,isonet,star_name)
%% tm_isonet_initialize_star
% Initialize a star file for IsoNet processing. This essentially replaces
% the isonet.py prepare_star step so that TOMOMAN can parse the proper
% parameters. 
%
% WW 06-2025

%% Generate struct array

% Initial fields
fields = {'rlnIndex';...
          'rlnMicrographName';...
          'rlnPixelSize';...
          'rlnDefocus';...
          'rlnNumberSubtomo';...
          'rlnMaskBoundary';...
          };
n_fields = numel(fields);

% Number of stacks
n_stacks = numel(tomolist);

% Initialize cell array
temp_cell = cell(n_fields,n_stacks);


%% Parse tomogram directory

% Check tomogram directory
tomo_dir = tm_check_absolute_path(p.root_dir,isonet.tomo_dir);

% Initialize array
tomo_names = cell(1,n_stacks);

% Check processing stack
switch isonet.process_stack
    case 'unfiltered'
        append = [];
    case 'dose-filtered'
        append = '_dose-filt';
end
    
% Fill tomo_names array
for i = 1:n_stacks
    
    % Parse name
    [~,stack_root,~] = fileparts(tomolist(i).stack_name);
    temp_name = [tomo_dir,stack_root,append];
    
    % Check file ext and existence
    if exist([temp_name,'.rec'],'file')
        tomo_names{i} = [temp_name,'.rec'];
    elseif exist([temp_name,'.mrc'],'file')
        tomo_names{i} = [temp_name,'.mrc'];
    else
        error([p.name,'ACHTUNG!!! Cannot find ',temp_name]);
    end    
end

%% Parse defocus parameters

% Initialize cell
defocus = cell(1,n_stacks);

% Calculate average defocii
for i = 1:n_stacks    
    
    % Parse defocus
    if tomolist(i).ctf_determined
        temp_def = mean(reshape(tomolist(i).determined_defocii(:,1:2),1,[]));
    else
        temp_def = -tomolist(i).target_defocus;
    end
    
    % Convert to CTFFIND4 units (Angstroms)
    defocus{i} = temp_def*10000;
end


%% Fill array and save

% Fill cell
temp_cell(1,:) = {tomolist.tomo_num};
temp_cell(2,:) = tomo_names;
temp_cell(3,:) = num2cell([tomolist.pixelsize]*isonet.tomo_binning);
temp_cell(4,:) = defocus;
temp_cell(5,:) = num2cell(ones(1,n_stacks).*isonet.number_subtomos);
temp_cell(6,:) = repmat({'None'},1,n_stacks);

% Convert to struct
star = cell2struct(temp_cell,fields);

% Write struct
stopgap_star_write(star,star_name);
      
