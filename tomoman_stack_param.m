function tomolist = tomoman_stack_param(tomolist,st)
%% tomoman_stack_param
% Check the stack parameters in the tomolist.
%
% WW 02-2018

%% Update stack parameters

% Number of stacks in tomolist
n_stacks = size(tomolist,1);

for i = 1:n_stacks
    
    tomolist(i).image_size = st.image_size;
    if ~isempty(st.prealigned)
        tomolist(i).frames_aligned = true;
        tomolist(i).frame_alignment_algorithm = st.prealigned;
        tomolist(i).stack_name = tomolist(i).raw_stack_name;
    end
    
end


