function n_stacks = tomoman_novactf_generate_defocus_files(t, p, tiltcom)
%% will_novactf_generate_defocus_files
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

% Copy ctfphaseflip.txt from root folder
copyfile([t.stack_dir,'ctfphaseflip_', t.ctf_determination_algorithm, '.txt'],[t.stack_dir,'novactf/defocus_files/ctfphaseflip.txt']);
% will_ctfphaseflip_single_space([t.stack_dir,'ctfphaseflip.txt'],[t.stack_dir,'novactf/defocus_files/ctfphaseflip.txt']);

% Parse tlt filename
[~,name,~] = fileparts(t.dose_filtered_stack_name);
tltname = [name,'.tlt'];

%% Check for refined center

if isfield(p,'mean_z')
    tomo_idx = p.mean_z(1,:) == t.tomo_num; % Find tomogram index
    mean_z = round(p.mean_z(2,tomo_idx));   % Parse mean Z value
%     tomo_cen = floor(tiltcom.THICKNESS/2)+1;
    z_shift = mean_z;
    shift_name = [t.stack_dir,'/novactf/def_shift.txt'];
    dlmwrite(shift_name,z_shift);
end
    
%% Generate parameter file

% Initialize script ouptut
com_name = [t.stack_dir,'novactf/scripts/setup_defocus.com'];
param = fopen(com_name,'w');

% Print lines
fprintf(param,['Algorithm defocus','\n']);
fprintf(param,['InputProjections ',t.stack_dir,t.dose_filtered_stack_name,'\n']);
fprintf(param,['FULLIMAGE ',num2str(tiltcom.FULLIMAGE(1)),' ',num2str(tiltcom.FULLIMAGE(2)),'\n']);
fprintf(param,['THICKNESS ',num2str(tiltcom.THICKNESS),'\n']);
fprintf(param,['TILTFILE ',t.stack_dir,tltname,'\n']);
fprintf(param,['SHIFT 0.0 0.0','\n']);
fprintf(param,['CorrectionType ',p.correction_type,'\n']);
fprintf(param,['DefocusFileFormat imod','\n']);
fprintf(param,['DefocusFile ',t.stack_dir,'novactf/defocus_files/ctfphaseflip.txt','\n']);
fprintf(param,['PixelSize ',num2str(t.pixelsize/10),'\n']); % Convert from A to nm
fprintf(param,['DefocusStep ',num2str(p.defocus_step),'\n']);
fprintf(param,['CorrectAstigmatism 1','\n']);

if isfield(p,'mean_z')
    fprintf(param,['DefocusShiftFile ',shift_name,'\n']);
end

% Close file
fclose(param);

%% Generate defocus files and determine number of stacks

% Run novaCTF
system([p.novactf,' -param ',com_name]);

% Determine number of defocus files
def_dir = dir([t.stack_dir,'novactf/defocus_files/ctfphaseflip.txt_*']);
n_stacks = numel(def_dir);


