function tomoman_link_tomos(root_dir,tomolist_name,input_dir,input_ext,output_dir, output_ext)
%% tomoman_link_tomos
% A function to read a tomolist and create symlinks for reconstructed
% tomograms. Links are named after the tomo_num field in the tomolist,
% matching the required input for STOPGAP extraction. 
%
% Input directory is relative to the root_dir
%
% Output directory requires full path.
%
% If given, link will be given the output_ext extension. Otherwise, the
% same extension as the input will be used. 
%
% WW 08-2022


%% Check check

if nargin < 6
    output_ext = [];
end


%% Initialize

% Read tomolist
tomolist = tm_read_tomolist(root_dir,tomolist_name);
n_tomos = numel(tomolist);


%% Create links

for i = 1:n_tomos
    
    % Check for skip
    if tomolist(i).skip
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
    [~,stack_name,~] = fileparts(process_stack);
    tomo_name = [stack_name,input_ext];
    
    % Check for tomo
    if ~exist([root_dir,input_dir,tomo_name],'file')
        warning(['ACHTUNG!!! Tomogram ',tomo_name,' not found!!! Moving to next tomogram...']);
        continue
    end
    
    % Check for extension
    if isempty(output_ext)
        [~,~,ext] = fileparts(tomo_name);
    else
        ext = output_ext;
    end
    
    % Make link
    system(['ln -s ',root_dir,input_dir,tomo_name,' ',output_dir,num2str(tomolist(i).tomo_num),ext]);
    
end


