function stack_aligned = tm_check_if_aligned(tomolist)
%% tm_check_if_aligned
% Check if an entry in the tomolist has been aligned. Given IMOD alignment
% requires manual alignment, there's no good way to update the motivelist.
% The checking here checks for the assignment of alignment software,
% followed by checking for the files required for reconstruction. 
%
% WW 06-2025


%% Initialize

% Number of stacks
n_stacks = numel(tomolist);

% Output array
stack_aligned = false(size(tomolist));

%% Check if aligned

for i = 1:n_stacks
    
    % Check if alignment software was assigned
    if ~sg_check_param(tomolist(i),'alignment_software')
        continue
    end

    % Parse name of stack used for alignment     
    switch tomolist(i).alignment_stack
        case 'unfiltered'
            process_stack = tomolist(i).stack_name;
        case 'dose-filtered'
            process_stack = tomolist(i).dose_filtered_stack_name;
        otherwise
            error('ACTHUNG!!! Unsuppored stack!!! Only "unfiltered" and "dose-filtered" supported!!!');
    end        
    [~,name,~] = fileparts(process_stack);

    % Parse alignment file names        
    switch tomolist(i).alignment_software
        case 'AreTomo'
            xf_name = [tomolist(i).stack_dir,'AreTomo/',name,'.xf'];
            tlt_name = [tomolist(i).stack_dir,'AreTomo/',name,'.tlt'];
        case 'imod'
            % IMOD files
            xf_name = [tomolist(i).stack_dir,'imod/',name,'.xf'];
            tlt_name = [tomolist(i).stack_dir,'imod/',name,'.tlt'];
        otherwise 
            if startsWith(tomolist(i).alignment_software,'sg_refine_')
                xf_name = [tomolist(i).stack_dir,tomolist(i).alignment_software,'/',name,'.xf'];
                tlt_name = [tomolist(i).stack_dir,tomolist(i).alignment_software,'/',name,'.tlt'];
            else
                error(['ACHTUNG !!! ',tomolist(i).alignment_software,' is an unsupported alignment_software type!!!']);
            end
    end

    % Check for files
    if ~exist(xf_name,'file') || ~exist(tlt_name,'file')
        continue
    end

    stack_aligned(i) = true;
    
end

