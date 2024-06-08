function tm_metadata_add_new(root_dir,tomolist_name, type)
%% tm_metadata_add_new
% A function to link arbitrary metadata files to a tomolist. This allows
% other functions to access this metadata using the tomolist.
%
% The metadata field in the tomolist is a 2-field struct array; the "type"
% field is the name of the metadata while the "files" field contains the
% filenames of the metadata. 
%
% Metadata fields are stored in metadata/[type]/ subfolders in the
% tilt-series folders. 
%
% Re-running this function with the same type will re-scan the folders and
% add/remove files. Re-running with a different type appends a new type to 
% the metadata field.
%
% WW 08-2022


%% Check check
root_dir = sg_check_dir_slash(root_dir);

%% Initialiize

% Read tomolist
tomolist = tm_read_tomolist(root_dir,tomolist_name);
n_tomos = numel(tomolist);

% Loop through tomos
% Scan for field / Append new field
% Scan files and store names

%% Scan for metadata

% Loop through tomos
for i = 1:n_tomos    
    disp(['TOMOMAN: ','Scanning for metadata type ',type,' for ',tomolist(i).stack_name]);
    
    % Detect field
    if isempty(tomolist(i).metadata)    % If no metadata stored...
        % Initialize metadata struct
        tomolist(i).metadata = struct(type,[]);
    else
        % Parse fields
        temp_fields = fieldnames(tomolist(i).metadata);
        if ~any(strcmp(type,temp_fields))
            % Add new field
            tomolist(i).metadata.(type) = [];
        end
    end
    
    % Parse metadata directory
    meta_dir = dir([tomolist(i).stack_dir,'metadata/',type,'/']);
    meta_dir = tm_remove_dot_directories(meta_dir);        
    if isempty(meta_dir)
        warning(['TOMOMAN: ','ACHTUNG!!! No metadata files of type ',type,' detected for ',tomolist(i).stack_name]);
        continue
    end
    
    % Store directory contents
    tomolist(i).metadata.(type) = {meta_dir.name}';
    disp(['TOMOMAN: ','Metadata files of type ',type,' stored...']);
end
    
% Write new tomolist
save([root_dir,tomolist_name],'tomolist');
disp(['TOMOMAN: ','tomolist saved...']);
    
    

