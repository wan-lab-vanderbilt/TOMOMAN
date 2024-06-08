function param = tm_read_paramfile(filename)
%% tm_read_param_file
% Function for reading a tomoman param file. Param files are plain text
% files that contain paramter names and values separated by an "=" sign.
% Comments are noted using "#".
%
% Parameters are returned as a cell containing a subcell with parameter
% names and another subcell with values.
%
% WW 05-2022

%% Read and parse file

% Read file
fid = fopen(filename,'r');
param = textscan(fid, '%s=%s','CommentStyle','#');
fclose(fid);


