function tm_imod_clean_folders(tomolist_name)
%% tm_imod_clean_folders
% Clean up imod folders by removing all temporary files (i.e. those ending
% with ~) and .mrc files. 
%
% WW 05-2026

%% Clean folders

load(tomolist_name);
n_tomos = numel(tomolist);

for i = 1:n_tomos
    
    % Check if processed
    if ~tm_check_if_aligned(tomolist(i))
        continue
    else
        if ~strcmpi(tomolist(i).alignment_software,'imod')
            continue
        end
    end
    
    system(['rm -f ',tomolist(i).stack_dir,'imod/*~']);
    system(['rm -f ',tomolist(i).stack_dir,'imod/*.mrc']);
    
end


