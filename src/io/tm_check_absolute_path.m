function path = tm_check_absolute_path(root_dir,target_dir)
%% tm_check_absolute_path
% A function to check if target directory is a relative path or absolute
% path. If it has a starting '/', it is an absolute path; otherwise, it is
% a relative path and the root_dir is appended.
%
% WW 06-2025

%% Check check

if strcmp(target_dir(1),'/')
    path = target_dir;
else
    if strcmp(target_dir(1:2),'./')
        path = [root_dir,target_dir(3:end)];
    else
        path = [root_dir,target_dir];
    end
end

