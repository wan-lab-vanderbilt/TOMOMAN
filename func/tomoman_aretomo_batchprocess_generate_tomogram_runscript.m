function tomoman_aretomo_batchprocess_generate_tomogram_runscript(t,p,AlignZ,VolZ)
%% will_novactf_generate_tomogram_runscript
% A function to generate a 'runscript' for running novaCTF on a tilt-stack.
% When run, the runscript first runs parallel processing of tilt-stacks via
% MPI; when the MPI job is completed, it finishes the tomogram by running
% novaCTF. The tomogram is then binned via Fourier cropping and the 
% intermediate files are deleted. 
%
% WW 01-2018

%% Initialize

%% Check for refined center (__FUTURE__: implement xaxis tilt based on motl)
% 
% if isfield(p,'mean_z')
%     tomo_idx = p.mean_z(1,:) == t.tomo_num; % Find tomogram index
%     mean_z = round(p.mean_z(2,tomo_idx));   % Parse mean Z value
%     cen_name = [t.stack_dir,'/sg_refine_batchprocess/refined_cen.txt'];
%     dlmwrite(cen_name,mean_z);
%     new_cen = ['DefocusShiftFile ',cen_name];
% else
%     new_cen = [];
% end
%     


%% Generate run script


% Write initial lines for submission on either local or hpcl700x (p.512g)
% 
% EDIT SK 27112019


% Parse imod name
switch p.imod_stack
    case 'unfiltered'
        imod_name = t.stack_name;
    case 'dose_filt'
        imod_name = t.dose_filtered_stack_name;
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end

[dir,name,ext] = fileparts(imod_name);
if ~isempty(dir)
    dir = [dir,'/']; %#ok<AGROW>
end


imod_stack_name = [t.stack_dir,name,ext];
InMrc_name = [t.stack_dir,'/AreTomo/',name,'.st'];

% InMrc_name = [t.stack_dir,name,'.preali'];
OutMrc_name = [t.stack_dir,'/AreTomo/',name,'_volume.st'];


% Check for IMOD coarse alignment xf file 
if p.imod_preali
    prexg_file = [t.stack_dir,name,'.prexg'];    
    if ~isfile(prexg_file)
        error('Prealignment transform file not found!!');
    end
end

% heck whether to use unfiltered or dose-filtered stack for Aretomo
% alignment

if p.aretomo_useunfilt
    imod_name2 = t.stack_name;
    [dir2,name2,ext2] = fileparts(imod_name2);
    if ~isempty(dir2)
        dir2 = [dir2,'/']; %#ok<AGROW>
    end
    imod_stack_name = [t.stack_dir,name2,ext2];
end

% AngleFile
tlt_name = [t.stack_dir,name,'.rawtlt'];

% Check if Known Angle offset is given.
if ~isempty(p.titlangleoffset)
   tilts = dlmread (tlt_name);
   offset_tilts = tilts + p.titlangleoffset;   
   tlt_name = [t.stack_dir,'/AreTomo/',name,'.rawtlt']; 
   dlmwrite(tlt_name,offset_tilts);
end


% AlignZ and VolZ vor given binning
AlignZ = AlignZ/p.aretomo_inbin;
VolZ = VolZ/p.aretomo_inbin;


% Output Volume
OutVol = [p.main_dir, num2str(t.tomo_num),'.mrc'];

% Patch alignment in Aretomo
if ~isempty(p.Patch_x) && ~isempty(p.Patch_y)
    aretomo_patch_string = [' -Patch ', num2str(p.Patch_x), ' ', num2str(p.Patch_y)];
else
    aretomo_patch_string = '';
end


% Tilt Axis angle refinement 
if ~isempty(p.tiltaxisangle)
    aretomo_tiltaxis_string = [num2str(p.tiltaxisangle), ' ',num2str(p.tiltaxisangle_refineflag)];
    
else
    aretomo_tiltaxis_string = [num2str(t.tilt_axis_angle), ' ',num2str(p.tiltaxisangle_refineflag)];
end


