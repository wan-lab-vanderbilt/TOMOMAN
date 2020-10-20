function defocii = tomoman_gctf_star_to_ctfphaseflip(tlt_name,star_name,out_name)
%% tomoman_gctf_star_to_ctfphaseflip
% A function to take a GCTF star file and convert it to the format required
% for IMOD's ctfphaseflip option. 
%
% WW 10-2017 

%% Initialize

% Read tlt file
tlt = dlmread(tlt_name);
n_tilts = size(tlt,1);

% Read star file
star = tomoman_star_read(star_name);
if n_tilts ~= numel(star)
    error(['ACHTUNG!!! Incorrect number of tilts! .tlt file contains ',...
        num2str(n_tilts),' while .star contains ',num2str(numel(star)),'!!!']);
end

% Initialize output file
digits = ceil(log10(n_tilts+1));
formatSpec = ['%',num2str(digits),'d    %',num2str(digits),'d    %6.2f    %6.2f    %4d    %4d    %3.1f\n'];
output = fopen(out_name, 'w');
fprintf(output,['1  0 0. 0. 0  3','\n']);

%% Write output

for i = 1:n_tilts
    
    % Output line
    line = zeros(1,7);
    line(1:2) = i;
    line(3:4) = tlt(i);
    line(5) = round(star(i).rlnDefocusV/10);
    line(6) = round(star(i).rlnDefocusU/10);
    line(7) = star(i).rlnDefocusAngle;
    
    % Write output
    fprintf(output,formatSpec,line);
end

% Close file
fclose(output);

% Return defocus table
defocii = zeros(n_tilts,3);
defocii(:,1) = [star.rlnDefocusU]./10000;
defocii(:,2) = [star.rlnDefocusV]./10000;
defocii(:,3) = [star.rlnDefocusAngle];


