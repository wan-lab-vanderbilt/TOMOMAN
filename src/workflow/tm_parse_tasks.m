function task = tm_parse_tasks(paramfilename)
%% tm_parse_tasks
% Read in first line of TOMOMAN .param file to parse and return name of
% task.
%
% WW 06-2022

%% Parse task

% Read file
fid = fopen(paramfilename,'r');
text = textscan(fid, '## tomoman_%s', 1);   % Get first line
fclose(fid);

% Return task
task = text{:}{:};

end