% Open run script
rscript = fopen([t.stack_dir,'/AreTomo/run_AreTomo.sh'],'w');


fprintf(rscript,['#!/bin/bash -l\n',...
    '# Standard output and error:\n',...
    '#SBATCH -e ' ,t.stack_dir,'/AreTomo/Submit.err\n',...
    '#SBATCH -o ' ,t.stack_dir,'/AreTomo/Submit.out\n',...
    '# Initial working directory:\n',...
    '#SBATCH -D ./\n',...
    '# Job Name:\n',...
    '#SBATCH -J AreTomo\n',...
    '# Queue (Partition):\n',...
    '#SBATCH --partition=p.hpcl8 \n',...
    '# Number of nodes and MPI tasks per node:\n',...
    '#SBATCH --nodes=1\n',...
    '#SBATCH --ntasks=1\n',...
    '#SBATCH --ntasks-per-node=1\n',...
    '#SBATCH --cpus-per-task=24\n',...
    '#SBATCH --gres=gpu:2\n',...
    '#\n',...
    '#SBATCH --mail-type=none\n',...
    '#SBATCH --mem 378880\n',...
    '#\n',...
    '# Wall clock limit:\n',...
    '#SBATCH --time=168:00:00\n',...
    'echo "setting up environment"\n',...
    'module purge\n',...
    'module load intel/18.0.5\n',...
    'module load impi/2018.4\n',...
    '#load module for your application\n',...
    'module load IMOD/4.10.43\n',...
    'module load cuda/10.1\n',...
    'module load ARETOMO/1.3.3\n',...
    'export IMOD_PROCESSORS=24\n']);                      % Get proper envionment; i.e. modules


% Check whether to use IMOD coarse alignment. In my experience it works
% better in most cases, 

if p.imod_preali
    if p.aretomo_inbin > 1
        fprintf(rscript,['# Generate and Fourier crop prealigned stack','\n']);
        fprintf(rscript,['newstack -InputFile ',imod_stack_name,' ',...
                         ' -OutputFile ',InMrc_name,' ',...
                         ' -TransformFile ',prexg_file,' ',...
                         ' -FourierReduceByFactor ', num2str(p.aretomo_inbin),'\n\n']);
    else
       fprintf(rscript,['# Generate prealigned stack','\n']);
       fprintf(rscript,['newstack -InputFile ',imod_stack_name,' ',...
                         ' -OutputFile ',InMrc_name,' ',...
                         ' -TransformFile ',prexg_file,'\n\n']);        
    end
   

else
    if p.aretomo_inbin > 1
        % bin original_stack
        fprintf(rscript,['# Fourier crop original stack','\n']);
        fprintf(rscript,['newstack -InputFile ',imod_stack_name,' ',...
                         ' -OutputFile ',InMrc_name,' ',...
                         ' -FourierReduceByFactor ', num2str(p.aretomo_inbin),'\n\n']);
    else
        fprintf(rscript,['# Link original stack','\n']);
        fprintf(rscript,['ln -sf ',imod_stack_name,' ',InMrc_name,'\n\n']);        
    end
                 
end

% AreTomo
fprintf(rscript,['# Process stacks','\n']);
fprintf(rscript,[p.aretomo_exe,' -InMrc ' , InMrc_name, ' -OutMrc ',OutMrc_name, ' -AngFile ',tlt_name, ' -AlignZ ',num2str(AlignZ),' -VolZ ',num2str(VolZ), ' -Wbp ', num2str(p.Wbp), ' -Outbin ',num2str(p.aretomo_outbin./p.aretomo_inbin),' -TiltCor ',num2str(p.TiltCor), ' -TiltAxis ',aretomo_tiltaxis_string, aretomo_patch_string ,' -DarkTol 0.001 -OutXf 1\n\n']);

fprintf(rscript,['clip rotx ',OutMrc_name, ' ', OutVol,'\n']);

% Close file and make executable
fclose(rscript);
system(['chmod +x ',t.stack_dir,'/AreTomo/run_AreTomo.sh']);

end


