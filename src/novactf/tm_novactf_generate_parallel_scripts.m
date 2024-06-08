function tm_novactf_generate_parallel_scripts(p,tomolist,novactf,dep,n_stacks,tiltcom,tlt_name,xf_name,efid_name)
%% tm_novactf_generate_parallel_scripts
% A function for generating a set of scripts for parallel processing of
% tilt-stacks for NovaCTF. 
%
% WW 01-2018

%% Initialize

% Generate job array
job_array = tm_job_array(n_stacks,novactf.n_cores);
n_jobs = size(job_array,1);
if n_jobs < novactf.n_cores
    disp([p.name,'ACHTUNG!!! For tomogram ',num2str(tomolist.tomo_num),' there are fewer stacks than number of allotted cores!!!']);
end


% Parse stack name
switch novactf.process_stack
    case 'unfiltered'
        stack_name = tomolist.stack_name;
    case 'dose-filtered'
        stack_name = tomolist.dose_filtered_stack_name;
    otherwise
        error([p.name,'ACHTUNG!!! ',novactf.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
end


% Generate string for newstack size
% if ~isempty(novactf.ali_dim)
%     ali_dim = ['-si ',num2str(novactf.ali_dim(1)),',',num2str(novactf.ali_dim(2)),' '];
% else
%     ali_dim = [];
% end
% ali_dim = ['-si ',num2str(tiltcom.FULLIMAGE(1)),',',num2str(tiltcom.FULLIMAGE(2)),' '];


%% Write parallel scripts

% Base name of parallel scripts
pscript_name = [tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process'];

for i = 1:n_jobs
    
    % Open script
    pscript = fopen([pscript_name,'_',num2str(i-1),'.sh'],'w');
    
    % Write initial lines
    fprintf(pscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
    
    % Loop through for each stack in job
    for j = (job_array(i,2)-1):(job_array(i,3)-1)
        
        % Write comment line
        fprintf(pscript,['echo "TOMOMAN: Processing stack ',num2str(j),' for reconstruction with novaCTF!!!"','\n\n\n']);
        
        % Perform CTF correction via NovaCTF
        fprintf(pscript,['echo "TOMOMAN: Performing CTF correction on stack ',num2str(j),' via novaCTF..."','\n']);
        fprintf(pscript,[dep.novactf,' -Algorithm ctfCorrection ',...
                         '-InputProjections ',tomolist.stack_dir,stack_name,' ',...
                         '-DefocusFile ',tomolist.stack_dir,'novaCTF/defocus_files/ctfphaseflip.txt_',num2str(j),' ',...
                         '-OutputFile ',tomolist.stack_dir,'novaCTF/stacks/corrected_stack.st_',num2str(j),' ',...
                         '-TILTFILE ',tomolist.stack_dir,tlt_name,' ',...
                         '-CorrectionType ',novactf.correction_type,' ',...
                         '-DefocusFileFormat imod ',...
                         '-PixelSize ',num2str(tomolist.pixelsize/10),' ',...
                         '-AmplitudeContrast ',num2str(tomolist.ctf_parameters.famp),' ',...
                         '-Cs ',num2str(tomolist.ctf_parameters.cs),' ',...
                         '-Volt ',num2str(tomolist.voltage),' ',...
                         '-CorrectAstigmatism 1','\n\n']);
        
        % Generate aligned stack
        fprintf(pscript,['echo "TOMOMAN: Generating aligned stack ',num2str(j),'..."\n']);
        fprintf(pscript,['newstack -in ',tomolist.stack_dir,'novaCTF/stacks/corrected_stack.st_',num2str(j),' ',...
                         '-ou ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-xform ',tomolist.stack_dir,xf_name,' ',...
                         '-si ',num2str(tiltcom.FULLIMAGE(1)),',',num2str(tiltcom.FULLIMAGE(2)),'\n\n']);
                     
        % Erase gold
        if ~isempty(novactf.erase_radius)
            if exist([tomolist.stack_dir,efid_name],'file')
                fprintf(pscript,['echo "TOMOMAN: Erasing gold beads in stack ',num2str(j),'..."\n']);
                fprintf(pscript,['ccderaser -input ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                                 '-output ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                                 '-mo ',tomolist.stack_dir,efid_name,' ',...
                                 '-be ',num2str(novactf.erase_radius),' ',...
                                 '-or 0 -me -exc -c / ','\n\n']);
            end
        end
        
        % Taper edges
        if ~isempty(novactf.taper_pixels)
            fprintf(pscript,['echo "TOMOMAN: Tapering edges of aligned stack ',num2str(j),'..."\n']);
            fprintf(pscript,['mrctaper -t ',num2str(novactf.taper_pixels),' ',...
                             tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),'\n\n']);
        end
        
        % Fourier crop stacks
        if ~isempty(novactf.ali_stack_bin)            
            if novactf.ali_stack_bin > 1
                         
             % Bin stack
            fprintf(pscript,['echo "TOMOMAN: Fourier croping aligned stack ',num2str(j),'..."\n']);
            fprintf(pscript,['newstack -InputFile ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                             ' -OutputFile ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                             ' -FourierReduceByFactor ', num2str(novactf.ali_stack_bin),'\n\n']);
                         
            end
        end
        
        % Flip stack
        fprintf(pscript,['echo "TOMOMAN: Flipping aligned stack ',num2str(j),'..."\n']);
        fprintf(pscript,['clip flipyz ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                         tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),'\n\n']);
        
                     
        % R-filter stack
        if ~isempty(novactf.radial)
            radial_str = ['-RADIAL ',num2str(novactf.radial(1)),' ',num2str(novactf.radial(2))];
        else
            radial_str = [];
        end
        fprintf(pscript,['echo "TOMOMAN: R-filtering flipped stack ',num2str(j),' with novaCTF...','"\n']);
        fprintf(pscript,[dep.novactf,' -Algorithm filterProjections ',...
                         '-InputProjections ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-OutputFile ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),' ',...
                         '-TILTFILE ',tomolist.stack_dir,tlt_name,' ',...
                         '-StackOrientation xz ',...
                         radial_str,'\n\n']);
                     
        % Cleanup temporary files
        fprintf(pscript,['echo "TOMOMAN: Cleaning up temporary files from stack ',num2str(j),'..."\n']);
        fprintf(pscript,['rm -f ',tomolist.stack_dir,'novaCTF/stacks/corrected_stack.st_',num2str(j),'\n']);    % Cleanup CTF-correction stack
        fprintf(pscript,['rm -f ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali_',num2str(j),'~\n\n']);    % Cleanup CTF-correction stack
        
        % Completion file
        fprintf(pscript,['touch ',tomolist.stack_dir,'novaCTF/comm/parallel_stack_process_',num2str(j),'\n\n\n\n\n']);
        
    end
    fclose(pscript);    % Close script
    % Make executable
    system(['chmod +x ',pscript_name,'_',num2str(i-1),'.sh']);
    
end

 
%% Write MPI script for parallel running
% 
% % Open script for writing
% mpiscript = fopen([tomolist.stack_dir,'novaCTF/scripts/mpi_stack_process.sh'],'w');
% 
% % Write script
% fprintf(mpiscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
% fprintf(mpiscript,['# Get OPENMPI environmental parameters','\n']);
% fprintf(mpiscript,['procnum=$OMPI_COMM_WORLD_RANK       # Get rank number','\n\n\n']); % openmpi
% % fprintf(mpiscript,['procnum=$PMI_RANK       # Get rank number','\n\n\n']); %intel mpi
% fprintf(mpiscript,['echo "TOMOMAN: Processing stack ${procnum}..."','\n\n']);
% fprintf(mpiscript,[tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process_${procnum}.sh > ',tomolist.stack_dir,'novaCTF/logs/parallel_log_${procnum}.txt 2>&1']);
% 
% % Close script and make executable
% fclose(mpiscript);
% system(['chmod +x ',tomolist.stack_dir,'novaCTF/scripts/mpi_stack_process.sh']);

%% Write script for parallel running

% Open script for writing
parscript = fopen([tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process.sh'],'w');

% Write script
fprintf(parscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);
fprintf(parscript,['echo "TOMOMAN: Processing jobs for ',stack_name,'..."','\n\n']);
for i = 1:n_jobs    
    fprintf(parscript,[tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process_',num2str(i-1),'.sh > ',tomolist.stack_dir,'novaCTF/logs/parallel_log_',num2str(i-1),'.txt 2>&1 & \n\n']);    
end

% Close script and make executable
fclose(parscript);
system(['chmod +x ',tomolist.stack_dir,'novaCTF/scripts/parallel_stack_process.sh']);
        


