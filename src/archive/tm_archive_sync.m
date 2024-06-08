function tm_archive_sync(filename_cell)
%% tm_archive_rsync
% Take a filename cell that consists of a source and destination, check the
% destination directory structure, and rsync files. 
%
% WW 09-2023

%% Rsync files

% Number of files
n_files = size(filename_cell,1);

% Loop through files
for i = 1:n_files
    
    % Make file structure
    [dir,~,~] = fileparts(filename_cell{i,2});
    system(['mkdir -p ',dir]);
    
    % Rsync file

    system(['ln -sf ',filename_cell{i,1},' ',filename_cell{i,2}]);
    
end


    
    


