function tomolist = tm_read_tomolist(root_dir,tomolist_name)
%% tm_read_tomolist
% Read existing or initialize new tomolist struct array. 
%
% WW 05-2022

%% Check check
root_dir = sg_check_dir_slash(root_dir);

%% Read list

if exist([root_dir,tomolist_name],'file')
    disp('TOMOMAN: Old tomolist found... Loading tomolist!!!');
    load([root_dir,tomolist_name],'tomolist');
else
    disp('TOMOMAN: No tomolist found... Generating new tomolist!!!');
    tomolist = struct([]);
end