function [xf,tlt,rotation] = tm_aretomo_aln2tltxf(aln_name,binning)
%% tm_aretomo_aln2tltxf
% Convert an AreTomo .aln file to IMOD .xf and .tlt files. Binning refers
% to the input binning of the tilt-series used for AreTomo alignment.
%
% WW: last tested for AreTomo 1.0.11
%
% SK, WW 06-2022


%% Read input

% Read file
fid = fopen(aln_name,'r');
data = textscan(fid, '%s', 'Delimiter', '\n');
data = data{1};
fclose(fid);

% Remove comment lines
n_lines = numel(data);  % Number of lines in text file
comment_idx = false(size(data));
for i = 1:n_lines
    % Check for octothorpe
    if strcmp(data{i}(1),'#')
        comment_idx(i) = true;
    end
end
data = data(~comment_idx);  % Keep non-comment lines


% Number of tilts
n_tilts = numel(data);    % Assume 3-line header

% Initialize arrays
xf = zeros(n_tilts,6);      % IMOD .xf format
tlt = zeros(n_tilts,1);     % Imod .tlt format

%% Convert data

for i = 1:n_tilts
    
    % Split line
    tlt_data = strsplit(data{i},' ');

    % Parse tilt
    tlt(i) = str2double(tlt_data{10});
    
    
    % Convert rotation angle to matrix
    rotation = str2double(tlt_data{2});
    xf(i,1) = cosd(-rotation);
    xf(i,2) = -sind(-rotation);
    xf(i,3) = sind(-rotation);
    xf(i,4) = cosd(-rotation);
    
    % Parse shifts
    xshift = -str2double(tlt_data{4});
    yshift = -str2double(tlt_data{5});
    
    % Convert reference frame of shifts
    xf(i,5) = (xf(i,1).*xshift + xf(i,2).*yshift).*binning;
    xf(i,6) = (xf(i,3).*xshift + xf(i,4).*yshift).*binning;
    

    
end


end
