function tomoman_novactf_generate_parallel_scripts(t,p,n_stacks,tiltcom)
%% will_novactf_generate_parallel_scripts
% A function for generating a set of scripts for parallel processing of
% tilt-stacks for NovaCTF. 
%
% WW 01-2018

%% Initialize

% Generate job array
job_array = will_job_array(n_stacks,p.n_cores);
n_jobs = size(job_array,1);
if n_jobs < p.n_cores
    disp(['ACHTUNG!!! For tomogram ',num2str(t.tomo_num),' there are fewer stacks than number of allotted cores!!!']);
end

% Stackname
switch p.stack
    case 'r'
        stack_name = t.stack_name;
    case 'w'
        [~,name,~] = fileparts(t.stack_name);
        stack_name = [name,'-whitened.st'];
    case 'df'
        stack_name = t.dose_filtered_stack_name;
    case 'dfw'
        [~,name,~] = fileparts(t.dose_filtered_stack_name);
        stack_name = [name,'-whitened.st'];
end
        

% Parse tlt filename
[~,name,~] = fileparts(t.dose_filtered_stack_name);
tltname = [name,'.tlt'];

% Parse transform file anme
xform_file = [name,'.xf'];

% Generate string for newstack size
if ~isempty(p.ali_dim)
    ali_dim = ['-si ',num2str(p.ali_dim(1)),',',num2str(p.ali_dim(2)),' '];
else
    ali_dim = [];
end

%% Write parallel scripts

% Base name of parallel scripts
pscript_name = [t.stack_dir,'novactf/scripts/parallel_stack_process'];

for i = 1:n_jobs
    
    % Open script
    pscript = fopen([pscript_name,'_',num2str(i-1),'.sh'],'w');
    
    % Write initial lines
    fprintf(pscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
    
    % Loop through for each stack in job
    for j = (job_array(i,2)-1):(job_array(i,3)-1)
        
        % Write comment line
        fprintf(pscript,['echo "##### Processing stack ',num2str(j),' #####"','\n\n\n']);
        
        % Perform CTF correction via NovaCTF
        fprintf(pscript,['# Perform CTF correction via NovaCTF','\n']);
        fprintf(pscript,[p.novactf,' -Algorithm ctfCorrection ',...
                         '-InputProjections ',t.stack_dir,stack_name,' ',...
                         '-DefocusFile ',t.stack_dir,'novactf/defocus_files/ctfphaseflip.txt_',num2str(j),' ',...
                         '-OutputFile ',t.stack_dir,'novactf/stacks/corrected_stack.st_',num2str(j),' ',...
                         '-TILTFILE ',t.stack_dir,tltname,' ',...
                         '-CorrectionType ',p.correction_type,' ',...
                         '-DefocusFileFormat imod ',...
                         '-PixelSize ',num2str(t.pixelsize/10),' ',...
                         '-AmplitudeContrast ',num2str(p.famp),' ',...
                         '-Cs ',num2str(p.cs),' ',...
                         '-Volt ',num2str(p.evk),' ',...
                         '-CorrectAstigmatism 1','\n\n']);
        
        % Generate aligned stack
        fprintf(pscript,['# Generate aligned stack','\n']);
        fprintf(pscript,['newstack -in ',t.stack_dir,'novactf/stacks/corrected_stack.st_',num2str(j),' ',...
                         '-ou ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-xform ',t.stack_dir,xform_file,' ',...
                         ali_dim,'\n\n']);
                     
        % Erase gold
        if ~isempty(p.goldradius)
            if exist([t.stack_dir,name,'_erase.fid '],'file')
                fprintf(pscript,['# Erase gold beads','\n']);
                fprintf(pscript,['ccderaser -input ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                                 '-output ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                                 '-mo ',t.stack_dir,name,'_erase.fid ',...
                                 '-be ',num2str(p.goldradius),' ',...
                                 '-or 0 -me -exc -c / ','\n\n']);
            end
        end
        
        % Taper edges
        if ~isempty(p.taper_pixels)
            fprintf(pscript,['# Taper edges of aligned stack','\n']);
            fprintf(pscript,['mrctaper -t ',num2str(p.taper_pixels),' ',...
                             t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),'\n\n']);
        end
        
        % Fourier crop stacks
        if ~isempty(p.ali_stack_bin)
