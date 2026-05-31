function tm_write_ctfphaseflip_file(name,tilt_angles,defocii)
%% tm_write_ctfphaseflip_file
% Write a ctfphseflip formatted CTF file.
%
% WW 01-2026

%% Write ouptut

% Number of columns is stored CTF
n_col = size(defocii,2);

% Open output file
output = fopen(name, 'w');

% Initialize output formatting and write header
n_tilts = numel(tilt_angles);
digits = ceil(log10(n_tilts+1));
switch n_col
    case 3
        formatSpec = ['%',num2str(digits),'d    %',num2str(digits),'d    %6.2f    %6.2f    %4d    %4d    %3.1f\n'];
        fprintf(output,['1  0 0. 0. 0  3','\n']);
    case 4
        formatSpec = ['%',num2str(digits),'d    %',num2str(digits),'d    %6.2f    %6.2f    %4d    %4d    %3.1f    %3.2f\n'];
        fprintf(output,['13  0 0. 0. 0  3','\n']);
end


% Write information per tilt
for i = 1:n_tilts
    
    % Output line
    switch n_col
        case 3
            line = zeros(1,7);
        case 4
            line = zeros(1,8);
    end
    
    line(1:2) = i;
    line(3:4) = tilt_angles(i);
    line(5) = round(defocii(i,1)*1000);
    line(6) = round(defocii(i,2)*1000);
    line(7) = defocii(i,3) ;
    
    if n_col == 4
        line(8) = round(defocii(i,4));
    end
    
    % Write output
    fprintf(output,formatSpec,line);
end



% Close file
fclose(output);



