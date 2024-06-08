function new_str = tm_fix_filename_brackets(str)
%% tm_fix_filename_brackets
% Add an escape backlash to squarebackets for bash systems.
%
% WW 05-2022

%% Fix strings

new_str = strrep(str,'[','\[');
new_str = strrep(new_str,']','\]');

