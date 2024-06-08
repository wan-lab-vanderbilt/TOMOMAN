function [tomo_num, tomo_name, digits] = tm_parse_tomo_num(filename,prefix)
 %% tm_parse_tomo_num
 % Parse tomogram number from filename and prefix. The tomogram number is
 % assumed to start at after the prefix and end before the first period.
 %
 % Different acquisition software (i.e. SerialEM vs Tomo5) seem
 % inconsistent in the file extension, so this assumption should be more
 % reliable that setting strict start and end numbers. 
 %
 % WW 06-2022
 
 %% Parse

% Determine size of prefix
prefix_size = numel(prefix);

% Determine position of first period after prefix
temp_str = filename(prefix_size+1:end);
idx = strfind(temp_str,'.');

% Parse tomogram number
tomo_num = str2double(filename(prefix_size+1:prefix_size+idx(1)));

% Parse tomogram name
tomo_name = filename(1:prefix_size+idx(1)-1);

% Parse digits for tomo num
digits = (prefix_size+idx(1)) - (prefix_size+1);
 
 