%             
%             % Calculate new dimensions
%             if ~isempty(p.ali_dim)
%                 bin_x = ceil(p.ali_dim(1)/(p.ali_stack_bin*2))*2;
%                 bin_y = ceil(p.ali_dim(2)/(p.ali_stack_bin*2))*2;                
%             else
%                 bin_x = ceil(tiltcom.FULLIMAGE(1)/(p.ali_stack_bin*2))*2;
%                 bin_y = ceil(tiltcom.FULLIMAGE(2)/(p.ali_stack_bin*2))*2;
%             end
%             newdim = [num2str(bin_x),',',num2str(bin_y),',',num2str(numel(t.rawtlt))];
%             
%             
            fprintf(pscript,['# Fourier crop aligned stack','\n']);
%             fprintf(pscript,[p.fcrop_vol,' ',...
%                              '-InputFile ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
%                              '-OutputFile ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
%                              '-NewDimensions ',newdim,' ',...
%                              '-MemoryLimit 2000 \n\n']);
            fprintf(pscript,[p.fcrop_stack,' ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                             t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                             num2str(p.ali_stack_bin),'\n\n']);
        end
        
        % Flip stack
        fprintf(pscript,['# Flip aligned stack','\n']);
        fprintf(pscript,['clip flipyz ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),'\n\n']);
        
        % R-filter stack
        if ~isempty(p.radial)
            radial_str = ['-RADIAL ',num2str(p.radial(1)),' ',num2str(p.radial(2))];
        else
            radial_str = [];
        end
        fprintf(pscript,['# R-filter flipped stack with novaCTF','\n']);
        fprintf(pscript,[p.novactf,' -Algorithm filterProjections ',...
                         '-InputProjections ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-OutputFile ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-TILTFILE ',t.stack_dir,tltname,' ',...
                         '-StackOrientation xz ',...
                         radial_str,'\n\n']);
                     
        % Cleanup temporary files
        fprintf(pscript,['# Cleanup temporary files','\n']);
        fprintf(pscript,['rm -f ',t.stack_dir,'novactf/stacks/corrected_stack.st_',num2str(j),'\n']);    % Cleanup CTF-correction stack
        fprintf(pscript,['rm -f ',t.stack_dir,'novactf/stacks/aligned_stack.ali_',num2str(j),'~\n\n\n\n\n']);    % Cleanup CTF-correction stack
        
    end
    fclose(pscript);    % Close script
    % Make executable
    system(['chmod +x ',pscript_name,'_',num2str(i-1),'.sh']);
    
end

 
%% Write MPI script for parallel running

% Open script for writing
mpiscript = fopen([t.stack_dir,'novactf/scripts/mpi_stack_process.sh'],'w');

% Write script
fprintf(mpiscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(mpiscript,['# Get OPENMPI environmental parameters','\n']);
% fprintf(mpiscript,['procnum=$OMPI_COMM_WORLD_RANK       # Get rank number','\n\n\n']); % openmpi
fprintf(mpiscript,['procnum=$PMI_RANK       # Get rank number','\n\n\n']); %intel mpi
fprintf(mpiscript,['echo "##### Processing stack ${procnum} #####"','\n\n']);
fprintf(mpiscript,[t.stack_dir,'novactf/scripts/parallel_stack_process_${procnum}.sh > ',t.stack_dir,'novactf/logs/parallel_log_${procnum}.txt 2>&1']);

% Close script and make executable
fclose(mpiscript);
system(['chmod +x ',t.stack_dir,'novactf/scripts/mpi_stack_process.sh']);


        


