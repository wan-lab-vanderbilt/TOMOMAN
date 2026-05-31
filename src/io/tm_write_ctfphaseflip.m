function tm_write_ctfphaseflip(tomolist,task)
%% tm_write_ctfphaseflip
% A function to take a tomolist and write out the CTF parameters in
% CTFPHASEFLIP format. 
%
% Input is a signle tomolist entry.
%
% WW 07-2018

%% Initialize

% Determine stack name
switch tomolist.alignment_stack
    case 'unfiltered'
        alignment_stack = tomolist.stack_name;
    case 'dose-filtered'
        alignment_stack = tomolist.dose_filtered_stack_name;
    case 'none'
        if tomolist.dose_filtered
            warning('ACHTUNG!!! stack not yet algined... Defaulting to using dose-filtered as alignment stack name...');
            alignment_stack = tomolist.dose_filtered_stack_name;
        else
            warning('ACHTUNG!!! stack not yet algined or dose filtered... Defaulting to using unfiltered as alignment stack name...');
            alignment_stack = tomolist.stack_name;
        end
    otherwise
        error(['ACTHUNG!!! ',tomolist.alignment_stack,' is an unsuppored alignment stack... Only "unfiltered" and "dose-filtered" supported!!!']);
end
[dir,name,~] =fileparts(alignment_stack);
if ~isempty(dir)
    dir = [dir,'/'];
end

% Get tilt angles
if tomolist.stack_aligned
    switch tomolist.alignment_software
        case 'AreTomo'
            tlt_name = [tomolist.stack_dir,'AreTomo/',name,'.tlt'];
        case 'imod'
            % IMOD files
            tlt_name = [tomolist.stack_dir,'imod/',name,'.tlt'];
        otherwise
            if startsWith(tomolist.alignment_software,'sg_refine_')
                tlt_name = [tomolist.stack_dir,tomolist.alignment_software,'/',name,'.tlt'];
            else
                error(['ACHTUNG !!! ',tomolist(t_idx).alignment_software,' is an unsupported alignment_software type!!!']);
            end
    end
    tlt = dlmread(tlt_name);
    
else
    tlt = tomolist.rawtlt;
end

% Check for mismatch (e.g. when using MotionCor3)
if numel(tlt) ~= size(tomolist.determined_defocii,1)
    if numel(tomolist.collected_tilts) == size(tomolist.determined_defocii,1)
        warning('Mismatch between number of teremined tilt angles and number of CTF estimation entries... Did you redo cleaning or motion correction? Defaulting to collected tilts...');
        tlt = sort(tomolist.collected_tilts);
    else
        error(['Irreconcilable difference between CTF estimation entries (',num2str(size(tomolist.determined_defocii,1)),...
               ') and collected tilts ',numel(tomolist.collected_tilts),'!!!']);
    end
end


% Parse output name
switch task
    case 'ctffind4'
        out_name = [tomolist.stack_dir,'ctffind4/ctfphaseflip_ctffind4.txt'];
    case 'tiltctf'
        out_name = [tomolist.stack_dir,'tiltctf/ctfphaseflip_tiltctf.txt'];
    case 'sg_ctfrefine'
        out_name = [tomolist.stack_dir,'sg_ctfrefine/ctfphaseflip_sg_ctfrefine.txt'];
    case 'motioncor3'
        out_name = [tomolist.stack_dir,'MotionCor3/ctfphaseflip_motioncor3.txt'];
    case 'sg_refine'
        out_name = [tomolist.stack_dir,tomolist.alignment_software,'/ctfphaseflip_sg_refine.txt'];
end

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
    line(7) = tomolist.determined_defocii(i,3) ;
    
    if n_col == 4
        line(8) = round(tomolist.determined_defocii(i,4));
    end
    
    % Write output
    fprintf(output,formatSpec,line);
end



% Close file
fclose(output);



