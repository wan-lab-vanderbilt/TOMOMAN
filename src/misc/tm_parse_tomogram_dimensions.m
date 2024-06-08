function dims = tm_parse_tomogram_dimensions(tomolist,binning)
%% tm_parse_tomogram_dimensions
% Parse tomogram dimensions from a tomolist. This script pulls dimensions
% from tilt.com files
%
% WW 08-2022

%% Check check
if nargin == 1
    binning = 1;
end


%% Parse dimensions

% Number of tomograms
n_tomos = numel(tomolist);

% Dimension array
dim_cell = cell(n_tomos,1);

% Parse dimensions
for i = 1:n_tomos
    
    % Check for skipping
    if tomolist(i).skip
        continue
    end
    
    % Parse tilt.com filenames
    switch tomolist(i).alignment_software
        case 'AreTomo'
            ali_dir = 'AreTomo/';                
        case 'imod'
            ali_dir = 'imod/';                
        otherwise
            error([p.name,'ACHTUNG!!! ',tomolist(i).alignment_software,' is unsupported!!!']);
    end
    tiltcom_name = [tomolist(i).stack_dir,ali_dir,'tilt.com'];

    % Read tilt.com        
    tiltcom = tm_imod_parse_tiltcom(tiltcom_name);
    
    % Store dimensions
    dim_cell{i} = [tiltcom.FULLIMAGE(1),tiltcom.FULLIMAGE(2),tiltcom.THICKNESS];
    
end

% Concatenate dimensions
dims = reshape([dim_cell{:}],3,[])';
    
% Check for binning
if binning ~= 1
    dims = ceil(dims./binning);
end

    

