function n_stacks = tm_novactf_generate_defocus_files(p,tomolist, novactf, dep, tiltcom, tlt_name)
%% tm_novactf_generate_defocus_files
% A function for generating a set of defocus files via novaCTF. First, the
% script copies the ctfphaseflip.txt file from the stack_dir to the novaCTF
% folder. Then it generates a parameter file and runs novaCTF to generate a 
% set of defocus files. It then determines the number of stacks required 
% and returns this value. 
%
% Inputs are one line of the tomolist, the paramater array, and the 
% tilt.com in a struct array.
%
% WW 01-2018

%% Initialize

% Copy ctfphaseflip file to novaCTF folder
switch tomolist.ctf_determination_algorithm
    case 'ctffind4'
        ctfphaseflipname = [tomolist.stack_dir,'ctffind4/ctfphaseflip_ctffind4.txt'];
    case 'tiltctf'
        ctfphaseflipname = [tomolist.stack_dir,'tiltctf/ctfphaseflip_tiltctf.txt'];
    otherwise
        disp([p.name,'ACHTUNG!!! Unsupported ctf_determination_algorithm']);
end

system(['cp ',ctfphaseflipname,' ',tomolist.stack_dir,'novaCTF/defocus_files/ctfphaseflip.txt']);


% Parse stack name
switch novactf.process_stack
    case 'unfiltered'
        stack_name = tomolist.stack_name;
    case 'dose-filtered'
        stack_name = tomolist.dose_filtered_stack_name;
    otherwise
        error([p.name,'ACHTUNG!!! ',novactf.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
end
        
%% Check for refined center

if isfield(novactf,'cen_mass')
    
    % Find tomogram index
    tomo_idx = novactf.cen_mass(:,1) == tomolist.tomo_num; 
        
    % Write shift file with center of mass
    shift_name = [tomolist.stack_dir,'/novaCTF/def_shift.txt'];
    dlmwrite(shift_name,round(novactf.cen_mass(tomo_idx,2)));
end
    


%% Generate parameter file
disp([p.name,'Running novaCTF to generate defocus files for input stacks...']);

% Initialize script ouptut
com_name = [tomolist.stack_dir,'novaCTF/scripts/setup_defocus.com'];
param = fopen(com_name,'w');

% Print lines
fprintf(param,['Algorithm defocus','\n']);
fprintf(param,['InputProjections ',tomolist.stack_dir,stack_name,'\n']);
fprintf(param,['FULLIMAGE ',num2str(tiltcom.FULLIMAGE(1)),' ',num2str(tiltcom.FULLIMAGE(2)),'\n']);
fprintf(param,['THICKNESS ',num2str(tiltcom.THICKNESS),'\n']);
fprintf(param,['TILTFILE ',tomolist.stack_dir,tlt_name,'\n']);
fprintf(param,['SHIFT 0.0 0.0','\n']);
fprintf(param,['CorrectionType ',novactf.correction_type,'\n']);
fprintf(param,['DefocusFileFormat imod','\n']);
fprintf(param,['DefocusFile ',tomolist.stack_dir,'novaCTF/defocus_files/ctfphaseflip.txt','\n']);
fprintf(param,['PixelSize ',num2str(tomolist.pixelsize/10),'\n']); % Convert from A to nm
fprintf(param,['DefocusStep ',num2str(novactf.defocus_step),'\n']);
fprintf(param,['CorrectAstigmatism 1','\n']);

if isfield(novactf,'cen_mass')
    fprintf(param,['DefocusShiftFile ',shift_name,'\n']);
end

% Close file
fclose(param);

%% Generate defocus files and determine number of stacks

% Run novaCTF
pscript_name = [tomolist.stack_dir,'novaCTF/scripts/generate_defocuse_files.sh'];
pscript = fopen(pscript_name,'w');
fprintf(pscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(pscript,[dep.novactf,' -param ',com_name,' \n\n']);
fclose(pscript);    % Close script
% Make executable
system(['chmod +x ',pscript_name]);

status = system([tomolist.stack_dir,'novaCTF/scripts/generate_defocuse_files.sh']);
if status ~= 0
    error(p.name,'ACHTUNG!!! Error in trying to generate novaCTF defocus files!!!')
end

% status = system([dep.novactf,' -param ',com_name]);
% if status ~= 0
%     error([p.name,'ACHUTNG!!! Error in trying to generate novaCTF defocus files!!!']);
% end

% Determine number of defocus files
def_dir = dir([tomolist.stack_dir,'novaCTF/defocus_files/ctfphaseflip.txt_*']);
n_stacks = numel(def_dir);

if n_stacks == 0
    error([p.name,'ACHUTNG!!! Error in trying to generate novaCTF defocus files!!!']);
end


