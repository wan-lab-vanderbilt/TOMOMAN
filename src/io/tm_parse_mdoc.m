function mdoc_param = tm_parse_mdoc(mdoc_name,fields,field_types)
%% tm_parse_mdoc
% A function to parse arguments for each image from a SerialEM .mdoc file.
% The function returns a struct array, and can be written out a .star file.
%
% Fields to be parsed are given at the start. Field types must also be
% given in a matching array; field types are: 'str' and 'num'.
%
% TiltAxisAngle is a special field, as it is parsed once at the beginning
% of the .mdoc. All other fields are assumed to be per-image fields.
%
% WW 11-2017


%% Check check

% Check mdoc
if ~exist(mdoc_name,'file')
    error('Achtung!!! What are you doing??? The.mdoc file does not exist!!!');
end

% Check field numbers
n_fields = numel(fields);
if numel(field_types) ~= n_fields
    error('Achtung!!! The number of fields does not match the number of field types!!!');
end

% Delimiter between field name and value
delim = ' = ';
d_size = numel(delim);

%% Initialize

% Open .mdoc file
fid = fopen(mdoc_name,'r');
mdoc = textscan(fid, '%s', 'Delimiter', '\n');

% Find starting indices for images
img_start_str = 'ZValue';       % String that identifies the start of an image section
% img_start = find(cellfun(@(x) ~isempty(strfind(x,img_start_str)), mdoc{1}));    % Get line numbers for starting strings
img_start = find(cellfun(@(x) contains(x,img_start_str), mdoc{1}));    % Get line numbers for starting strings

n_img = numel(img_start);    % Number of starting strings

% Get start and end values
img_indices = zeros(n_img,2);
img_indices(:,1) = img_start;
img_indices(1:end-1,2) = img_start(2:end);
img_indices(end,2) = size(mdoc{1},1);

% Initialize struct array
mdoc_param = struct;

% Get field sizes
f_size = zeros(n_fields,1);
for i = 1:n_fields
    f_size(i) = numel(fields{i});
end


%% Check for tilt axis angle

taa_idx = strcmp(fields,'TiltAxisAngle');
if any(taa_idx)
    % Find index in cell
    taa_cell_match = cellfun(@(x) strfind(x,'Tilt axis angle'), mdoc{1},'UniformOutput',false);
    
    if all(cellfun(@isempty,taa_cell_match))
        % Hack for Tomo5
        
        % Match for tiltaxisangle
        taa_cell_match = cellfun(@(x) strfind(x,'TiltAxisAngle'), mdoc{1},'UniformOutput',false);
        
        % Find matching line
        taa_cell_idx = find(~cellfun(@(x) isempty(x),taa_cell_match));
        
        % Find start of string
        taa_str_idx = taa_cell_match{taa_cell_idx};
        
        % Find first "=" after string
        taa_start = strfind(mdoc{1}{taa_cell_idx}(taa_str_idx:end),'=');
        
        % Parse string
        tmp_taa = strtrim(mdoc{1}{taa_cell_idx}(taa_str_idx+taa_start(1):end));              
        
        % Find first ',' after string
        taa_end = strfind(tmp_taa,' ');
        
        % Parse tilt axis angle
        tilt_axis_angle = str2double(tmp_taa(1:taa_end-1));
    else
        
        taa_cell_idx = find(~cellfun(@(x) isempty(x),taa_cell_match));

        % Find start of string
        taa_str_idx = taa_cell_match{taa_cell_idx};

        % Find first "=" after string
        taa_start = strfind(mdoc{1}{taa_cell_idx}(taa_str_idx:end),'=');

        % Find first ',' after string
        taa_end = strfind(mdoc{1}{taa_cell_idx}(taa_str_idx+taa_start(1):end),',');

        % Parse tilt axis angle
        tilt_axis_angle = str2double(mdoc{1}{taa_cell_idx}((taa_str_idx+taa_start(1)):(taa_str_idx+taa_start(1)+taa_end(1)-2)));
    end
end
    



%% Get fields

% Loop through images
for i = 1:n_img
    
    % Parse image lines
    temp_lines = mdoc{1}(img_indices(i,1):img_indices(i,2));
    
    % Loop through fields
    for j = 1:n_fields
               
        switch fields{j}
            
            case 'TiltAxisAngle'
                mdoc_param(i).TiltAxisAngle = tilt_axis_angle; 
                
            otherwise
                % Look for field
                f_idx = cellfun(@(x) strncmpi(fields{j},x,f_size(j)),temp_lines);            
                if ~any(f_idx)
                    error(['ACHTUNG!!! Field "',fields{j},'" not found!!!']);
                end
                
                % Parse line
                value = temp_lines{f_idx}((f_size(j)+d_size+1):end);

                % Check value type
                switch field_types{j}
                    case 'str'
                        mdoc_param(i).(fields{j}) = value;
                    case 'num'
                        mdoc_param(i).(fields{j}) = str2num(value); %#ok<ST2NM>
                end
        end
    end
        
end








