function tm_novactf_generate_tomogram_runscript(tomolist,novactf,dep,tlt_name,tiltcom,tomo_dir)
%% tm_novactf_generate_tomogram_runscript
% A function to generate a 'runscript' for running novaCTF on a tilt-stack.
%
% WW 07-2022

%% Initialize


% % Determine number of cores
% if n_stacks < novactf.n_cores
%     n_cores = n_stacks;
% else
%     n_cores = novactf.n_cores;
% end

% Binning dimensions for aligned stacks
ali_x = round(tiltcom.FULLIMAGE(1)/novactf.ali_stack_bin);
ali_y = round(tiltcom.FULLIMAGE(2)/novactf.ali_stack_bin);
thickness = floor(tiltcom.THICKNESS/novactf.ali_stack_bin);
shift_x = round(tiltcom.SHIFT(1)/novactf.ali_stack_bin);
shift_y = round(tiltcom.SHIFT(2)/novactf.ali_stack_bin);

% Calculate binned pixelsize in nm
pixelsize = (tomolist.pixelsize*novactf.ali_stack_bin)/10;


% Generate parameter strings
thick_str  =  num2str(thickness);                       % THICKNESS string
fullimage_str = [num2str(ali_x),',',num2str(ali_y)];    % FULLIMAGE string
shift_str =  [num2str(shift_x),',',num2str(shift_y)];   % SHIFT string
pixelsize_str = num2str(pixelsize);                     % Pixelsize string



% Parse name of stack used for alignment
switch tomolist.alignment_stack
    case 'unfiltered'
        process_stack = tomolist.stack_name;
    case 'dose-filtered'
        process_stack = tomolist.dose_filtered_stack_name;
    otherwise
        error([p.name,'ACTHUNG!!! Unsuppored stack!!! Only "unfiltered" and "dose-filtered" supported!!!']);
end        
[~,stack_name,~] = fileparts(process_stack);

%% Check for refined center

% if isfield(novactf,'mean_z')
%     tomo_idx = novactf.mean_z(1,:) == tomolist.tomo_num; % Find tomogram index
%     mean_z = round(novactf.mean_z(2,tomo_idx));   % Parse mean Z value
%     cen_name = [tomolist.stack_dir,'/novactf/refined_cen.txt'];
%     dlmwrite(cen_name,mean_z);
%     new_cen = ['DefocusShiftFile ',cen_name];
% else
%     new_cen = [];
% end
new_cen = []; 


%% Generate run script

% Open run script
rscript = fopen([tomolist.stack_dir,'/novaCTF/run_novaCTF.sh'],'w');
fprintf(rscript,['#!/usr/bin/env bash \n\n','set -e \n','set -o nounset \n\n']);

% % Run parallel scripts
% fprintf(rscript,'echo "TOMOMAN: Processing stacks in parallel..."\n');
% fprintf(rscript,[dep.mpiexec,' -np ',num2str(n_cores),' ',tomolist.stack_dir,'novaCTF/scripts/mpi_stack_process.sh','\n\n']);

% Reconstruct with novaCTF
fprintf(rscript,['echo "TOMOMAN: Reconstructing tomogram ',stack_name,' with novaCTF..."','\n']);
fprintf(rscript,[dep.novactf,' -Algorithm 3dctf ',...
                 '-InputProjections ',tomolist.stack_dir,'novaCTF/stacks/aligned_stack.ali ',...
                 '-OutputFile ',tomo_dir{1},'/',stack_name,'.rec ',...
                 '-TILTFILE ',tomolist.stack_dir,tlt_name,' ',...
                 '-THICKNESS ',thick_str,' ',...
                 '-FULLIMAGE ',fullimage_str,' ',...
                 '-SHIFT ',shift_str,' ',...
                 '-PixelSize ',pixelsize_str,' ',...
                 '-DefocusStep ',num2str(novactf.defocus_step),' ',...
                 '-Use3DCTF 1 ',...
                 new_cen,...
                 '> ',tomolist.stack_dir,'novaCTF/logs/3dctf_log.txt 2>&1','\n\n']);
             
% Rotate tomogram
fprintf(rscript,['echo "TOMOMAN: Rotating tomogram ',stack_name,' about X..."','\n']);
fprintf(rscript,['clip rotx ',tomo_dir{1},'/',stack_name,'.rec ',tomo_dir{1},'/',stack_name,'.rec','\n\n']);

% Remove temporary files
fprintf(rscript,['echo "TOMOMAN: Tomomgram ',stack_name,' reconstructed!!! Removing temporary files..."','\n']);
fprintf(rscript,['rm -f ',tomo_dir{1},'/',stack_name,'.rec~','\n']);
fprintf(rscript,['rm -f ',tomolist.stack_dir,'novaCTF/stacks/*','\n\n']);

% Bin tomograms serially
n_binning = numel(novactf.tomo_bin);
if n_binning > 1
    for i = 2:numel(novactf.tomo_bin)

        % Input tomogram name
        in_name = [tomo_dir{i-1},stack_name,'.rec'];

        % Ouptut tomogram name
        out_name = [tomo_dir{i},'/',stack_name,'.rec'];

        % Bin factor
        bin_factor = novactf.tomo_bin(i)/novactf.tomo_bin(i-1);

        % Write script
        fprintf(rscript,['echo "TOMOMAN: Binning tomogram by a factor of ',num2str(novactf.tomo_bin(i)),' by Fourier cropping..."\n']);
        fprintf(rscript,[dep.fourier3d,' ',...
                         '-InputFile ',in_name,' ',...
                         '-OutputFile ',out_name,' ',...
                         '-BinFactor ',num2str(bin_factor),' ',...
                         '-MemoryLimit ',num2str(novactf.f3d_memlimit),' ',...
                         '> ',tomolist.stack_dir,'novaCTF/logs/binning_log.txt 2>&1','\n\n']);

    end
end

% Close file and make executable
fclose(rscript);
system(['chmod +x ',tomolist.stack_dir,'/novaCTF/run_novaCTF.sh']);

                 


