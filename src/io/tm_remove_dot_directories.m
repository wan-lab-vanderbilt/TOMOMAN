function dir_struct = tm_remove_dot_directories(dir_struct)
%% tm_remove_dot_directories
% Remove the . and .. from a dir struct.
%
% WW 08-2022

%% Remove dots

% Indices of dot directories
dot_idx = strcmp({dir_struct.name},'.') + strcmp({dir_struct.name},'..');

% Parse remaining directories
dir_struct = dir_struct(~dot_idx);


