function [path, name, ext] = tm_fileparts_windows(filename)
%% tm_fileparts_windows
% A function to parse the parts of a filename in windows format. 
%
% It is assumed that the last '\' separates the path and name, and that the
% final '.' separates the name and extension. 
%
% WW 12-2017

%% Parse filename

% Find slash
slashes = strfind(filename,'\');
l_slash = slashes(end);

% Find period
periods = strfind(filename,'.');
l_period = periods(end);

% Parse filename
path = filename(1:l_slash-1);
name = filename(l_slash+1:l_period-1);
ext = filename(l_period:end);
