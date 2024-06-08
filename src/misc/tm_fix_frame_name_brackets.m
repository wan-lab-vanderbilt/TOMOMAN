%% tm_fix_frame_name_brackets
% A function to parse frame filenames from .mdoc files and replace the
% square brackets with different characters. Original .mdoc files are saved
% into a backup folder, which can be used to undo the name changes.
%
% Running in unfix mode restores the backup .mdoc files and original frame
% names.
% 
% WW 06-2022

%% Inputs

% Directories
root_dir = '/hd1/wwan/2022/2022-06-30_glacios/06302022_wanw_reutzeam_5dayMeV-dialysis/06302022_wanw_reutzeam_5dayMeV-dialysis_2/';      % Root directory
mdoc_dir = 'rawdata/';                                          % Relative directory to .mdoc files.
frame_dir = 'frames/';                                          % Relative directory to frames.


% Bracket Replacements
l_bracket = '_';    % Relplacement characters for left bracket "["
r_bracket = '';     % Relplacement characters for right bracket "]"

% Mode
mode = 'fix';       % Modes are 'fix' and 'unfix'.


%% Initialize

% Find .mdoc files
d = dir([root_dir,mdoc_dir,'*.mdoc']);
n_mdoc = numel(d);


% .mdoc fields for parsing
mdoc_fields = {'SubFramePath'};
mdoc_field_types = {'str'};


%% Fix brackets

switch mode
    
    % Fix brackets
    case 'fix'
        
        % Loop through names
        for i = 1:n_mdoc

            % Parse original frame names
            mdoc_name = [root_dir,mdoc_dir,d(i).name];
            mdoc_param1 = tm_parse_mdoc(mdoc_name,mdoc_fields,mdoc_field_types);
            n_frames = numel(mdoc_param1);

            % Fix .mdoc files
            tm_fix_mdoc_brackets(mdoc_name,mdoc_name,'backup');


            % Parse new frame names
            mdoc_param2 = tm_parse_mdoc(mdoc_name,mdoc_fields,mdoc_field_types);
            if numel(mdoc_param2) ~= n_frames
                warning(['ACHTUNG!!!, Something has gone wrong with the fixing ',d(i).name,'!!! The number of frames before and after have changed!!!']);
                continue
            end


            % Rename frames
            for j = 1:n_frames

                % Parse starting name
                [~,name1,ext1] = tm_fileparts_windows(mdoc_param1(j).SubFramePath);
                frame1 = [root_dir,frame_dir,name1,ext1];

                % Parse fixed name
                [~,name2,ext2] = tm_fileparts_windows(mdoc_param2(j).SubFramePath);
                frame2 = [root_dir,frame_dir,name2,ext2];

                system(['mv ',frame1,' ',frame2]);

            end

        end

        
        
    case 'unfix'
        
        
        
        % Loop through names
        for i = 1:n_mdoc

            % Parse fixed frame names
            mdoc_name = [root_dir,mdoc_dir,d(i).name];
            mdoc_param1 = tm_parse_mdoc(mdoc_name,mdoc_fields,mdoc_field_types);
            n_frames = numel(mdoc_param1);

            % Replace fixed with backup .mdoc
            system(['cp ',root_dir,mdoc_dir,'backup/',d(i).name,' ',root_dir,mdoc_dir,d(i).name]);


            % Parse new frame names
            mdoc_param2 = tm_parse_mdoc(mdoc_name,mdoc_fields,mdoc_field_types);
            if numel(mdoc_param2) ~= n_frames
                warning(['ACHTUNG!!!, Something has gone wrong with the fixing ',d(i).name,'!!! The number of frames before and after have changed!!!']);
                continue
            end


            % Rename frames
            for j = 1:n_frames

                % Parse starting name
                [~,name1,ext1] = tm_fileparts_windows(mdoc_param1(j).SubFramePath);
                frame1 = [root_dir,frame_dir,name1,ext1];

                % Parse fixed name
                [~,name2,ext2] = tm_fileparts_windows(mdoc_param2(j).SubFramePath);
                frame2 = [root_dir,frame_dir,name2,ext2];

                system(['mv ',frame1,' ',frame2]);

            end

        end
        
        
        
        
        
        
end










