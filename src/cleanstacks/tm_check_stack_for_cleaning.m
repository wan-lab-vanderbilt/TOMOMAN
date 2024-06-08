function cleaned = tm_check_stack_for_cleaning(stack_name, n_good_tilts)
%% tm_check_stack_for_cleaning
% Function to check if stack has been cleaned by comparing number of images
% in stack. 
%
% WW 07-2023


% Read header
header = sg_read_mrc_header(stack_name);

% Check stack size
if header.nz == n_good_tilts
    disp(['TOMOMAN: ACHTUNG!!! ',stack_name,' seems to have already been cleaned...'])
    cleaned = true;
elseif header.nz > n_good_tilts
    cleaned = false;
else
    error(['TOMOMAN: ACHTUNG!!! ',stack_name,' has fewer tilts than expected!!!']);
end
    


end