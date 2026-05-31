function star = tm_isonet2_initialize_star(p,tomolist,isonet2,star_name)
%% tm_isonet2_initialize_star
% Initialize a star file for IsoNet2 processing. This essentially replaces
% the isonet.py prepare_star step so that TOMOMAN can parse the proper
% parameters. 
%
% WW 02-2026

%% Generate struct array

% Initial fields
fields = {'rlnIndex';...
          'rlnTomoName';...
          'rlnTomoReconstructedTomogramHalf1';...
          'rlnTomoReconstructedTomogramHalf2';...
          'rlnPixelSize';...
          'rlnDefocus';...
          'rlnVoltage';...
          'rlnSphericalAberration';...
          'rlnAmplitudeContrast';...
          'rlnDeconvTomoName';...
          'rlnMaskBoundary';...
          'rlnMaskName';...
          'rlnTiltMin';...
          'rlnTiltMax';...
          'rlnBoxFile';...
          'rlnNumberSubtomo';...
          'rlnCorrectedTomoName';...
          'rlnDenoisedTomoName';...
          };
n_fields = numel(fields);

% Number of stacks
n_stacks = numel(tomolist);

% Initialize cell array
temp_cell = cell(n_fields,n_stacks);

% Tomogram directory
tomo_dir = [p.root_dir,isonet2.isonet2_dir,isonet2.tomo_subdir];

%% Fill parameters for each stack

for i = 1:n_stacks
    
    % Parse IMOD-formatted Alignment Filenames
    switch tomolist(i).alignment_software
        case 'AreTomo'
            subfolder = 'AreTomo/';
        case 'imod'
            subfolder = 'imod/';
        otherwise 
            if startsWith(t.alignment_software,'sg_refine_')
                subfolder = [tomolist(i).alignment_software,'/'];
            else
                error(['ACHTUNG !!! ',tomolist(i).alignment_software,' is an unsupported alignment_software type!!!']);
            end
    end
    
    % tomo_num
    temp_cell{1,i} = tomolist(i).tomo_num;
    
    % Tomogram names
    switch isonet2.process_stack
        case 'dose-filtered'
            [~,name,~] = fileparts(tomolist(i).dose_filtered_stack_name);
        otherwise
            [~,name,~] = fileparts(tomolist(i).stack_name);
    end
    temp_cell{2,i} = [tomo_dir,'AVG/',name,'_AVG.rec'];
    temp_cell{3,i} = [tomo_dir,'EVN/',name,'_EVN.rec'];
    temp_cell{4,i} = [tomo_dir,'ODD/',name,'_ODD.rec'];
    
    % Pixelsize
    temp_cell{5,i} = tomolist(i).pixelsize.*isonet2.binning;
    
    % Defocus
    if tomolist(i).ctf_determined
        temp_def = mean(reshape(tomolist(i).determined_defocii(:,1:2),1,[]));
        temp_cell{8,i} = tomolist(i).ctf_parameters.cs;       % Cs used for fitting
        temp_cell{9,i} = tomolist(i).ctf_parameters.famp;      % famp used for fitting
    else
        temp_def = -tomolist(i).target_defocus;
        temp_cell{8,i} = 2.7;       % Default Cs
        temp_cell{9,i} = 0.07;      % Default famp
    end
    temp_cell{6,i} = temp_def*10000;    % Convert to CTFFIND4 units (Angstroms)
    temp_cell{7,i} = tomolist(i).voltage;
    
    % Mask parameters
    temp_cell{10,i} = 'None';
    temp_cell{11,i} = 'None';
    temp_cell{12,i} = 'None';
    
    % Tilt range
    tlt = dlmread([tomolist(i).stack_dir,subfolder,name,'.tlt']);   % Read .tlt file
    temp_cell{13,i} = min(tlt);   
    temp_cell{14,i} = max(tlt);
    
    % Box file
    temp_cell{15,i} = 'None';
    
    % Number subtomos
    temp_cell{16,i} = isonet2.number_subtomos;
    
    % Preditcted tomos
    temp_cell{17,i} = 'None';
    temp_cell{18,i} = 'None';
    

end

% Convert to struct
star = cell2struct(temp_cell,fields);

% Write struct
stopgap_star_write(star,star_name,'isonet2',[],4);
      
