function tomoman_write_ctfphaseflip(tomolist,imod_stack)
%% tomoman_write_ctfphaseflip
% A function to take a tomolist and write out the CTF parameters in
% CTFPHASEFLIP format. 
%
% Input is a signle tomolist entry.
%
% WW 07-2018

%% Initialize

% Determine stack name
switch imod_stack
    case 'unfiltered'
        imod_name = tomolist.stack_name;
    case 'dose_filt'
        imod_name = tomolist.dose_filtered_stack_name;
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end
[dir,name,~] =fileparts(imod_name);
if ~isempty(dir)
    dir = [dir,'/'];
end

% Get tilt angles
tlt_name = [tomolist.stack_dir,'/',name,'.tlt'];
try
    tlt = dlmread(tlt_name);
catch
    tlt = tomolist.rawtlt;
end

% Parse output name
out_name = [tomolist.stack_dir,'/ctfphaseflip_',tomolist.ctf_determination_algorithm,'.txt'];

%% Write output

% Number of columns is stored CTF
n_col = size(tomolist.determined_defocii,2);

% Open output file
output = fopen(out_name, 'w');

% Initialize output formatting and write header
n_tilts = numel(tlt);
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
    line(3:4) = tlt(i);
    line(5) = round(tomolist.determined_defocii(i,1)*1000);
    line(6) = round(tomolist.determined_defocii(i,2)*1000);
    line(7) = round(tomolist.determined_defocii(i,3));
    
    if n_col == 4
        line(8) = round(tomolist.determined_defocii(i,4));
    end
    
    % Write output
    fprintf(output,formatSpec,line);
end



% Close file
fclose(output);



