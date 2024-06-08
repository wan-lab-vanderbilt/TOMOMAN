function rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,field,value)
%% sg_rlntomocoord2_2_fill_field
% A function to fill a rlntomocoord2_2 field with given values. The values must either
% have the same dimensions of the rlntomocoord2_2 or have a single value. In the case
% of a single value, this value as assigned to all fields.
%
% The given fields are checked against the default fields and types are
% enforced.
%
% WW 07-2018

%% Check check

n_rlntomocoord2_2s = numel(rlntomocoord2_2);
n_values = numel(value);

if (n_values ~= n_rlntomocoord2_2s) && (n_values ~= 1)
    error('ACHTUNG!!! Number of values is not 1 and does not match number of rlntomocoord2_2 entries!!!');
end

% Number of repeats
if n_values ~= n_rlntomocoord2_2s
    rep_val = n_rlntomocoord2_2s;
else 
    rep_val = 1;
end



%% If non-cell input, parse and store

% Get fields
rlntomocoord2_2_fields = tm_get_rlntomocoord2_2_fields;
f_idx = strcmp(field,rlntomocoord2_2_fields(:,1));

switch rlntomocoord2_2_fields{f_idx,3}
    
    case 'float'
        
        if isnumeric(value) || islogical(value)
            value = repmat(num2cell(double(value)),[rep_val,1]);
        elseif ischar(value)
            error('ACHTUNG!!! You are trying to store strings into a "float" field!!!');
        elseif iscell
            if any(cellfun(@(x) ~isnumeric(x) & ~islogical(x),value))
                error('ACHTUNG!!! You are trying to store a cell array with non-numeric inputs into a "float" field!!!');
            else
                value = repmat(num2cell(cellfun(@(x) double(x),value)),[rep_val,1]);
            end
        end
        
    case 'int'
        
        if isnumeric(value) || islogical(value)
            value = repmat(num2cell(int64(value)),[rep_val,1]);
        elseif ischar(value)
            error('ACHTUNG!!! You are trying to store strings into an "int" field!!!');
        elseif iscell
            if any(cellfun(@(x) ~isnumeric(x) & ~islogical(x),value))
                error('ACHTUNG!!! You are trying to store a cell array with non-numeric inputs into an "int" field!!!');
            else
                value = repmat(num2cell(cellfun(@(x) int64(x),value)),[rep_val,1]);
            end
        end
            
    case 'str'
        
        if isnumeric(value) || islogical(value)
            value = repmat(cellstr(num2str(value(:))),[rep_val,1]);
        elseif ischar(value)
            if n_values ~= n_rlntomocoord2_2s
                value = repmat({value},[rep_val,1]);
            else
                value = cellstr(value(:));
            end        
        elseif iscell(value)
            num_idx = cellfun(@(x) isnumeric(x) | islogical(x),value);
            if any(num_idx)
                value(num_idx) = strsplit(num2str([value{num_idx}]));
            end
            value = repmat(value,[rep_val,1]);
        end
        
end

% Store value
[rlntomocoord2_2.(field)] = value{:};
