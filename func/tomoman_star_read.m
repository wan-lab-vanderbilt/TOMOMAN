function struct_array = tomoman_star_read(star_name, parsenum, fieldtypes)
%% tomoman_star_read
% A function to read a .star file as a struct array.
%
% The parsenum parameter, given as 0 or 1, decides if the function tries to
% determine numeric fields. 
%
% A cell array containing field types can also be given to override numeric
% testing. Field types are: 'str','num','boo' for string, numeric, and
% logical types.
%
% v1: WW 11-2017
% v2: WW 01-2018: Updated numeric parsing; can now properly parse
% comma-separated numeric arrays.
% v3: WW 04-2018: Updated to take in field types
%
% WW 04-2018


%% Check check!!!
if nargin < 3
    fieldtypes = [];
end
if nargin < 2
    parsenum = 1;
end
if (nargin > 3) || (nargin < 1)
    error('Achtung!!! Incorrect number of inputs!!!');
end

if ~isempty(fieldtypes) && (parsenum==1)
    warning('ACHTUNG!!! "fieldtypes" will be used rather than automatic numeric parsing!!!');
end

%% Read format information

% Open .star file
fid = fopen(star_name,'r');
star = textscan(fid, '%s', 'Delimiter', '\n');

% Find fields
idx_fields = find(strncmpi(star{1},'_',1));
n_fields = size(idx_fields,1);

% Check number of fields against fieldtypes
if ~isempty(fieldtypes)
    if n_fields ~= numel(fieldtypes)
        error('ACHTUNG!!! Number of fields in .star file do not match number of input fieldtypes!!!');
    end
end

% Find empty lines
empty_lines = cellfun('isempty',star{1});

% Parse fields
fields = cell(n_fields,1);
for i = 1:n_fields
    
    % Get field line
    temp_field = textscan(star{1}{idx_fields(i)},'%s %s');
    
    % Write field to array
    fields{i} = temp_field{1}{1}(2:end);
end
clear star


%% Read data and convert to struct array

% Data start
header_size = idx_fields(end);

% Number of data lines
n_data = sum(~empty_lines(header_size+1:end));

% Formatting of data
formatSpec = repmat(cat(2,repmat('%s ',[1,n_fields]),'\n '),[1,n_data]);


% Move text scanner to beginning of file
fseek(fid,1,'bof');

% Read data into cell
data_cell = reshape(textscan(fid,formatSpec,'HeaderLines',header_size-1),n_fields,n_data);
fclose(fid);

% Parse out lowest cells
for i = 1:numel(data_cell)
    data_cell{i} = data_cell{i}{:};
end

% Return struct
struct_array = cell2struct(data_cell,fields);


%% Attempt to parse numbers

if (parsenum == 1) && isempty(fieldtypes)
    for i = 1:n_fields
        
        % Test for numbers
        c = {struct_array.(fields{i})};
        test = all(cellfun(@(x) all(ismember(x,'0123456789+-.eEdD,')), c));
        
        if test == 1
            numcell = cellfun(@(x) str2double(strsplit(x,{',',' '})), {struct_array.(fields{i})},'UniformOutput', false);
            [struct_array.(fields{i})] = numcell{:};
        end
    end
end

%% Assign field types from input array

if ~isempty(fieldtypes)    
    for i = 1:n_fields
        
        switch fieldtypes{i}
            case 'num'
               numcell = cellfun(@(x) str2double(strsplit(x,{',',' '})), {struct_array.(fields{i})},'UniformOutput', false);
               [struct_array.(fields{i})] = numcell{:}; 
            case 'boo'
               boocell = num2cell(cellfun(@(x) logical(x),{struct_array.(fields{i})}));
               [struct_array.(fields{i})] = boocell{:};
        end
        
    end
end

            

    

