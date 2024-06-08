function tm_fix_frame_brackets(frame_ext,root_dir,dest_dir)
%% tm_fix_frame_brackets
% A function to remove square backets from the filenames of frame files. 
% The left bracket is replaced with an underscore while the right bracket 
% is removed. 
%
% WW 05-2022

%% Initialize

if nargin < 2
    root_dir = './';
end

if nargin < 3
    dest_dir = root_dir;
end


%% Fix Brackets

% Find mdocs
frame_dir = dir([root_dir,'*',frame_ext]);
n_frames = numel(frame_dir);

for i = 1:n_frames
    
    % Generat new name
    new_name = strrep(frame_dir(i).name,'[','_');
    new_name = strrep(new_name,']','');
    
    % Rename file
    movefile([root_dir,frame_dir(i).name],[dest_dir,new_name]);
    
end

