function tm_save_tomolist(root_dir,tomolist_name,tomolist)
%% tm_save_tomolist
% A function to save the tomolist while backing up the previous one prior
% to saving. 
%
% The backup tomolists are saved into a .backup_tomolists/ subfolder in the
% root_dir and take the same name with an appended timestamp.
%
% If no tomolist is provied, only the backup will be performed.
%
% WW 07-2025

%% Check check

if nargin == 2
    tomolist = [];
end


%% Save tomolist

% Check directory slash
root_dir = sg_check_dir_slash(root_dir);

% Check for previous tomolist
if ~exist([root_dir,tomolist_name],'file')
    disp('No previous tomolist detected... Saving new tomolist!!!');
    save([root_dir,tomolist_name],'tomolist');
    return
end
disp('Backing up previous tomolist... Saving new tomolist!!!');

% Parse name
[dir,name,ext] = fileparts(tomolist_name);
dir = sg_check_dir_slash(dir);

% Generate timestamp string
timestamp = strrep(char(datetime('now')),' ','_');

% Backup name
backup_name = [dir,name,'_',timestamp,ext];

% Check backup directory
if ~exist([root_dir,'.backup_tomolists/',dir],'dir')
    mkdir([root_dir,'.backup_tomolists/',dir]);
end

% Copy backup
copyfile([root_dir,tomolist_name],[root_dir,'.backup_tomolists/',backup_name]);
if isempty(tomolist)
    return
end

% Save tomolist
save([root_dir,tomolist_name],'tomolist');



